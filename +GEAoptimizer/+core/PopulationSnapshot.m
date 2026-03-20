classdef PopulationSnapshot
    %POPULATIONSNAPSHOT Read-only view of a population for monitoring.
    %
    % This snapshot is a value object that contains copies of genes/fitness.
    % Mutating it cannot affect the optimizer's internal population.

    properties (SetAccess = immutable)
        genes   % populationSize x nGenes
        fitness % populationSize x 1
    end

    methods (Static)
        function snap = fromPopulation(problem, population)
            arguments
                problem (1, 1) GEAoptimizer.Problem
                population (1, 1) GEAoptimizer.core.Population
            end

            % Copy out into plain MATLAB arrays.
            % `genes` is (populationSize x nGenes), `fitness` is (populationSize x 1).
            if isempty(population.chromosomes)
                genes = zeros(0, problem.nGenes);
                fitness = zeros(0, 1);
            else
                genes = reshape([population.chromosomes.genes], problem.nGenes, []).';
                fitness = [population.chromosomes.fitness].';
            end

            snap = GEAoptimizer.core.PopulationSnapshot(genes, fitness);
        end
    end

    methods
        function obj = PopulationSnapshot(genes, fitness)
            arguments
                genes double
                fitness double
            end
            if size(genes, 1) ~= numel(fitness)
                error("PopulationSnapshot:InvalidShape", "genes rows must match numel(fitness).");
            end
            obj.genes = genes;
            obj.fitness = fitness(:);
        end

        function n = count(obj)
            %COUNT Number of chromosomes represented by this snapshot.
            n = size(obj.genes, 1);
        end

        function [bestFitness, bestGenes, idx] = best(obj, objectiveType)
            arguments
                obj
                objectiveType (1, 1) string {mustBeMember(objectiveType,["min","max"])}
            end

            if isempty(obj.fitness)
                bestFitness = NaN;
                bestGenes = [];
                idx = NaN;
                return;
            end

            if objectiveType == "min"
                [bestFitness, idx] = min(obj.fitness);
            else
                [bestFitness, idx] = max(obj.fitness);
            end
            bestGenes = obj.genes(idx, :);
        end
    end
end
