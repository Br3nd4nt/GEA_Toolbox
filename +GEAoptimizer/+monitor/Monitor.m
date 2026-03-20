classdef (Abstract) Monitor < handle
    %MONITOR Observer interface for optimization runs.

    methods (Abstract)
        onStart(obj, problem, options)
        onIteration(obj, iteration, populationSnapshot, history)
        onFinish(obj, result, history)
    end
end
