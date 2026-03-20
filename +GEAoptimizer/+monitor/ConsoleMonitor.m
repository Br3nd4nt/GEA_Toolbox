classdef ConsoleMonitor < GEAoptimizer.monitor.Monitor
    %CONSOLEMONITOR Minimal console logger.

    properties
        printEvery (1, 1) double {mustBeInteger, mustBePositive} = 1
    end

    methods
        function obj = ConsoleMonitor(printEvery)
            if nargin > 0
                obj.printEvery = printEvery;
            end
        end

        function onStart(~, problem, options)
            fprintf("Starting %s (%s), pop=%d, iters=%d, seed=%d\n", options.algorithm, problem.objectiveType, options.populationSize, options.maxIterations, options.seed);
        end

        function onIteration(obj, iteration, ~, history)
            if mod(iteration, obj.printEvery) ~= 0
                return;
            end
            fprintf("iter=%d best=%g mean=%g\n", iteration, history.bestFitness(end), history.meanFitness(end));
        end

        function onFinish(~, result, ~)
            fprintf("Done (%s): best=%g after %d iterations in %.3fs\n", result.exitReason, result.bestFitness, result.iterations, result.elapsedTimeSeconds);
        end
    end
end
