classdef OptimizerFactory
    %OPTIMIZERFACTORY Creates optimizer instances for gea.solve dispatch.

    methods (Static)
        function optimizer = create(problem, options)
            arguments
                problem (1, 1) GEAoptimizer.Problem
                options (1, 1) GEAoptimizer.Options
            end

            switch options.algorithm
                case "ga"
                    optimizer = GEAoptimizer.alg.GA(problem, options);
                case "gea"
                    optimizer = GEAoptimizer.alg.GEA(problem, options);
                case "sa"
                    optimizer = GEAoptimizer.alg.SA(problem, options);
                case "pso"
                    optimizer = GEAoptimizer.alg.PSO(problem, options);
                otherwise
                    error("Unknown algorithm: %s", options.algorithm);
            end
        end
    end
end

