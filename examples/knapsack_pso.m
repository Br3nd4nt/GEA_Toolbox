% KNAPSACK_PSO 0/1 knapsack ("backpack") example using PSO to validate toolbox plumbing.
%
% This uses a simple Binary PSO variant:
%   - positions are binary {0,1}
%   - velocities are updated continuously
%   - sigmoid(velocity) becomes bit probability
% The objective applies an overweight penalty.

clear; clc;

w = [2 3 4 5 9 7 6 1 8 3];
v = [3 4 5 8 10 7 6 2 9 4];
capacity = 20;
nGenes = numel(w);

bounds = [zeros(1, nGenes); ones(1, nGenes)];
fitness = @(X) knapsackFitness(X, w, v, capacity);
problem = GEAoptimizer.Problem("max", nGenes, bounds, fitness);

% Function-handle monitor (start/iteration/finish)
mon = @monitorFn;

% Callbacks (onStart/onBeforeStep/onAfterStep/onAfterEvaluation/onFinish)
cbs = struct();
cbs.onStart = @cbOnStart;
cbs.onBeforeStep = @cbOnBeforeStep;
cbs.onAfterStep = @cbOnAfterStep;
cbs.onAfterEvaluation = @cbOnAfterEval;
cbs.onFinish = @cbOnFinish;

% PSO params (read via options.params)
params = struct();
params.w = 0.72;
params.c1 = 1.49;
params.c2 = 1.49;
params.vMax = 4;       % velocity clamp (helps keep sigmoid stable)
params.binary = true;  % enable binary mode

% Seed population can be provided; here we let the initializer generate it.
opts = GEAoptimizer.Options( ...
    "algorithm", "pso", ...
    "populationSize", 30, ...
    "maxIterations", 150, ...
    "seed", 1, ...
    "monitor", mon, ...
    "callbacks", cbs, ...
    "params", params);

[result, history] = GEAoptimizer.solve(problem, opts); %#ok<NASGU>

bestX = round(result.bestGenes(:))';
bestValue = sum(bestX .* v);
bestWeight = sum(bestX .* w);
fprintf("\nBest packed value=%g weight=%g\n", bestValue, bestWeight);
disp(bestX);

function f = knapsackFitness(X, w, v, capacity)
Xb = round(min(max(X, 0), 1));
totalW = Xb * w(:);
totalV = Xb * v(:);
over = max(0, totalW - capacity);
penalty = 100 * (over .^ 2);
f = totalV - penalty;
end

function monitorFn(event, iter, pop, hist, ctx, res) %#ok<INUSD>
if event == "start"
    fprintf("Monitor(start): alg=%s objective=%s pop=%d\n", string(ctx.algorithm), string(ctx.problem.objectiveType), ctx.options.populationSize);
elseif event == "iteration"
    if mod(iter, 10) == 0
        fprintf("iter=%3d best=%8.3f mean=%8.3f\n", iter, hist.bestFitness(end), hist.meanFitness(end));
    end
elseif event == "finish"
    fprintf("Monitor(finish): reason=%s best=%g iters=%d\n", string(res.exitReason), res.bestFitness, res.iterations);
end
end

function stop = cbOnStart(iter, pop, hist, ctx, result) %#ok<INUSD>
fprintf("Callback(onStart): PSO binary=%d\n", logical(ctx.options.params.binary));
stop = false;
end

function stop = cbOnBeforeStep(iter, pop, hist, ctx, result) %#ok<INUSD>
if ~isempty(pop) && mod(iter, 10) == 0
    fprintf("Callback(onBeforeStep): iter=%d currentBest=%g\n", iter, hist.bestFitness(end));
end
stop = false;
end

function stop = cbOnAfterStep(iter, pop, hist, ctx, result) %#ok<INUSD>
% After step but before evaluation, pop.fitness may still reflect previous evaluation.
stop = false;
end

function stop = cbOnAfterEval(iter, pop, hist, ctx, result) %#ok<INUSD>
if hist.bestFitness(end) >= 50
    fprintf("Callback(onAfterEvaluation): stopping early at iter=%d (best=%g)\n", iter, hist.bestFitness(end));
    stop = true;
else
    stop = false;
end
end

function stop = cbOnFinish(iter, pop, hist, ctx, result) %#ok<INUSD>
fprintf("Callback(onFinish): exitReason=%s best=%g\n", string(result.exitReason), result.bestFitness);
stop = false;
end

