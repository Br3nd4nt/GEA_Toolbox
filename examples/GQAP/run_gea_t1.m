% RUN_GEA_T1 Showcase: solve GQAP instance T1 using GEAoptimizer (GEA).

clear; clc;

addpath(pwd);
addpath("examples/GQAP");

model = T1();
I = model.I;
J = model.J;

bounds = [ones(1, J); I * ones(1, J)];

fitness = @(X) gqapFitness(X, model);
problem = GEAoptimizer.Problem("min", J, bounds, fitness);

init = @GEAoptimizer.init.randomInt;

params = struct();
params.pCrossover = 0.4;
params.pMutation = 0.3;
params.pScenario1 = 0.2;
params.pScenario3 = 0.2;
params.pFixedX = 0.6;
params.eliteCount = 1;
params.scenarioCrossoverRate = 0.4;
params.scenarioMutationRate = 0.4;

% Classic operator specs
selection = struct("mode","fixed","variants","tournament","params",struct("k",3));
crossover = "twopoint";
mutation = struct("mode","fixed","variants","randomint","params",struct("numRandMax",5));

mon = @(event, iter, pop, hist, ctx, res) monitorFn(event, iter, pop, hist, ctx, res);

opts = GEAoptimizer.Options( ...
    "algorithm", "gea", ...
    "populationSize", 40, ...
    "maxIterations", 10000, ...
    "seed", 1, ...
    "populationInitializer", init, ...
    "selection", selection, ...
    "crossover", crossover, ...
    "mutation", mutation, ...
    "monitor", mon, ...
    "params", params);

[result, history] = GEAoptimizer.solve(problem, opts);

bestP = round(result.bestGenes(:))';
[~, X] = CreateXij(bestP, model);
[bestCost, ~, cvar] = CostFunction(X, model);

fprintf("\nBest cost = %g (cvar=%g)\n", bestCost, cvar);

function f = gqapFitness(X, model)
%GQAPFITNESS Evaluate a batch of chromosomes.
% X is N x J; each row is an assignment vector in 1..I (integers).

N = size(X, 1);
f = zeros(N, 1);
for r = 1:N
    p = X(r, :);
    % clamp+round into valid assignment indices
    p = round(min(max(p, 1), model.I));
    [~, Xij] = CreateXij(p, model);
    [z, ~, cvar] = CostFunction(Xij, model);

    % The original cost function returns Inf for infeasible solutions.
    % For metaheuristics, returning Inf can cause the whole population to
    % become Inf and stall. Convert infeasibility to a large penalty while
    % keeping values finite.
    if isinf(z) || isnan(z)
        if isvector(cvar) && numel(cvar) == model.I
            violation = sum(max(0, -cvar));
        else
            violation = double(cvar);
        end
        f(r) = 1e12 + 1e6 * violation;
    else
        f(r) = z;
    end
end
end


function monitorFn(event, iter, ~, hist, ctx, res)
if event == "start"
    fprintf("Starting %s (%s), pop=%d, iters=%d, seed=%d\n", string(ctx.algorithm), string(ctx.problem.objectiveType), ctx.options.populationSize, ctx.options.maxIterations, ctx.options.seed);
elseif event == "iteration"
    if iter == 0 || mod(iter, 10) == 0
        fprintf("iter=%d best=%g mean=%g\n", iter, hist.bestFitness(end), hist.meanFitness(end));
    end
elseif event == "finish"
    fprintf("Done (%s): best=%g after %d iterations in %.3fs\n", string(res.exitReason), res.bestFitness, res.iterations, res.elapsedTimeSeconds);
end
end
