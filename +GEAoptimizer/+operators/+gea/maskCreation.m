function [mask, masks] = maskCreation(chromosomes, nFixedX)
%MASKCREATION Create binary masks of "fixed" genes for each chromosome.
%
% Inputs:
% - chromosomes: 1xN array of GEAoptimizer.core.Chromosome (typically top of pop)
% - nFixedX: threshold for considering a gene "fixed"
%
% Outputs:
% - mask: alias for masks (kept for compatibility with older naming)
% - masks: N x nGenes logical matrix, where true means gene is "fixed"

arguments
    chromosomes (1, :) GEAoptimizer.core.Chromosome
    nFixedX (1, 1) double {mustBeInteger, mustBePositive}
end

if isempty(chromosomes)
    masks = false(0, 0);
    mask = masks;
    return;
end

matrix = vertcat(chromosomes.genes); % N x nGenes
[rows, cols] = size(matrix);
masks = false(rows, cols);

for rowIdx = 1:rows
    row = matrix(rowIdx, :);
    diff = bsxfun(@minus, row, matrix);
    zeroMask = (diff == 0);
    zeroCount = sum(zeroMask, 1);
    validCols = (zeroCount >= nFixedX);
    masks(rowIdx, validCols) = true;
end

mask = masks;
end

