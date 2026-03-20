classdef SA < GEAoptimizer.alg.Optimizer
    %SA Simulated Annealing (minimal working implementation).
    %
    % This implementation exists primarily to validate the toolbox's
    % end-to-end run logic: Problem/Options/solve, monitoring, callbacks,
    % history collection, and Result creation.

    methods
        function [result, history] = run(obj)
            tStart = tic;
            obj.validateInputs();

            mon = obj.resolveMonitor();
            if ~isempty(mon)
                mon.onStart(obj.problem, obj.options);
            end
            if obj.invokeCallback("onStart", 0, [])
                result = obj.makeResultFromEmpty("userStop", tStart);
                history = GEAoptimizer.core.History();
                if ~isempty(mon)
                    mon.onFinish(result, history);
                end
                return;
            end

            GEAoptimizer.core.RNG.setSeed(obj.options.seed);

            % Current solution is represented as a population of size 1 so we can
            % reuse History and the PopulationSnapshot monitoring mechanism.
            currentPop = obj.initializeCurrentPopulation();
            currentPop = obj.evaluatePopulation(currentPop);

            history = GEAoptimizer.core.History();
            history.addIteration(currentPop, obj.problem.objectiveType);
            obj.maybeMonitorIteration(mon, 0, currentPop, history);
            if obj.invokeCallback("onAfterEvaluation", 0, currentPop, history)
                result = obj.makeResult(history, "userStop", tStart);
                if ~isempty(mon)
                    mon.onFinish(result, history);
                end
                obj.invokeCallback("onFinish", result.iterations, [], history, result);
                return;
            end

            T = obj.getParam("T0", 1.0);
            exitReason = "maxIterations";
            stallCount = 0;
            bestSoFar = history.bestFitness(end);

            for iter = 1:obj.options.maxIterations
                if obj.invokeCallback("onBeforeStep", iter, currentPop, history)
                    exitReason = "userStop";
                    break;
                end

                candidatePop = obj.proposeNeighbor(currentPop);
                candidatePop = obj.evaluatePopulation(candidatePop);

                if obj.acceptMove(currentPop.chromosomes.fitness, candidatePop.chromosomes.fitness, T)
                    currentPop = candidatePop;
                end

                if obj.invokeCallback("onAfterStep", iter, currentPop, history)
                    exitReason = "userStop";
                    break;
                end

                history.addIteration(currentPop, obj.problem.objectiveType);
                obj.maybeMonitorIteration(mon, iter, currentPop, history);

                if obj.invokeCallback("onAfterEvaluation", iter, currentPop, history)
                    exitReason = "userStop";
                    break;
                end

                currentBest = history.bestFitness(end);
                if obj.hitTarget(currentBest)
                    exitReason = "targetFitness";
                    break;
                end

                if obj.options.stallIterations > 0
                    if obj.isImprovement(currentBest, bestSoFar)
                        bestSoFar = currentBest;
                        stallCount = 0;
                    else
                        stallCount = stallCount + 1;
                        if stallCount >= obj.options.stallIterations
                            exitReason = "stall";
                            break;
                        end
                    end
                end

                T = T * obj.getParam("alpha", 0.99);
            end

            result = obj.makeResult(history, exitReason, tStart);
            if ~isempty(mon)
                mon.onFinish(result, history);
            end
            obj.invokeCallback("onFinish", result.iterations, [], history, result);
        end
    end

    methods (Access = private)
        function validateInputs(obj)
            if obj.problem.nGenes <= 0
                error("SA:InvalidProblem", "Problem.nGenes must be positive.");
            end
            if any(obj.problem.bounds(2, :) < obj.problem.bounds(1, :))
                error("SA:InvalidBounds", "Each upper bound must be >= lower bound.");
            end
            if obj.getParam("T0", 1.0) <= 0
                error("SA:InvalidTemperature", "params.T0 must be positive.");
            end
            alpha = obj.getParam("alpha", 0.99);
            if alpha <= 0 || alpha >= 1
                error("SA:InvalidCoolingRate", "params.alpha must be in (0, 1).");
            end
            if obj.getParam("stepSize", 0.1) <= 0
                error("SA:InvalidStepSize", "params.stepSize must be positive.");
            end

            nf = obj.getParam("neighborFcn", []);
            if ~(isempty(nf) || isa(nf, "function_handle"))
                error("SA:InvalidNeighborFcn", "params.neighborFcn must be a function handle or empty.");
            end
        end

        function mon = resolveMonitor(obj)
            mon = obj.options.monitor;
            if isa(mon, "function_handle")
                mon = GEAoptimizer.monitor.FunctionMonitor(mon);
            end
        end

        function population = initializeCurrentPopulation(obj)
            seedPop = obj.options.initialPopulation;
            if isempty(seedPop)
                population = obj.options.populationInitializer(obj.problem, 1);
            elseif isa(seedPop, "GEAoptimizer.core.Population")
                if isempty(seedPop.chromosomes)
                    population = obj.options.populationInitializer(obj.problem, 1);
                else
                    population = GEAoptimizer.core.Population(seedPop.chromosomes(1));
                end
            else
                seedPop = double(seedPop);
                if size(seedPop, 1) == 0
                    population = obj.options.populationInitializer(obj.problem, 1);
                else
                    population = GEAoptimizer.core.Population.fromGenes(obj.problem, seedPop(1, :));
                end
            end

            if ~isa(population, "GEAoptimizer.core.Population") || isempty(population.chromosomes)
                error("SA:InvalidInitializer", "Initializer must provide at least one chromosome.");
            end
            if numel(population.chromosomes) ~= 1
                population = GEAoptimizer.core.Population(population.chromosomes(1));
            end
        end

        function pop = evaluatePopulation(obj, pop)
            genes = pop.chromosomes.genes;
            if isvector(genes)
                genes = reshape(genes, 1, []);
            end
            fitness = obj.problem.fitnessFunction(genes);
            if ~isscalar(fitness)
                if numel(fitness) ~= 1
                    error("SA:InvalidFitness", "Fitness function must return a scalar for a single chromosome.");
                end
                fitness = fitness(1);
            end
            pop.chromosomes.fitness = double(fitness);
        end

        function candidate = proposeNeighbor(obj, current)
            lb = obj.problem.bounds(1, :);
            ub = obj.problem.bounds(2, :);
            x = current.chromosomes.genes;
            neighborFcn = obj.getParam("neighborFcn", []);
            if isempty(neighborFcn)
                step = obj.getParam("stepSize", 0.1) * randn(size(x));
                x2 = x + step;
            else
                x2 = neighborFcn(x, obj.problem, obj.options);
            end
            x2 = min(max(x2, lb), ub);
            candidate = GEAoptimizer.core.Population(GEAoptimizer.core.Chromosome(x2, NaN));
        end

        function value = getParam(obj, name, defaultValue)
            % Read algorithm-specific parameters from options.params with a default.
            if isfield(obj.options.params, name)
                value = obj.options.params.(name);
            else
                value = defaultValue;
            end
        end

        function tf = acceptMove(obj, currentFitness, candidateFitness, T)
            % Accept always if candidate improves. Otherwise accept with
            % probability exp(-delta/T) where delta is the "worsening amount".
            if obj.problem.objectiveType == "min"
                delta = candidateFitness - currentFitness;
            else
                delta = currentFitness - candidateFitness;
            end
            if delta <= 0
                tf = true;
                return;
            end
            tf = rand() < exp(-delta / max(T, eps));
        end

        function tf = hitTarget(obj, currentBest)
            if isnan(obj.options.targetFitness)
                tf = false;
                return;
            end
            if obj.problem.objectiveType == "min"
                tf = currentBest <= obj.options.targetFitness;
            else
                tf = currentBest >= obj.options.targetFitness;
            end
        end

        function tf = isImprovement(obj, candidate, reference)
            if obj.problem.objectiveType == "min"
                tf = candidate < reference;
            else
                tf = candidate > reference;
            end
        end

        function maybeMonitorIteration(obj, mon, iter, population, history)
            if isempty(mon)
                return;
            end
            snap = GEAoptimizer.core.PopulationSnapshot.fromPopulation(obj.problem, population);
            mon.onIteration(iter, snap, history);
        end

        function stop = invokeCallback(obj, name, iteration, population, history, result)
            arguments
                obj
                name (1, 1) string
                iteration (1, 1) double
                population = []
                history = []
                result = []
            end
            stop = false;
            if ~isstruct(obj.options.callbacks) || ~isfield(obj.options.callbacks, name)
                return;
            end
            cb = obj.options.callbacks.(name);
            if isempty(cb)
                return;
            end
            if isempty(population)
                snap = [];
            else
                snap = GEAoptimizer.core.PopulationSnapshot.fromPopulation(obj.problem, population);
            end
            ctx = struct("problem", obj.problem, "options", obj.options, "algorithm", obj.options.algorithm);
            out = cb(iteration, snap, history, ctx, result);
            if islogical(out) && isscalar(out) && out
                stop = true;
            end
        end

        function result = makeResult(obj, history, exitReason, tStart)
            bestGenes = history.bestGenes{end};
            bestFitness = history.bestFitness(end);
            elapsedTimeSeconds = toc(tStart);
            result = GEAoptimizer.Result(bestGenes, bestFitness, numel(history.bestFitness)-1, exitReason, elapsedTimeSeconds, obj.options.algorithm);
        end

        function result = makeResultFromEmpty(obj, exitReason, tStart)
            elapsedTimeSeconds = toc(tStart);
            result = GEAoptimizer.Result([], NaN, 0, exitReason, elapsedTimeSeconds, obj.options.algorithm);
        end
    end
end
