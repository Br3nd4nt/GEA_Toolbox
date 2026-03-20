function population = uniform(problem, n)
%UNIFORM Default population initializer (uniform within bounds).
%
% population = GEAoptimizer.init.uniform(problem, n)
%
% Creates n chromosomes with genes sampled uniformly from [lb, ub] per gene.

arguments
    problem (1, 1) GEAoptimizer.Problem
    n (1, 1) double {mustBeInteger, mustBePositive}
end

population = GEAoptimizer.core.Population.randomUniform(problem, n);
end

