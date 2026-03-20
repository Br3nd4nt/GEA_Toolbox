function genes = reversion(genes, bounds, params)

arguments
    genes (1, :) double
    bounds (2, :) double
    params = struct()
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

