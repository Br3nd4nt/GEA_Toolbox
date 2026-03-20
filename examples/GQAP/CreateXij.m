function [p, xij] = CreateXij(p, model)
%CREATEXIJ Convert 1D chromosome to assignment matrix (ported).
%
% Chromosome encoding:
% - p is a 1 x J vector
% - p(j) is an integer in 1..I indicating the facility assigned to item j

xij = zeros(model.I, model.J);
for j = 1:numel(p)
    xij(p(j), j) = 1;
end
end

