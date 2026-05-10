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
                obj.chromosomes = GEAoptimizer.core.Chromosome.empty();
            end
        end

        function n = count(obj)
            %COUNT Number of chromosomes in this population.
            n = numel(obj.chromosomes);
        end

        function [best, idx] = best(obj, objectiveType)
            if isempty(obj.chromosomes)
                error("Population:Empty", "Cannot take best() of an empty population.");
            end
            fitness = [obj.chromosomes.fitness];
            if objectiveType == "min"
                [~, idx] = min(fitness);
            else
                [~, idx] = max(fitness);
            end
            best = obj.chromosomes(idx);
        end

        function obj = sortByFitness(obj, objectiveType)
            if isempty(obj.chromosomes)
                return;
            end
            fitness = [obj.chromosomes.fitness];
            if objectiveType == "min"
                [~, idx] = sort(fitness, "ascend");
            else
                [~, idx] = sort(fitness, "descend");
            end
            obj.chromosomes = obj.chromosomes(idx);
        end
    end

    methods (Static)
        function population = fromGenes(problem, genes)
            arguments
                problem (1, 1) GEAoptimizer.Problem
                genes double
            end
            if size(genes, 2) ~= problem.nGenes
                error("Population:InvalidGenes", "genes must be N x nGenes.");
            end
            n = size(genes, 1);
            if n == 0
                population = GEAoptimizer.core.Population(GEAoptimizer.core.Chromosome.empty());
                return;
            end
            chromosomes(1, n) = GEAoptimizer.core.Chromosome();
            for i = 1:n
                chromosomes(i) = GEAoptimizer.core.Chromosome(genes(i, :), NaN);
            end
            population = GEAoptimizer.core.Population(chromosomes);
        end

        function population = randomUniform(problem, populationSize)
            arguments
                problem (1, 1) GEAoptimizer.Problem
                populationSize (1, 1) double {mustBeInteger, mustBePositive}
            end

            lb = problem.bounds(1, :);
            ub = problem.bounds(2, :);
            if any(ub < lb)
                error("Invalid bounds: upper bound must be >= lower bound for each gene.");
            end

            genes = lb + (ub - lb) .* GEAoptimizer.core.RNG.randUniform([populationSize, problem.nGenes]);
            chromosomes(1, populationSize) = GEAoptimizer.core.Chromosome();
            for i = 1:populationSize
                chromosomes(i) = GEAoptimizer.core.Chromosome(genes(i, :), NaN);
            end
            population = GEAoptimizer.core.Population(chromosomes);
        end
    end
end
