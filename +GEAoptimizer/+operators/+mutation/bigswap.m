function genes = bigswap(genes, bounds, params)

arguments
    genes (1, :) double
    bounds (2, :) double
    params = struct()
end

n = numel(genes);
if n < 2
    return;
end
p = randperm(n, 2);
genes(p) = genes(fliplr(p));
end

