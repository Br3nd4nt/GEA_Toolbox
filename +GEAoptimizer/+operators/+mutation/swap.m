function genes = swap(genes, bounds, params)

arguments
    genes (1, :) double
    bounds (2, :) double
    params = struct()
end

n = numel(genes);
if n < 2
    return;
end
p = randi([1 n-1], 1, 1);
genes([p, p+1]) = genes([p+1, p]);
end

