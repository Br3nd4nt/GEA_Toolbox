classdef PSO < GEAoptimizer.core.PopulationOptimizer
    %PSO Particle Swarm Optimization (minimal working implementation).
    %
    % Uses the shared PopulationOptimizer run-loop for evaluation/history/
    % monitoring/callbacks. PSO-specific state (velocities, personal bests)
    % is stored inside the optimizer instance.

    properties (Access = private)
        velocities = []          % N x nGenes
        pBestGenes = []          % N x nGenes
        pBestFitness = []        % N x 1
        initialized (1, 1) logical = false
    end

    methods (Access = protected)
        function population = step(obj, population, iter) %#ok<INUSD>
            % step() receives an evaluated population (fitness already set).
            % It updates PSO state from current fitness, then advances positions.

            n = numel(population.chromosomes);
            nGenes = obj.problem.nGenes;
            X = reshape([population.chromosomes.genes], nGenes, []).';   % N x nGenes
            F = [population.chromosomes.fitness].';                      % N x 1

            if ~obj.initialized
                obj.velocities = zeros(n, nGenes);
                obj.pBestGenes = X;
                obj.pBestFitness = F;
                obj.initialized = true;
            else
                obj.updatePersonalBests(X, F);
            end

            [gBestGenes, ~] = obj.globalBest();

            % Parameters from options.params with defaults.
            w = obj.getParam("w", 0.72);      % inertia
            c1 = obj.getParam("c1", 1.49);    % cognitive
            c2 = obj.getParam("c2", 1.49);    % social
            vMax = obj.getParam("vMax", []);  % optional velocity clamp (scalar or 1xnGenes)
            binary = logical(obj.getParam("binary", false));

            r1 = rand(n, nGenes);
            r2 = rand(n, nGenes);

            obj.velocities = w .* obj.velocities ...
                + c1 .* r1 .* (obj.pBestGenes - X) ...
                + c2 .* r2 .* (gBestGenes - X);

            if ~isempty(vMax)
                obj.velocities = obj.clampVelocity(obj.velocities, vMax);
            end

            if binary
                % Binary PSO variant:
                % - interpret velocity as logit; apply sigmoid to get probability
                % - sample bit positions from Bernoulli(prob)
                prob = 1 ./ (1 + exp(-obj.velocities));
                X2 = double(rand(n, nGenes) < prob);
            else
                X2 = X + obj.velocities;
                X2 = obj.clampToBounds(X2);
            end

            chromosomes(1, n) = GEAoptimizer.core.Chromosome();
            for i = 1:n
                chromosomes(i) = GEAoptimizer.core.Chromosome(X2(i, :), NaN);
            end
            population = GEAoptimizer.core.Population(chromosomes);
        end
    end

    methods (Access = private)
        function updatePersonalBests(obj, X, F)
            if isempty(obj.pBestFitness)
                obj.pBestGenes = X;
                obj.pBestFitness = F;
                return;
            end

            if obj.problem.objectiveType == "min"
                improve = F < obj.pBestFitness;
            else
                improve = F > obj.pBestFitness;
            end
            if any(improve)
                obj.pBestFitness(improve) = F(improve);
                obj.pBestGenes(improve, :) = X(improve, :);
            end
        end

        function [genes, fitness] = globalBest(obj)
            if obj.problem.objectiveType == "min"
                [fitness, idx] = min(obj.pBestFitness);
            else
                [fitness, idx] = max(obj.pBestFitness);
            end
            genes = obj.pBestGenes(idx, :);
        end

        function X = clampToBounds(obj, X)
            lb = obj.problem.bounds(1, :);
            ub = obj.problem.bounds(2, :);
            X = min(max(X, lb), ub);
        end

        function V = clampVelocity(~, V, vMax)
            if isscalar(vMax)
                vMaxRow = repmat(vMax, 1, size(V, 2));
            else
                vMaxRow = reshape(vMax, 1, []);
                if numel(vMaxRow) ~= size(V, 2)
                    error("PSO:InvalidVMax", "params.vMax must be a scalar or 1 x nGenes.");
                end
            end
            V = min(max(V, -vMaxRow), vMaxRow);
        end

        function value = getParam(obj, name, defaultValue)
            if isfield(obj.options.params, name)
                value = obj.options.params.(name);
            else
                value = defaultValue;
            end
        end
    end
end
