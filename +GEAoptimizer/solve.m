function [result, history] = solve(problem, options)
%SOLVE Public entry point for optimization.
%
%   problem = GEAoptimizer.Problem(...)
%   options = GEAoptimizer.Options(...)
%   [result, history] = GEAoptimizer.solve(problem, options)

arguments
    problem (1, 1) GEAoptimizer.Problem
    options (1, 1) GEAoptimizer.Options
end

optimizer = GEAoptimizer.alg.OptimizerFactory.create(problem, options);
[result, history] = optimizer.run();
end

