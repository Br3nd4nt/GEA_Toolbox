classdef Optimizer < handle
    %OPTIMIZER Interface for optimization algorithms
    
    properties (SetAccess = protected)
        problem
        options
    end
    
    methods
        function obj = Optimizer(problem,options)
            obj.problem = problem;
            obj.options = options;
        end
    end

    methods (Abstract)
        [result, history] = run(obj)
    end
end

