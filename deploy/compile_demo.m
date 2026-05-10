function compile_demo(varargin)
%COMPILE_DEMO Build compiled CLI demo (requires MATLAB Compiler).
%
% Run from repo root in a licensed MATLAB with MATLAB Compiler:
%   compile_demo("outputDir","dist/GEA_Demo","mcrRelease","R2024b")
%
% The output folder will contain a runnable executable and the CTF archive.

args = struct( ...
    "outputDir", fullfile(pwd, "dist", "GEA_Demo"), ...
    "mcrRelease", "" ...
);

if mod(nargin, 2) ~= 0
    error("compile_demo:InvalidArgs", "Use name/value pairs.");
end
for k = 1:2:nargin
    args.(string(varargin{k})) = varargin{k + 1};
end

outDir = char(args.outputDir);
if ~exist(outDir, "dir")
    mkdir(outDir);
end

entry = fullfile(pwd, "examples", "demos", "GEA_demo_runner.m");
assert(exist(entry, "file") == 2, "Missing entrypoint: %s", entry);

% Include all required files/folders.
addFiles = {
    fullfile(pwd, "+GEAoptimizer")
    fullfile(pwd, "examples", "demos")
    fullfile(pwd, "examples", "GQAP")
    fullfile(pwd, "README.md")
};

fprintf("Compiling entrypoint: %s\n", entry);
fprintf("Output dir: %s\n", outDir);
fprintf("Host: %s %s\n", string(computer), string(computer("arch")));

compiler.build.standaloneApplication(entry, ...
    "OutputDir", outDir, ...
    "AdditionalFiles", addFiles);

fprintf("Done. Next: build docker image from %s\n", outDir);
end
