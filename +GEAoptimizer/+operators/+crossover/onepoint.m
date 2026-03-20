function [c1, c2] = onepoint(p1, p2, params)
%ONEPOINT One-point crossover.

arguments
    p1 (1, :) double
    p2 (1, :) double
    params = struct() %#ok<INUSA>
end

n = numel(p1);
if n ~= numel(p2)
    error("onepoint:SizeMismatch", "Parents must have the same gene count.");
end
if n < 2
    c1 = p1;
    c2 = p2;
    return;
end

cp = randi([1 n-1], 1, 1);
c1 = [p1(1:cp), p2(cp+1:end)];
c2 = [p2(1:cp), p1(cp+1:end)];
end

