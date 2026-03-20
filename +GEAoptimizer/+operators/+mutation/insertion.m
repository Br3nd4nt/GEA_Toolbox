function genes = insertion(genes, bounds, params)

arguments
    genes (1, :) double
    bounds (2, :) double
    params = struct()
end

n = numel(genes);
if n < 2
    return;
end

pts = sort(randi([2 n], 1, 2));
pA = pts(1);
pB = pts(2);

temp = genes(pA:pB);
prefix = genes(1:pA-1);
suffix = [];
if pB ~= n
    suffix = genes(pB+1:end);
end
genes = [temp, prefix, suffix];
end

