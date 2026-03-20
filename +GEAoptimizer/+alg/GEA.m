classdef GEA < GEAoptimizer.alg.PopulationOptimizer
    %GEA Genetic Evolutionary Algorithm optimizer (scaffolding only).

    methods (Access = protected)
        function population = step(~, ~, ~)
            error("GEAoptimizer:NotImplemented", "GEA step() is not implemented yet (GEA operators/algorithm core missing).");
        end
    end
end
