function parentIdx = roulette(popSnapshot, nParents, objectiveType, params) %#ok<INUSD>
%ROULETTE Roulette-wheel selection (index-only operator).
%
% For minimization, uses inverted ranks; for maximization, uses shifted fitness.
% This is a simple baseline intended for testing wiring, not performance.

arguments
    popSnapshot (1, 1) GEAoptimizer.core.PopulationSnapshot
    nParents (1, 1) double {mustBeInteger, mustBePositive}
    objectiveType (1, 1) string {mustBeMember(objectiveType,["min","max"])}
    params = struct() %#ok<INUSA>
end

fit = popSnapshot.fitness(:);
n = numel(fit);
if n == 0
    error("roulette:EmptyPopulation", "Cannot select from empty population.");
end

if objectiveType == "min"
    % Convert to ranks: best gets highest weight.
    [~, order] = sort(fit, "ascend");
    ranks = zeros(n, 1);
    ranks(order) = n:-1:1;
    w = ranks;
else
    % Shift fitness to be non-negative.
    fmin = min(fit);
    w = fit - fmin + eps;
end

w = w / sum(w);
cdf = cumsum(w);
r = rand(nParents, 1);
parentIdx = arrayfun(@(x) find(cdf >= x, 1, "first"), r);
end

