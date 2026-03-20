classdef GA < GEAoptimizer.alg.PopulationOptimizer
    %GA Genetic Algorithm optimizer (scaffolding only).

    methods (Access = protected)
        function population = step(~, ~, ~)
            error("GEAoptimizer:NotImplemented", "GA step() is not implemented yet (operators/algorithm core missing).");
        end
    end
end
