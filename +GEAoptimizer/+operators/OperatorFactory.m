classdef OperatorFactory
    %OPERATORFACTORY Resolves operator variants into function handles.
    %
    % This does not run operators; it only standardizes how options specify
    % a "fixed" operator or a "random among variants" operator choice.

    methods (Static)
        function [opHandle, variant, params] = resolve(kind, spec)
            arguments
                kind (1, 1) string {mustBeMember(kind,["selection","crossover","mutation"])}
                spec
            end

            [mode, variants, params] = GEAoptimizer.operators.OperatorFactory.parseSpec(kind, spec);

            if mode == "random"
                variant = variants(randi(numel(variants)));
            else
                variant = variants(1);
            end

            opHandle = GEAoptimizer.operators.OperatorFactory.variantToHandle(kind, variant);
        end
    end

    methods (Access = private, Static)
        function [mode, variants, params] = parseSpec(kind, spec)
            defaults = GEAoptimizer.operators.OperatorFactory.defaultVariants(kind);
            params = struct();

            if isstring(spec) || ischar(spec)
                s = string(spec);
                if s == "random"
                    mode = "random";
                    variants = defaults;
                else
                    mode = "fixed";
                    variants = s;
                end
                return;
            end

            if isstruct(spec)
                if isfield(spec, "mode")
                    mode = string(spec.mode);
                else
                    mode = "fixed";
                end
                if ~ismember(mode, ["fixed","random"])
                    error("OperatorFactory:InvalidMode", "Operator spec.mode must be ""fixed"" or ""random"".");
                end

                if isfield(spec, "variants")
                    variants = string(spec.variants);
                    if isempty(variants)
                        variants = defaults;
                    end
                else
                    variants = defaults;
                end

                if isfield(spec, "params")
                    if ~isstruct(spec.params)
                        error("OperatorFactory:InvalidParams", "Operator spec.params must be a struct.");
                    end
                    params = spec.params;
                end

                return;
            end

            error("OperatorFactory:InvalidSpec", "Operator spec must be a string or struct.");
        end

        function variants = defaultVariants(kind)
            switch kind
                case "selection"
                    variants = ["tournament","roulette"];
                case "crossover"
                    variants = ["onepoint","twopoint"];
                case "mutation"
                    variants = ["swap","bigswap","insertion","reversion","randomint"];
            end
        end

        function op = variantToHandle(kind, variant)
            key = lower(string(variant));
            switch kind
                case "selection"
                    switch key
                        case "tournament"
                            op = @GEAoptimizer.operators.selection.tournament;
                        case "roulette"
                            op = @GEAoptimizer.operators.selection.roulette;
                        otherwise
                            error("OperatorFactory:UnknownVariant", "Unknown selection operator: %s", key);
                    end
                case "crossover"
                    switch key
                        case "onepoint"
                            op = @GEAoptimizer.operators.crossover.onepoint;
                        case "twopoint"
                            op = @GEAoptimizer.operators.crossover.twopoint;
                        otherwise
                            error("OperatorFactory:UnknownVariant", "Unknown crossover operator: %s", key);
                    end
                case "mutation"
                    switch key
                        case "swap"
                            op = @GEAoptimizer.operators.mutation.swap;
                        case "bigswap"
                            op = @GEAoptimizer.operators.mutation.bigswap;
                        case "insertion"
                            op = @GEAoptimizer.operators.mutation.insertion;
                        case "reversion"
                            op = @GEAoptimizer.operators.mutation.reversion;
                        case "randomint"
                            op = @GEAoptimizer.operators.mutation.randomint;
                        otherwise
                            error("OperatorFactory:UnknownVariant", "Unknown mutation operator: %s", key);
                    end
            end
        end
    end
end
