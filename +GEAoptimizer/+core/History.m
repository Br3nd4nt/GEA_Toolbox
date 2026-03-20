classdef History < handle
    %HISTORY History of optimization alg running
    
    % TODO: add the problem itself?
    properties
        bestFitness = []
        meanFitness = []
        bestGenes = {}
    end
    
    methods
        function addIteration(obj, population, objectiveType)
            fitness = [population.chromosomes.fitness];
            if objectiveType == "min"
                [bestVal, idx] = min(fitness);
            else
                [bestVal, idx] = max(fitness);
            end
            obj.bestFitness(end+1) = bestVal;
            obj.meanFitness(end+1) = mean(fitness);
            obj.bestGenes{end+1} = population.chromosomes(idx).genes;
        end
    end
end
