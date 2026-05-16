# SolverSpike

Standalone Swift package for the Tendle solver spike.

## Build and Test

```sh
cd ios/SolverSpike
swift build
swift test
swift run SolverSpike
```

The CLI generates 100 deterministic random seeds, solves each board with
`solverProfile=mvp-v1`, prints score and wall-clock time, then reruns the same
inputs and checks bit-for-bit deterministic results.

## Gate Mapping

- Gate 1, correctness: `SolverTests` checks 10 hand-crafted boards with known
  optima and requires at least 90% of optimum.
- Gate 2, determinism: `BoardGeneratorTests` and `DeterminismTests` verify same
  seed/profile results are identical across reruns.
- Gate 3, performance: `swift run SolverSpike` reports per-board times and p95
  wall-clock for the 100-seed spike run.

