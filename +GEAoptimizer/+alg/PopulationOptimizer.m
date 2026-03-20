classdef (Abstract) PopulationOptimizer < GEAoptimizer.alg.Optimizer
    %POPULATIONOPTIMIZER Shared run-loop scaffolding for population-based methods.
    %
    % This class intentionally does NOT implement algorithm specifics such as
    % selection/crossover/mutation. Subclasses must provide the per-iteration
    % update step.

    properties (Access = private)
        % Cached/resolved monitor instance.
        % - If options.monitor is a Monitor object, it's used as-is.
        % - If options.monitor is a function handle, it's wrapped into a
        %   GEAoptimizer.monitor.FunctionMonitor.
        monitorResolved = []
    end

    methods
        function [result, history] = run(obj)
            tStart = tic;
            obj.validateInputs();

            % Resolve the monitor once (and cache it). The monitor is distinct
            % from callbacks: monitors observe; callbacks can request stopping.
            mon = obj.getMonitor();
            if ~isempty(mon)
                mon.onStart(obj.problem, obj.options);
            end
            obj.invokeCallback("onStart", 0, []);

            GEAoptimizer.core.RNG.setSeed(obj.options.seed);

            % Initialize and evaluate the initial population (iteration 0).
            population = obj.initializePopulation();
            population = obj.evaluatePopulation(population);

            history = GEAoptimizer.core.History();
            history.addIteration(population, obj.problem.objectiveType);
            obj.maybeMonitorIteration(0, population, history);
            if obj.invokeCallback("onAfterEvaluation", 0, population, history)
                result = obj.makeResult(history, "userStop", tStart);
                if ~isempty(mon)
                    mon.onFinish(result, history);
                end
                obj.invokeCallback("onFinish", result.iterations, [], history, result);
                return;
            end

            exitReason = "maxIterations";
            stallCount = 0;
            bestSoFar = history.bestFitness(end);

            for iter = 1:obj.options.maxIterations
                % Callback before algorithm operators for this iteration.
                if obj.invokeCallback("onBeforeStep", iter, population, history)
                    exitReason = "userStop";
                    break;
                end

                % One algorithm iteration (selection/crossover/mutation/etc.).
                % Subclasses implement step(); this scaffolding stays generic.
                population = obj.step(population, iter);

                % Callback after operators, before evaluation.
                if obj.invokeCallback("onAfterStep", iter, population, history)
                    exitReason = "userStop";
                    break;
                end

                % Evaluate the new population and record history.
                population = obj.evaluatePopulation(population);
                history.addIteration(population, obj.problem.objectiveType);

                % Monitor sees a read-only snapshot of population state.
                obj.maybeMonitorIteration(iter, population, history);
                if obj.invokeCallback("onAfterEvaluation", iter, population, history)
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
            end

            result = obj.makeResult(history, exitReason, tStart);

            if ~isempty(mon)
                mon.onFinish(result, history);
            end
            obj.invokeCallback("onFinish", result.iterations, [], history, result);
        end
    end

    methods (Access = protected)
        function validateInputs(obj)
            if obj.options.populationSize <= 0
                error("populationSize must be positive.");
            end
            if ~isa(obj.options.populationInitializer, "function_handle")
                error("Options:InvalidPopulationInitializer", "populationInitializer must be a function handle.");
            end
            if ~isempty(obj.options.initialPopulation)
                if ~(isa(obj.options.initialPopulation, "GEAoptimizer.core.Population") || isnumeric(obj.options.initialPopulation))
                    error("Options:InvalidInitialPopulation", "initialPopulation must be a genes matrix or GEAoptimizer.core.Population.");
                end
            end
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

        function pop = evaluatePopulation(obj, pop)
            % Evaluate fitness for each chromosome.
            %
            % Fitness function contract:
            %   - Input: genes matrix of size (populationSize x nGenes)
            %   - Output: scalar OR vector with one value per row
            genes = reshape([pop.chromosomes.genes], obj.problem.nGenes, []).';
            fitness = obj.problem.fitnessFunction(genes);
            if isscalar(fitness)
                fitness = repmat(fitness, size(genes, 1), 1);
            end
            if numel(fitness) ~= size(genes, 1)
                error("Fitness function must return scalar or one fitness per chromosome.");
            end
            fitness = fitness(:).';
            for i = 1:numel(pop.chromosomes)
                pop.chromosomes(i).fitness = fitness(i);
            end
        end

        function maybeMonitorIteration(obj, iter, population, history)
            mon = obj.getMonitor();
            if isempty(mon)
                return;
            end
            % IMPORTANT: pass a snapshot copy so user code cannot mutate the
            % internal population (handle classes are reference-like).
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
            % Callbacks are optional function handles in options.callbacks.
            % If a callback returns logical true, we stop the run.
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

            % Lightweight context struct; stable fields only.
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

        function population = initializePopulation(obj)
            % Initialize population using either:
            %   1) options.initialPopulation (genes matrix or Population), plus optional fill
            %   2) options.populationInitializer(problem, n) to generate from bounds
            %
            % The initializer is intentionally not algorithm-specific.

            nTarget = obj.options.populationSize;
            seedPop = obj.options.initialPopulation;

            if isempty(seedPop)
                population = obj.options.populationInitializer(obj.problem, nTarget);
                obj.mustBePopulation(population, "populationInitializer");
                return;
            end

            if isa(seedPop, "GEAoptimizer.core.Population")
                seedPopulation = seedPop;
            else
                seedPopulation = GEAoptimizer.core.Population.fromGenes(obj.problem, seedPop);
            end

            nSeed = numel(seedPopulation.chromosomes);
            if nSeed == 0
                population = obj.options.populationInitializer(obj.problem, nTarget);
                obj.mustBePopulation(population, "populationInitializer");
                return;
            end

            if nSeed >= nTarget
                population = GEAoptimizer.core.Population(seedPopulation.chromosomes(1:nTarget));
                return;
            end

            % Fill the remainder with the configured initializer.
            fillPopulation = obj.options.populationInitializer(obj.problem, nTarget - nSeed);
            obj.mustBePopulation(fillPopulation, "populationInitializer");
            population = GEAoptimizer.core.Population([seedPopulation.chromosomes, fillPopulation.chromosomes]);
        end

        function mustBePopulation(~, population, sourceName)
            if ~isa(population, "GEAoptimizer.core.Population")
                error("Options:InvalidPopulationInitializer", "%s must return GEAoptimizer.core.Population.", sourceName);
            end
        end
    end

    methods (Access = private)
        function mon = getMonitor(obj)
            if ~isempty(obj.monitorResolved)
                mon = obj.monitorResolved;
                return;
            end

            mon = obj.options.monitor;
            if isa(mon, "function_handle")
                % Allow a simple function handle monitor: wrap it into Monitor.
                mon = GEAoptimizer.monitor.FunctionMonitor(mon);
            end
            obj.monitorResolved = mon;
        end
    end

    methods (Access = protected, Abstract)
        % One iteration update: produce the next population.
        % Algorithm operators belong in implementations of this method.
        population = step(obj, population, iter)
    end
end
