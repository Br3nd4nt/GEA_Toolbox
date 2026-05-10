clear;
clc;

%% Fitness Function

% Rastrigin function
fitness = @(X) ...
    10 * size(X, 2) + ...
    sum(X .^ 2 - 10 * cos(2 * pi * X), 2);

%% Problem Configuration

nGenes = 30;

bounds = [ ...
    -5.12 * ones(1, nGenes); ...
     5.12 * ones(1, nGenes)];

problem = GEAoptimizer.Problem( ...
    "min", ...
    nGenes, ...
    bounds, ...
    fitness);

%% Callbacks

callbacks = struct();

% Called before optimization starts
callbacks.onStart = @(iter, popSnap, history, ctx, result) ...
    fprintf("Optimization started\n");

% Stop optimization after 300 iterations
callbacks.onAfterEvaluation = @(iter, popSnap, history, ctx, result) ...
    iter >= 300;

% Called after optimization ends
callbacks.onFinish = @(iter, popSnap, history, ctx, result) ...
    fprintf("Optimization finished\n");

%% Operator Configuration

selection = struct( ...
    "mode", "fixed", ...
    "variants", "tournament", ...
    "params", struct("k", 3));

crossover = struct( ...
    "mode", "fixed", ...
    "variants", "onepoint");

mutation = struct( ...
    "mode", "fixed", ...
    "variants", "swap");

%% Algorithm Parameters

params = struct();

params.eliteCount = 2;
params.crossoverRate = 0.9;
params.mutationRate = 0.1;

%% Options

opts = GEAoptimizer.Options( ...
    "algorithm", "gea", ...
    "populationSize", 100, ...
    "maxIterations", 1000, ...
    "seed", 1, ...
    "targetFitness", 1e-6, ...
    "stallIterations", 100, ...
    "monitor", GEAoptimizer.monitor.ConsoleMonitor, ...
    "callbacks", callbacks, ...
    "params", params, ...
    "selection", selection, ...
    "crossover", crossover, ...
    "mutation", mutation);

%% Run Optimization

[result, history] = GEAoptimizer.solve(problem, opts);

%% Result Analysis

fprintf("\n");
fprintf("===== Optimization Result =====\n");

fprintf("Best fitness: %.10f\n", result.bestFitness);
fprintf("Iterations: %d\n", result.iterations);
fprintf("Exit reason: %s\n", string(result.exitReason));

%% Plot Convergence

figure;

plot(history.bestFitness, "LineWidth", 2);

xlabel("Iteration");
ylabel("Best Fitness");

title("Optimization Convergence");
grid on;