classdef OptimizerFactory
    %OPTIMIZERFACTORY Creates optimizer instances for gea.solve dispatch.

    methods (Static)
        function optimizer = create(problem, options)
            arguments
                problem (1, 1) GEAoptimizer.Problem
                options (1, 1) GEAoptimizer.Options
            end

            if isa(options.algorithm, "function_handle")
                optimizer = options.algorithm(problem, options);
                if ~isa(optimizer, "GEAoptimizer.alg.Optimizer")
                    error("OptimizerFactory:InvalidFactory", "Algorithm factory must return a GEAoptimizer.alg.Optimizer.");
                end
                return;
            end

            alg = string(options.algorithm);
            switch alg
                case "ga"
                    optimizer = GEAoptimizer.alg.GA(problem, options);
                case "gea"
                    optimizer = GEAoptimizer.alg.GEA(problem, options);
                case "sa"
                    optimizer = GEAoptimizer.alg.SA(problem, options);
                case "pso"
                    optimizer = GEAoptimizer.alg.PSO(problem, options);
                otherwise
                    error("Unknown algorithm: %s", alg);
            end
        end
    end
end
