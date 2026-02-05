# GEA Toolbox (MATLAB)

Short project structure overview and module roles.

## Architecture (layers)

1. User API
- Problem definition (`GEAoptimizer.Problem`)
- Algorithm selection and parameters (`GEAoptimizer.Options`)
- Optimization entry point (`GEAoptimizer.solve`)

2. Algorithm Layer
- Algorithm implementations: `GA`, `GEA`, `SA`, `PSO`

3. Core Primitives
- Base entities: population, chromosome, history, RNG

4. Operators
- Selection / crossover / mutation operators
- GEA-specific operators

## Directory Structure

```
+GEAoptimizer/
│
├── solve.m                 % main entry point (public API)
├── Problem.m               % problem definition
├── Options.m               % parameters and configuration
├── Result.m                % optimization result
│
├── +alg/                   % algorithm implementations
│   ├── GA.m
│   ├── GEA.m
│   ├── SA.m
│   └── PSO.m
│
├── +core/                  % core entities
│   ├── Chromosome.m
│   ├── Population.m
│   ├── History.m
│   └── RNG.m
│
├── +operators/             % operators
│   ├── +selection/
│   ├── +crossover/
│   ├── +mutation/
│   └── +gea/
│       ├── binaryMatrixCreation.m
│       ├── directedMutation.m
│       ├── geneInjection.m
│       └── robustCrossover.m
│
├── +monitor/               % monitoring
│   ├── Monitor.m
│   └── ConsoleMonitor.m
│
├── examples/               % usage examples
├── tests/                  % tests
└── doc/                    % documentation
```

## Example Usage (API idea)

```matlab
problem = GEAoptimizer.Problem("min", nGenes, bounds, @fitness);
opts = GEAoptimizer.Options("algorithm","gea","populationSize",50);

[result, history] = GEAoptimizer.solve(problem, opts);
```

## Notes
- Users should only interact with `GEAoptimizer.solve`, `GEAoptimizer.Problem`, `GEAoptimizer.Options`.
- Everything else is internal implementation detail.
