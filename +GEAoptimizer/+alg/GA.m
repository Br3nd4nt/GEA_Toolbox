classdef GA < GEAoptimizer.alg.PopulationOptimizer
    %GA Genetic Algorithm optimizer (scaffolding only).

    methods (Access = protected)
        function population = step(obj, population, iter) %#ok<INUSD>
            %STEP One GA generation.
            %
            % Expected pipeline:
            %   1) Elitism
            %   2) Selection (choose parent indices)
            %   3) Crossover (produce children genes)
            %   4) Mutation (mutate children genes)
            %   5) Replacement (next population = elites + children)

            n = numel(population.chromosomes);
            if n ~= obj.options.populationSize
                error("GA:PopulationSizeMismatch", "Population size changed unexpectedly.");
            end

            % GA params (from options.params)
            eliteCount = obj.getParam("eliteCount", 1);
            if eliteCount < 0 || eliteCount >= n
                error("GA:InvalidEliteCount", "params.eliteCount must be in [0, populationSize-1].");
            end
            crossoverRate = obj.getParam("crossoverRate", 0.9);
            if crossoverRate < 0 || crossoverRate > 1
                error("GA:InvalidCrossoverRate", "params.crossoverRate must be in [0,1].");
            end

            % Sort by fitness so elites are easy to take.
            population = population.sortByFitness(obj.problem.objectiveType);
            elites = population.chromosomes(1:eliteCount);

            % Resolve operator variants (fixed or random).
            [selectOp, selectionVariant, selectionParams] = GEAoptimizer.operators.OperatorFactory.resolve("selection", obj.options.selection); %#ok<NASGU>
            [crossOp, crossoverVariant, crossoverParams] = GEAoptimizer.operators.OperatorFactory.resolve("crossover", obj.options.crossover); %#ok<NASGU>
            [mutOp, mutationVariant, mutationParams] = GEAoptimizer.operators.OperatorFactory.resolve("mutation", obj.options.mutation); %#ok<NASGU>

            % Selection operates on a snapshot (read-only).
            snap = GEAoptimizer.core.PopulationSnapshot.fromPopulation(obj.problem, population);

            nChildren = n - eliteCount;
            chromosomes(1, nChildren) = GEAoptimizer.core.Chromosome();

            childIdx = 1;
            while childIdx <= nChildren
            parentIdx = selectOp(snap, 2, obj.problem.objectiveType, selectionParams);
                p1 = population.chromosomes(parentIdx(1)).genes;
                p2 = population.chromosomes(parentIdx(2)).genes;

                if rand() < crossoverRate
                    [c1, c2] = crossOp(p1, p2, crossoverParams);
                else
                    c1 = p1;
                    c2 = p2;
                end

                c1 = obj.applyMutation(mutOp, c1, mutationParams);
                c2 = obj.applyMutation(mutOp, c2, mutationParams);

                c1 = obj.clampToBounds(c1);
                c2 = obj.clampToBounds(c2);

                chromosomes(childIdx) = GEAoptimizer.core.Chromosome(c1, NaN);
                childIdx = childIdx + 1;
                if childIdx <= nChildren
                    chromosomes(childIdx) = GEAoptimizer.core.Chromosome(c2, NaN);
                    childIdx = childIdx + 1;
                end
            end

            population = GEAoptimizer.core.Population([elites, chromosomes]);
        end
    end

    methods (Access = private)
        function value = getParam(obj, name, defaultValue)
            if isfield(obj.options.params, name)
                value = obj.options.params.(name);
            else
                value = defaultValue;
            end
        end

        function genes = clampToBounds(obj, genes)
            lb = obj.problem.bounds(1, :);
            ub = obj.problem.bounds(2, :);
            genes = min(max(genes, lb), ub);
        end

        function genes = applyMutation(obj, mutOp, genes, mutationParams)
            % Mutation operator contract in this toolbox:
            %   genesOut = mutOp(genesIn, bounds, params)
            %
            % Discrete/binary operators can ignore bounds if not needed.
            genes = mutOp(genes, obj.problem.bounds, mutationParams);
        end
    end
end
