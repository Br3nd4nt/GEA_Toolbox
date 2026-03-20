function genes = reversion(genes, bounds, params) %#ok<INUSD>
%REVERSION Reverse a random segment (permutation-style).
%
% Ported from Metaheuristics_GEA/Algorithm/Mutation/Mutation_Reversion.m

arguments
    genes (1, :) double
    bounds (2, :) double %#ok<INUSA>
    params = struct() %#ok<INUSA>
end

n = numel(genes);
if n < 2
    return;
end

pts = sort(randperm(n, 2));
pA = pts(1);
pB = pts(2);
genes(pA:pB) = genes(pB:-1:pA);
end

