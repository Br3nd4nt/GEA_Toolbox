classdef FunctionMonitor < GEAoptimizer.monitor.Monitor
    %FUNCTIONMONITOR Wraps a user function into the Monitor interface.
    %
    % The wrapped function is called as:
    %   fn(event, iteration, populationSnapshot, history, ctx, result)
    %
    % where event is one of: "start", "iteration", "finish".

    properties (SetAccess = immutable)
        fn (1, 1) function_handle
    end
    
    properties (Access = private)
        ctxCached = []
    end

    methods
        function obj = FunctionMonitor(fn)
            arguments
                fn (1, 1) function_handle
            end
            obj.fn = fn;
        end

        function onStart(obj, problem, options)
            % At start we pass a ctx that includes problem/options so the user
            % can inspect bounds/objective configuration.
            ctx = struct("problem", problem, "options", options, "algorithm", options.algorithm);
            obj.ctxCached = ctx;
            obj.fn("start", 0, [], [], ctx, []);
        end

        function onIteration(obj, iteration, populationSnapshot, history)
            % Iteration events are the "between steps" observation point.
            % populationSnapshot is immutable and safe to inspect.
            if isempty(obj.ctxCached)
                ctx = struct("problem", [], "options", [], "algorithm", []);
            else
                ctx = obj.ctxCached;
            end
            obj.fn("iteration", iteration, populationSnapshot, history, ctx, []);
        end

        function onFinish(obj, result, history)
            % Finish event gets the final Result object.
            if isempty(obj.ctxCached)
                ctx = struct("problem", [], "options", [], "algorithm", result.algorithm);
            else
                ctx = obj.ctxCached;
            end
            obj.fn("finish", result.iterations, [], history, ctx, result);
        end
    end
end
