classdef RNG
    methods (Static)
        function setSeed(seed)
            rng(seed, "twister");
        end

        function r = randUniform(sz)
            r = rand(sz);
        end

        function r = randInt(low, high, sz)
            r = randi([low high], sz);
        end
    end
end