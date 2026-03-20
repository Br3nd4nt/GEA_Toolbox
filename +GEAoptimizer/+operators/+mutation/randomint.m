function genes = randomint(genes, bounds, params)

arguments
    genes (1, :) double
    bounds (2, :) double
    params (1, 1) struct = struct()
end

numRandMax = 5;
if isfield(params, "numRandMax")
    numRandMax = params.numRandMax;
end
if ~(isnumeric(numRandMax) && isscalar(numRandMax) && numRandMax == floor(numRandMax) && numRandMax >= 1)
    error("randomint:InvalidNumRandMax", "params.numRandMax must be a positive integer.");
end

n = numel(genes);
if n == 0
    return;
end

numRand = randi([1 min(numRandMax, max(1, n))], 1, 1);
idx = randperm(n, min(numRand, n));

lb = bounds(1, :);
ub = bounds(2, :);
if any(ub < lb)
    error("randomint:InvalidBounds", "Upper bounds must be >= lower bounds.");
end

for k = 1:numel(idx)
    j = idx(k);
    lo = ceil(lb(j));
    hi = floor(ub(j));
    if hi < lo
        % No integer point inside bounds; fall back to clamped rounding.
        genes(j) = round(min(max(genes(j), lb(j)), ub(j)));
    else
        genes(j) = randi([lo hi], 1, 1);
    end
end
end
