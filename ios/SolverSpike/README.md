# SolverSpike

Standalone Swift package for the Tendle solver spike (spec §5.6).

## Build and Test

```sh
cd ios/SolverSpike
swift build -c release
swift test
swift run -c release SolverSpike
```

The CLI generates 100 deterministic random seeds, solves each board with
`solverProfile=mvp-v1`, prints score and wall-clock time, reruns the same
inputs to verify bit-for-bit deterministic results, and **exits non-zero**
if either Gate 2 (determinism) or Gate 3 (p95 < 30 s) fails.

## Gate Mapping

- **Gate 1 — correctness**: `SolverTests` validates beam-search recovers
  ≥ 90% of optimum on hand-crafted boards. NOTE: MVP fixtures are sparse
  1-row boards; expanding to 4×4/5×5/6×6 dense boards with brute-force
  optima is tracked for main-app implementation.
- **Gate 2 — determinism**: `BoardGeneratorTests`, `DeterminismTests`, and
  the CLI rerun all verify identical results for identical inputs. The
  CLI fails loudly (`exit 1`) on any mismatch.
- **Gate 3 — performance**: the CLI computes p95 wall-clock across 100
  release-build runs and exits non-zero if p95 ≥ 30 s.

## Cross-platform manifest

For each platform we want to certify (mac, iphone-12-sim, iphone-15-sim),
capture the CLI summary line and store under `docs/spike-manifests/`:

```text
docs/spike-manifests/mvp-v1-mac.txt
docs/spike-manifests/mvp-v1-iphone-12-sim.txt
docs/spike-manifests/mvp-v1-iphone-15-sim.txt
```

The score column must be **bit-for-bit identical** across all manifests
(same `solverProfile`, same `boardSeeds`). Only the per-board wall-clock
time may differ.

