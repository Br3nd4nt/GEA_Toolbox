classdef GEA < GEAoptimizer.core.PopulationOptimizer
    %GEA Genetic Evolutionary Algorithm (GEA) optimizer (main operators).
    %
    % This is a genericized implementation inspired by Metaheuristics_GEA:
    % it augments classic GA with two additional "scenario" operators:
    %   Scenario 1: Dominant-gene crossover with a dominant chromosome.
    %   Scenario 3: Gene injection (inject dominant genes into a parent).
    %
    % Notes:
    % - Dominant/fixed genes are detected via exact equality in the top part
    %   of the population. This is best suited for discrete/permutation
    %   encodings; for continuous encodings, provide discretized genes or a
    %   custom equality strategy (future extension).
    %
    % Parameters are read from options.params (all have defaults):
    % - pCrossover (0.4), pMutation (0.2)
    % - pScenario1 (0), pScenario3 (0)
    % - pFixedX (0.6): fraction of top-scenario pool used as "fixed threshold"
    % - scenarioCrossoverRate (0.2): relative size of scenario offspring
    % - scenarioMutationRate (0.2): relative size of scenario offspring
    %
    % Operator specs:
    % - options.selection, options.crossover, options.mutation (classic GA)
    % (Mask-mutation scenario is not implemented in this toolbox.)

    properties (Access = private)
        % Cached adaptive weights placeholder (future).
        initialized (1, 1) logical = false
    end

    methods (Access = protected)
        function population = step(obj, population, iter) %#ok<INUSD>
            %STEP One GEA generation (GA + scenario operators + merge/select).

            n = numel(population.chromosomes);
            if n ~= obj.options.populationSize
                error("GEA:PopulationSizeMismatch", "Population size changed unexpectedly.");
            end

            % Sort so "top fraction" is well-defined.
            population = population.sortByFitness(obj.problem.objectiveType);

            % === Classic GA operators ===
            pCrossover = obj.getParam("pCrossover", 0.4);
            pMutation = obj.getParam("pMutation", 0.2);
            eliteCount = obj.getParam("eliteCount", 1);
            if eliteCount < 0 || eliteCount >= n
                error("GEA:InvalidEliteCount", "params.eliteCount must be in [0, populationSize-1].");
            end
            nCrossover = 2 * floor((pCrossover * n) / 2);
            nMutation = floor(pMutation * n);

            [selectOp, ~, selectionParams] = GEAoptimizer.operators.OperatorFactory.resolve("selection", obj.options.selection);
            [crossOp, ~, crossoverParams] = GEAoptimizer.operators.OperatorFactory.resolve("crossover", obj.options.crossover);
            [mutOp, ~, mutationParams] = GEAoptimizer.operators.OperatorFactory.resolve("mutation", obj.options.mutation);

            snap = GEAoptimizer.core.PopulationSnapshot.fromPopulation(obj.problem, population);

            % Crossover children
            popc = repmat(GEAoptimizer.core.Chromosome(), 1, nCrossover);
            for k = 1:2:nCrossover
                parentIdx = selectOp(snap, 2, obj.problem.objectiveType, selectionParams);
                p1 = population.chromosomes(parentIdx(1)).genes;
                p2 = population.chromosomes(parentIdx(2)).genes;
                [c1, c2] = crossOp(p1, p2, crossoverParams);
                popc(k) = GEAoptimizer.core.Chromosome(obj.clampToBounds(c1), NaN);
                popc(k+1) = GEAoptimizer.core.Chromosome(obj.clampToBounds(c2), NaN);
            end

            % Mutation children
            popm = repmat(GEAoptimizer.core.Chromosome(), 1, nMutation);
            for k = 1:nMutation
                idx = randi(n);
                g = population.chromosomes(idx).genes;
                g2 = mutOp(g, obj.problem.bounds, mutationParams);
                popm(k) = GEAoptimizer.core.Chromosome(obj.clampToBounds(g2), NaN);
            end

            % === Scenario operators (GEA-specific) ===
            pSc1 = obj.getParam("pScenario1", 0.0);
            pSc3 = obj.getParam("pScenario3", 0.0);

            scenarioCrossoverRate = obj.getParam("scenarioCrossoverRate", 0.2);
            scenarioMutationRate = obj.getParam("scenarioMutationRate", 0.2);

            % pool sizes for scenario analysis (top fractions)
            nPoolSc1 = max(1, floor(pSc1 * n));
            nPoolSc3 = max(1, floor(pSc3 * n));

            pFixedX = obj.getParam("pFixedX", 0.6); % fraction used as fixed threshold
            if pFixedX <= 0 || pFixedX > 1
                error("GEA:InvalidPFixedX", "params.pFixedX must be in (0, 1].");
            end

            popSc = GEAoptimizer.core.Chromosome.empty();

            % Scenario 1: dominant-gene crossover
            if pSc1 > 0
                nIter = 2 * floor((scenarioCrossoverRate * nPoolSc1) / 2);
                [domGenes, ~] = GEAoptimizer.operators.gea.analyzeDominant(population.chromosomes(1:nPoolSc1), max(1, floor(pFixedX * nPoolSc1)));
                domChrom = GEAoptimizer.core.Chromosome(domGenes, NaN);
                sc1 = repmat(GEAoptimizer.core.Chromosome(), 1, nIter);
                for k = 1:2:nIter
                    parentIdx = selectOp(snap, 1, obj.problem.objectiveType, selectionParams);
                    p2 = population.chromosomes(parentIdx(1)).genes;
                    [c1, c2] = crossOp(domChrom.genes, p2, crossoverParams);
                    sc1(k) = GEAoptimizer.core.Chromosome(obj.clampToBounds(c1), NaN);
                    sc1(k+1) = GEAoptimizer.core.Chromosome(obj.clampToBounds(c2), NaN);
                end
                popSc = [popSc, sc1];
            end

            % Scenario 3: gene injection
            if pSc3 > 0
                nIter = ceil(scenarioMutationRate * nPoolSc3);
                [domGenes, maskDom] = GEAoptimizer.operators.gea.analyzeDominant(population.chromosomes(1:nPoolSc3), max(1, floor(pFixedX * nPoolSc3)));

                sc3 = repmat(GEAoptimizer.core.Chromosome(), 1, nIter);
                % pick parents from the bottom part to diversify
                lo = max(1, n - nPoolSc3 + 1);
                for k = 1:nIter
                    jj = randi([lo n], 1, 1);
                    parent = population.chromosomes(jj).genes;
                    child = GEAoptimizer.operators.gea.geneInjection(domGenes, parent, maskDom);
                    sc3(k) = GEAoptimizer.core.Chromosome(obj.clampToBounds(child), NaN);
                end
                popSc = [popSc, sc3];
            end

            % === Merge pool and select next generation ===
            elites = population.chromosomes(1:eliteCount);
            pool = [elites, population.chromosomes, popc, popm, popSc];
            % Evaluate the entire pool and keep the best N to form next generation.
            poolPop = GEAoptimizer.core.Population(pool);
            poolPop = obj.evaluatePopulation(poolPop);
            poolPop = poolPop.sortByFitness(obj.problem.objectiveType);
            population = GEAoptimizer.core.Population(poolPop.chromosomes(1:n));
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
    end
end
