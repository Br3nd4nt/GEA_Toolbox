clear; clc;

fitness = @(X) sum(X .^ 2);

nGenes = 100;
bounds = [zeros(1, nGenes); randi(10, 1, nGenes)];
problem = GEAoptimizer.Problem("max", nGenes, bounds, fitness);

opts = GEAoptimizer.Options( ...
    "algorithm", "sa", ...
    "maxIterations", 2000, ...
    "seed", 1, ...
    "monitor", GEAoptimizer.monitor.ConsoleMonitor);

[result, history] = GEAoptimizer.solve(problem, opts);