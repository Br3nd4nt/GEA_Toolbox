classdef Options
    %OPTIONS Configuration for an optimization run (public API).
    %
    % Example:
    %   opts = GEAoptimizer.Options("algorithm","ga","populationSize",50);

    properties (SetAccess = immutable)
        % Algorithm selection:
        % - string: one of "ga", "gea", "sa", "pso"
        % - function_handle: factory called as f(problem, options) returning an Optimizer
        algorithm = "ga"
        populationSize (1, 1) double {mustBeInteger, mustBePositive} = 50
        maxIterations (1, 1) double {mustBeInteger, mustBePositive} = 200
        seed (1, 1) double {mustBeInteger, mustBeNonnegative} = 0

        % Population initialization
        % - If provided, initialPopulation seeds the run.
        % - If fewer rows than populationSize, the remainder is filled using
        %   populationInitializer.
        initialPopulation = []   % double matrix (N x nGenes) OR GEAoptimizer.core.Population
        populationInitializer (1, 1) function_handle = @GEAoptimizer.init.uniform % (problem, n) -> Population

        % Early-stop options (generic; algorithms may ignore if unsupported)
        targetFitness (1, 1) double = NaN
        stallIterations (1, 1) double {mustBeInteger, mustBeNonnegative} = 0

        % Monitoring
        monitor = []
        callbacks = struct()

        % Algorithm-specific parameters bag.
        % Algorithms should read from here instead of adding new Options fields.
        params (1, 1) struct = struct()

        % Operator configuration (used by population-based algorithms like GA/GEA).
        %
        % Each field can be:
        %   - a string variant name (e.g., "tournament")
        %   - "random" to pick randomly from defaults / provided variants
        %   - a struct with fields:
        %       .mode: "fixed" | "random"
        %       .variants: string array of variant names
        %       .params: (optional) struct passed to operator implementation
        selection = "tournament"
        crossover = "onepoint"
        mutation = "swap"
    end

    methods
        function obj = Options(nameValueArgs)
            arguments
                nameValueArgs.algorithm = "ga"
                nameValueArgs.populationSize (1, 1) double = 50
                nameValueArgs.maxIterations (1, 1) double = 200
                nameValueArgs.seed (1, 1) double = 0
                nameValueArgs.initialPopulation = []
                nameValueArgs.populationInitializer (1, 1) function_handle = @GEAoptimizer.init.uniform
                nameValueArgs.targetFitness (1, 1) double = NaN
                nameValueArgs.stallIterations (1, 1) double = 0
                nameValueArgs.monitor = []
                nameValueArgs.params (1, 1) struct = struct()
                % callbacks is a struct of function handles that run during the
                % main loop (in addition to monitor). Each field is optional:
                %   - onStart(iter, popSnap, history, ctx, result)
                %   - onBeforeStep(iter, popSnap, history, ctx, result)
                %   - onAfterStep(iter, popSnap, history, ctx, result)
                %   - onAfterEvaluation(iter, popSnap, history, ctx, result)
                %   - onFinish(iter, popSnap, history, ctx, result)
                %
                % If a callback returns logical true, the run stops with
                % exitReason="userStop".
                nameValueArgs.callbacks = struct()
                nameValueArgs.selection = "random"
                nameValueArgs.crossover = "random"
                nameValueArgs.mutation = "random"
            end

            obj.algorithm = nameValueArgs.algorithm;
            obj.populationSize = nameValueArgs.populationSize;
            obj.maxIterations = nameValueArgs.maxIterations;
            obj.seed = nameValueArgs.seed;
            obj.initialPopulation = nameValueArgs.initialPopulation;
            obj.populationInitializer = nameValueArgs.populationInitializer;
            obj.targetFitness = nameValueArgs.targetFitness;
            obj.stallIterations = nameValueArgs.stallIterations;
            obj.monitor = nameValueArgs.monitor;
            obj.callbacks = obj.normalizeCallbacks(nameValueArgs.callbacks);
            obj.params = nameValueArgs.params;
            obj.selection = nameValueArgs.selection;
            obj.crossover = nameValueArgs.crossover;
            obj.mutation = nameValueArgs.mutation;
        end
    end

    methods (Access = private, Static)
        function cb = normalizeCallbacks(cb)
            if isempty(cb)
                cb = struct();
            end
            if ~isstruct(cb)
                error("Options:InvalidCallbacks", "callbacks must be a struct of function handles.");
            end
            % Normalize missing fields to [] so call sites can check simply.
            cb = GEAoptimizer.Options.ensureCallbackField(cb, "onStart");
            cb = GEAoptimizer.Options.ensureCallbackField(cb, "onBeforeStep");
            cb = GEAoptimizer.Options.ensureCallbackField(cb, "onAfterStep");
            cb = GEAoptimizer.Options.ensureCallbackField(cb, "onAfterEvaluation");
            cb = GEAoptimizer.Options.ensureCallbackField(cb, "onFinish");
        end

        function cb = ensureCallbackField(cb, name)
            if ~isfield(cb, name)
                cb.(name) = [];
                return;
            end
            val = cb.(name);
            if ~(isempty(val) || isa(val, "function_handle"))
                error("Options:InvalidCallbacks", "callbacks.%s must be a function handle or empty.", name);
            end
        end
    end
end
