function child = geneInjection(dominantGenes, parentGenes, maskDominant)
%GENEINJECTION Inject dominant genes into a parent using a binary mask.

arguments
    dominantGenes (1, :) double
    parentGenes (1, :) double
    maskDominant (1, :) logical
end

if numel(dominantGenes) ~= numel(parentGenes) || numel(maskDominant) ~= numel(parentGenes)
    error("geneInjection:SizeMismatch", "dominantGenes, parentGenes, and maskDominant must have same length.");
end

child = parentGenes;
child(maskDominant) = dominantGenes(maskDominant);
end

