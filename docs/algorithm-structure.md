# Genetic Algorithm Structure (GEA Toolbox)

This document describes the *algorithm structure* used by the toolbox: what objects exist, what the main loop does, and where GA/GEA operators are expected to run.

## Core concepts

- **Gene**: one decision variable (one element of the `genes` vector).
- **Chromosome**: one candidate solution with:
  - `genes` (1 × `nGenes`)
  - `fitness` (scalar)
- **Population**: an array of chromosomes (size = `populationSize`).

## Problem definition (`GEAoptimizer.Problem`)

A run is defined by a `Problem` object:

- `objectiveType`: `"min"` or `"max"`
- `nGenes`: number of genes in one chromosome
- `bounds`: a 2 × `nGenes` matrix (`bounds(1,:)` = lower bounds, `bounds(2,:)` = upper bounds)
- `fitnessFunction`: a function handle called as:
  - `fitness = fitnessFunction(genesMatrix)`
  - where `genesMatrix` is `populationSize × nGenes`
  - the output must be one value per chromosome (vector length = `populationSize`)

## Run configuration (`GEAoptimizer.Options`)

`Options` configures the generic run loop:

- `algorithm`: `"ga" | "gea" | "sa" | "pso"`
- `populationSize`
- `maxIterations`
- `seed` (reproducibility)
- stopping rules:
  - `targetFitness` (optional)
  - `stallIterations` (optional)
- monitoring hooks:
  - `monitor` (Monitor object *or* a function handle, wrapped automatically)
  - `callbacks` (struct of function handles for finer-grained hooks)

## Main loop scaffold (`GEAoptimizer.alg.PopulationOptimizer`)

Population-based algorithms (GA/GEA) use the shared scaffold implemented in:

- `+GEAoptimizer/+alg/PopulationOptimizer.m`

### High-level flow

1) **Resolve monitor**
   - `options.monitor` can be either a `GEAoptimizer.monitor.Monitor` object or a function handle.
   - If it’s a function handle, it is wrapped into `GEAoptimizer.monitor.FunctionMonitor`.

2) **Start hooks**
   - `monitor.onStart(problem, options)` (if provided)
   - callback: `callbacks.onStart(...)` (if provided)

3) **Initialization**
   - `population = initializePopulation()` (implemented by the algorithm class)
   - `population = evaluatePopulation(population)` assigns `fitness` to each chromosome

4) **History recording (iteration 0)**
   - `history.addIteration(population, objectiveType)`
   - `monitor.onIteration(0, snapshot, history)` (snapshot is read-only)
   - callback: `callbacks.onAfterEvaluation(0, ...)` (optional stop)

5) **Iterations**
   For `iter = 1..maxIterations`:
   - callback: `callbacks.onBeforeStep(iter, ...)` (optional stop)
   - `population = step(population, iter)` (**algorithm-specific operators live here**)
   - callback: `callbacks.onAfterStep(iter, ...)` (optional stop)
   - `population = evaluatePopulation(population)`
   - `history.addIteration(population, objectiveType)`
   - `monitor.onIteration(iter, snapshot, history)`
   - callback: `callbacks.onAfterEvaluation(iter, ...)` (optional stop)
   - stopping checks:
     - `targetFitness`
     - `stallIterations`
     - `maxIterations`

6) **Finish**
   - build a `GEAoptimizer.Result` (best genes/fitness, iterations, exit reason, timing)
   - `monitor.onFinish(result, history)`
   - callback: `callbacks.onFinish(..., result)`

## Where GA/GEA operators go

The scaffold **does not** implement operators. Operators belong inside the algorithm’s `step()` method:

- `+GEAoptimizer/+alg/GA.m` implements:
  - `initializePopulation()` (already provided)
  - `step(...)` (**not implemented yet**)
- `+GEAoptimizer/+alg/GEA.m` implements:
  - `initializePopulation()` (already provided)
  - `step(...)` (**not implemented yet**)

### Typical GA step pipeline (conceptual)

Within `step()` you typically implement the stage pipeline:

1) **Selection** (pick parents)
2) **Crossover** (produce offspring genes)
3) **Mutation** (perturb offspring genes)
4) **Replacement / Elitism** (form the next population)
5) **Bounds/constraints handling** (clamp/repair genes to `[lb, ub]`)

If you want monitoring between these sub-stages, the recommended design is to add stage-specific callbacks such as:

- `onAfterSelection`
- `onAfterCrossover`
- `onAfterMutation`
- `onAfterReplacement`

and invoke them from within `GA.step()` / `GEA.step()` with `PopulationSnapshot` objects.

## Monitoring and “read-only access”

The toolbox enforces “observe-only” access by passing monitors/callbacks a snapshot:

- `GEAoptimizer.core.PopulationSnapshot`

This snapshot contains copied arrays:

- `genes`: `populationSize × nGenes`
- `fitness`: `populationSize × 1`

Because it’s a value object with immutable properties, user code cannot mutate the optimizer’s internal population.

### Two monitoring styles

1) **Monitor object** (`GEAoptimizer.monitor.Monitor`)
   - Implement `onStart`, `onIteration`, `onFinish`.

2) **Function handle monitor** (wrapper)
   - Provide a function:
     - `fn(event, iter, popSnapshot, history, ctx, result)`
   - `event` is one of: `"start"`, `"iteration"`, `"finish"`.
   - Wrapped by `GEAoptimizer.monitor.FunctionMonitor`.

3) **Callbacks** (`options.callbacks`)
   - Field names:
     - `onStart`, `onBeforeStep`, `onAfterStep`, `onAfterEvaluation`, `onFinish`
   - Signature:
     - `stop = cb(iter, popSnapshot, history, ctx, result)`
   - If `stop` is `true`, the run stops with `exitReason = "userStop"`.

## Glossary (monitoring + callbacks)

- **Monitor**
  - A *passive observer* attached via `options.monitor`.
  - Receives iteration snapshots and history, but cannot stop the run.
  - Implemented as a `GEAoptimizer.monitor.Monitor` subclass, or a function handle wrapped by `GEAoptimizer.monitor.FunctionMonitor`.

- **Function monitor**
  - A single function handle used as `options.monitor`.
  - Wrapped automatically; called as:
    - `fn(event, iteration, populationSnapshot, history, ctx, result)`
  - `event` is `"start"`, `"iteration"`, or `"finish"`.

- **Callback**
  - An *active hook* attached via `options.callbacks` (a struct of function handles).
  - Runs at specific points in the loop and may request early stop.
  - Contract:
    - `stop = cb(iteration, populationSnapshot, history, ctx, result)`
    - return `true` to stop the run (`exitReason="userStop"`).

- **Population snapshot**
  - A read-only/value copy of the internal population state.
  - Type: `GEAoptimizer.core.PopulationSnapshot`
  - Fields:
    - `genes` (`populationSize × nGenes`)
    - `fitness` (`populationSize × 1`)

- **Iteration (history index)**
  - Iteration `0` is the *initial evaluated population* (after initialization + evaluation).
  - Iteration `k` (`k>=1`) is the evaluated population after completing `step()` and re-evaluation.

- **Step**
  - One algorithm iteration (`step(population, iter)`), where operators run (selection/crossover/mutation/replacement).
  - Implemented by the specific optimizer (GA/GEA). The scaffold does not define operator logic.

- **Hook timing**
  - `onBeforeStep`: just before `step()` is executed for an iteration.
  - `onAfterStep`: immediately after `step()` but before evaluation.
  - `onAfterEvaluation`: after evaluation + history update + monitor notification for that iteration.

