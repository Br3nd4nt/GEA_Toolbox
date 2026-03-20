function parentIdx = tournament(popSnapshot, nParents, objectiveType, params)
%TOURNAMENT Tournament selection (index-only operator).
%
% parentIdx = tournament(popSnapshot, nParents, objectiveType, params)
%
% Inputs:
% - popSnapshot: GEAoptimizer.core.PopulationSnapshot (read-only)
% - nParents: number of parent indices to sample
% - objectiveType: "min" or "max"
% - params.k: tournament size (default 3)

arguments
    popSnapshot (1, 1) GEAoptimizer.core.PopulationSnapshot
    nParents (1, 1) double {mustBeInteger, mustBePositive}
    objectiveType (1, 1) string {mustBeMember(objectiveType,["min","max"])}
    params (1, 1) struct = struct()
end

k = 3;
if isfield(params, "k")
    k = params.k;
end
if ~(isnumeric(k) && isscalar(k) && k == floor(k) && k >= 1)
    error("tournament:InvalidK", "params.k must be a positive integer.");
end

n = popSnapshot.count();
if n == 0
    error("tournament:EmptyPopulation", "Cannot select from empty population.");
end

parentIdx = zeros(nParents, 1);
for i = 1:nParents
    cand = randi(n, k, 1);
    fit = popSnapshot.fitness(cand);
    if objectiveType == "min"
        [~, bestLocal] = min(fit);
    else
        [~, bestLocal] = max(fit);
    end
    parentIdx(i) = cand(bestLocal);
end
end
