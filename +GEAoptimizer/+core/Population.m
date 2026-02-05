classdef Population
    %POPULATION consists of main chromosomes
    
    properties
        chromosomes
    end
    
    methods 
        function obj = Population(chromosomes)
            if nargin > 0
                obj.chromosomes = chromosomes;
            else 
                obj.chromosomes = GEAoptimizer.core.Chromosome.empty(); % ???
            end
        end

        function n = size(obj)
            n = numel(obj.chromosomes);
        end

        function [best, idx] = best(obj, objectiveType)
            fitness = [obj.chromosomes.fitness];
            if objectiveType == "min"
                [~, idx] = min(fitness);
            else
                [~, idx] = max(fitness);
            end
            best = obj.chromosomes(idx);
        end

        function obj = sortByFitness(obj, objectiveType)
            fitness = [obj.chromosomes.fitness];
            if objectiveType == "min"
                [~, idx] = sort(fitness, "ascend");
            else
                [~, idx] = sort(fitness, "descend");
            end
            obj.chromosomes = obj.chromosomes(idx);
        end
    end
end

