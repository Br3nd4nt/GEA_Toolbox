function [dominantGenes, maskDominant] = analyzeDominant(chromosomes, nFixedX)
%ANALYZEDOMINANT Pick a dominant chromosome and its fixed-gene mask.

arguments
    chromosomes (1, :) GEAoptimizer.core.Chromosome
    nFixedX (1, 1) double {mustBeInteger, mustBePositive}
end

[~, masks] = GEAoptimizer.operators.gea.maskCreation(chromosomes, nFixedX);
if isempty(masks)
    dominantGenes = chromosomes(1).genes;
    maskDominant = true(size(dominantGenes));
    return;
end

fixedCounts = sum(masks, 2);
bestCount = max(fixedCounts);
bestIdx = find(fixedCounts == bestCount);

% Random tie-break.
idx = bestIdx(randi(numel(bestIdx)));
dominantGenes = chromosomes(idx).genes;
maskDominant = masks(idx, :);
end

