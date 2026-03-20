classdef Problem
    %PROBLEM Class for defining optimization problem
    
    properties (SetAccess = immutable)
        objectiveType % min or max
        nGenes
        bounds
        fitnessFunction
    end

    methods
        function obj = Problem(objectiveType, nGenes, bounds, fitnessFunction)
            arguments
                objectiveType (1, 1) string {mustBeMember(objectiveType,["min", "max"])}
                nGenes (1, 1) double {mustBeInteger, mustBePositive}
                bounds (2, :) double
                fitnessFunction (1, 1) function_handle
            end
            if size(bounds,2) ~= nGenes
                error("Bounds must be 2 x nGenes.");
            end

            obj.objectiveType = objectiveType;
            obj.nGenes = nGenes;
            obj.bounds = bounds;
            obj.fitnessFunction = fitnessFunction;
        end
    end
end
