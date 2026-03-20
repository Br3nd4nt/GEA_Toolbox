function population = randomInt(problem, n)
%RANDOMINT Population initializer sampling integer genes within bounds.
%
% population = GEAoptimizer.init.randomInt(problem, n)
%
% Bounds are interpreted per gene; sampling uses:
%   lo = ceil(lb), hi = floor(ub)
% If hi < lo for a gene, falls back to clamped rounding of lb.

arguments
    problem (1, 1) GEAoptimizer.Problem
    n (1, 1) double {mustBeInteger, mustBePositive}
end

lb = problem.bounds(1, :);
ub = problem.bounds(2, :);
if any(ub < lb)
    error("randomInt:InvalidBounds", "Upper bounds must be >= lower bounds.");
end

nGenes = problem.nGenes;
genes = zeros(n, nGenes);
for j = 1:nGenes
    lo = ceil(lb(j));
    hi = floor(ub(j));
    if hi < lo
        genes(:, j) = round(min(max(lb(j), lb(j)), ub(j)));
    else
        genes(:, j) = randi([lo hi], n, 1);
    end
end

population = GEAoptimizer.core.Population.fromGenes(problem, genes);
end

