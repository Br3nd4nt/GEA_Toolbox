function [c1, c2] = twopoint(p1, p2, params)

arguments
    p1 (1, :) double
    p2 (1, :) double
    params = struct();
end

n = numel(p1);
if n ~= numel(p2)
    error("twopoint:SizeMismatch", "Parents must have the same gene count.");
end
if n < 3
    [c1, c2] = GEAoptimizer.operators.crossover.onepoint(p1, p2);
    return;
end

pts = sort(randi([1 n-1], 1, 2));
pA = pts(1);
pB = pts(2);

c1 = [p2(1:pA), p1(pA+1:pB), p2(pB+1:end)];
c2 = [p1(1:pA), p2(pA+1:pB), p1(pB+1:end)];
end

