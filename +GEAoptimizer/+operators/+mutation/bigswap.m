function genes = bigswap(genes, bounds, params) %#ok<INUSD>
%BIGSWAP Swap two random positions (permutation-style).
%
% Ported from Metaheuristics_GEA/Algorithm/Mutation/Mutation_BigSwap.m

arguments
    genes (1, :) double
    bounds (2, :) double %#ok<INUSA>
    params = struct() %#ok<INUSA>
end

n = numel(genes);
if n < 2
    return;
end
p = randperm(n, 2);
genes(p) = genes(fliplr(p));
end

