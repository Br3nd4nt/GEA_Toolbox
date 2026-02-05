classdef Chromosome
    properties
        genes       % 1 x nGenes
        fitness     % scalar
    end

    methods
        function obj = Chromosome(genes, fitness)
            if nargin > 0
                obj.genes = genes;
                obj.fitness = fitness;
            end
        end
    end
end