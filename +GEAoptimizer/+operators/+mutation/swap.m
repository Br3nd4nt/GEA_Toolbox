function genes = swap(genes, bounds, params) %#ok<INUSD>
%SWAP Swap adjacent genes (permutation-style).
%
% Ported from Metaheuristics_GEA/Algorithm/Mutation/Mutation_Swap.m

arguments
    genes (1, :) double
    bounds (2, :) double %#ok<INUSA>
    params = struct() %#ok<INUSA>
end

n = numel(genes);
if n < 2
    return;
end
p = randi([1 n-1], 1, 1);
genes([p, p+1]) = genes([p+1, p]);
end

