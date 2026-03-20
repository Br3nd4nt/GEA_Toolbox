% KNAPSACK_SA 0/1 knapsack ("backpack") example using SA to validate toolbox plumbing.
%
% This example uses a continuous SA implementation with a custom neighbor
% function that flips one bit per iteration. The objective rounds/clamps
% genes to {0,1} and applies a penalty for overweight solutions.

clear; clc;

% Problem data (weights, values, capacity)
w = [2 3 4 5 9 7 6 1 8 3];
v = [3 4 5 8 10 7 6 2 9 4];
capacity = 20;
nGenes = numel(w);

% Bounds for "binary" genes represented as continuous [0,1]
bounds = [zeros(1, nGenes); ones(1, nGenes)];

% Fitness: maximize value, penalize overweight
fitness = @(X) knapsackFitness(X, w, v, capacity);
problem = GEAoptimizer.Problem("max", nGenes, bounds, fitness);

% Monitor: demonstrate function-handle monitor wrapper (start/iteration/finish).
mon = @monitorFn;

% SA params:
% - T0: initial temperature
% - alpha: cooling rate
% - neighborFcn: bit-flip neighbor
params = struct();
params.T0 = 2.0;
params.alpha = 0.995;
params.neighborFcn = @bitFlipNeighbor;

% Callbacks: demonstrate fine-grained hooks around the step/evaluation loop.
% Each callback has signature:
%   stop = cb(iter, popSnapshot, history, ctx, result)
% Return true to stop the run early.
cbs = struct();
cbs.onStart = @cbOnStart;
cbs.onBeforeStep = @cbOnBeforeStep;
cbs.onAfterStep = @cbOnAfterStep;
cbs.onAfterEvaluation = @cbOnAfterEval;
cbs.onFinish = @cbOnFinish;

opts = GEAoptimizer.Options( ...
    "algorithm", "sa", ...
    "maxIterations", 200, ...
    "seed", 1, ...
    "monitor", mon, ...
    "callbacks", cbs, ...
    "params", params);

[result, history] = GEAoptimizer.solve(problem, opts);

bestX = round(result.bestGenes(:))';
bestValue = sum(bestX .* v);
bestWeight = sum(bestX .* w);
fprintf("\nBest packed value=%g weight=%g\n", bestValue, bestWeight);
disp(bestX);

function f = knapsackFitness(X, w, v, capacity)
%KNAPSACKFITNESS Vectorized fitness for knapsack.
% X is N x nGenes (continuous [0,1] values). We treat it as binary via rounding.

Xb = round(min(max(X, 0), 1));
totalW = Xb * w(:);
totalV = Xb * v(:);

% Penalty for overweight (quadratic)
over = max(0, totalW - capacity);
penalty = 100 * (over .^ 2);

f = totalV - penalty;
end

function x2 = bitFlipNeighbor(x, problem, options) %#ok<INUSD>
%BITFLIPNEIGHBOR Flip exactly one bit in a 0/1 vector represented in [0,1].

n = problem.nGenes;
idx = randi(n);

x01 = round(min(max(x, 0), 1));
x01(idx) = 1 - x01(idx);

% Return as [0,1] double vector
x2 = double(x01);
end

function monitorFn(event, iter, pop, hist, ctx, res) %#ok<INUSD>
if event == "iteration"
    if mod(iter,20) == 0 
        fprintf("iter=%3d best=%8.3f\n", iter, hist.bestFitness(end));
    end
elseif event == "start"
    fprintf("Monitor(start): alg=%s objective=%s nGenes=%d\n", string(ctx.algorithm), string(ctx.problem.objectiveType), ctx.problem.nGenes);
elseif event == "finish"
    fprintf("Monitor(finish): reason=%s bestFitness=%g iters=%d\n", string(res.exitReason), res.bestFitness, res.iterations);
end
end

function stop = cbOnStart(iter, pop, hist, ctx, result) %#ok<INUSD>
fprintf("Callback(onStart): maxIters=%d seed=%d\n", ctx.options.maxIterations, ctx.options.seed);
stop = false;
end

function stop = cbOnBeforeStep(iter, pop, hist, ctx, result) %#ok<INUSD>
% pop is a PopulationSnapshot (read-only/value copy). You can inspect:
%   pop.genes, pop.fitness
if ~isempty(pop) && ~isempty(pop.fitness) && mod(iter,20) == 0
    fprintf("Callback(onBeforeStep): iter=%d currentFitness=%g\n", iter, pop.fitness(1));
end
stop = false;
end

function stop = cbOnAfterStep(iter, pop, hist, ctx, result) %#ok<INUSD>
% In SA, onAfterStep observes the accepted state before history updates.
if ~isempty(pop) && ~isempty(pop.fitness) && mod(iter,20) == 0
    fprintf("Callback(onAfterStep):  iter=%d acceptedFitness=%g\n", iter, pop.fitness(1));
end
stop = false;
end

function stop = cbOnAfterEval(iter, pop, hist, ctx, result) %#ok<INUSD>
% Stop early if we found a feasible high-value solution.
best = hist.bestFitness(end);
if best >= 25
    fprintf("Callback(onAfterEvaluation): stopping early at iter=%d (best=%g)\n", iter, best);
    stop = true;
else
    stop = false;
end
end

function stop = cbOnFinish(iter, pop, hist, ctx, result) %#ok<INUSD>
fprintf("Callback(onFinish): exitReason=%s best=%g\n", string(result.exitReason), result.bestFitness);
stop = false;
end
