classdef Result
    %RESULT Immutable optimization output (public API).

    properties (SetAccess = immutable)
        bestGenes
        bestFitness (1, 1) double
        iterations (1, 1) double {mustBeInteger, mustBeNonnegative}
        exitReason (1, 1) string
        elapsedTimeSeconds (1, 1) double {mustBeNonnegative}
        algorithm (1, 1) string
    end

    methods
        function obj = Result(bestGenes, bestFitness, iterations, exitReason, elapsedTimeSeconds, algorithm)
            arguments
                bestGenes
                bestFitness (1, 1) double
                iterations (1, 1) double {mustBeInteger, mustBeNonnegative}
                exitReason (1, 1) string
                elapsedTimeSeconds (1, 1) double {mustBeNonnegative}
                algorithm (1, 1) string
            end

            obj.bestGenes = bestGenes;
            obj.bestFitness = bestFitness;
            obj.iterations = iterations;
            obj.exitReason = exitReason;
            obj.elapsedTimeSeconds = elapsedTimeSeconds;
            obj.algorithm = algorithm;
        end
    end
end

