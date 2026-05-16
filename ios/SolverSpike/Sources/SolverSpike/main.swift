import Foundation
import SolverSpikeCore

let seeds = (0..<100).map { UInt64($0) &* 0x9E3779B97F4A7C15 &+ 0xD1B54A32D192ED03 }
var firstRun: [SolverResult] = []
var elapsedTimes: [Double] = []

print("SolverSpike profile=\(SolverProfile.mvpV1.solverProfile) seeds=100")

for seed in seeds {
    let board = BoardGenerator.generate(seed: seed)
    let start = CFAbsoluteTimeGetCurrent()
    let result = Solver.solve(board, profile: .mvpV1)
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    firstRun.append(result)
    elapsedTimes.append(elapsed)
    print(String(format: "seed=%016llx score=%d expanded=%d time=%.3fs", seed, result.score, result.expandedStates, elapsed))
}

let rerunMatches = zip(seeds, firstRun).allSatisfy { seed, expected in
    let board = BoardGenerator.generate(seed: seed)
    return Solver.solve(board, profile: .mvpV1) == expected
}

let scores = firstRun.map(\.score)
let sortedTimes = elapsedTimes.sorted()
let p95Index = min(sortedTimes.count - 1, Int(Double(sortedTimes.count - 1) * 0.95))
let p95 = sortedTimes[p95Index]
let averageScore = Double(scores.reduce(0, +)) / Double(scores.count)

print(String(format: "summary minScore=%d maxScore=%d avgScore=%.2f p95=%.3fs determinism=%@",
             scores.min() ?? 0,
             scores.max() ?? 0,
             averageScore,
             p95,
             rerunMatches ? "pass" : "fail"))

// Spec §5.6 Gate 2 + Gate 3 — non-zero exit on failure.
let p95Ceiling = 30.0
var failed = false
if !rerunMatches {
    print("GATE 2 FAIL: determinism rerun produced different result.")
    failed = true
}
if p95 >= p95Ceiling {
    print(String(format: "GATE 3 FAIL: p95 %.3fs >= %.1fs ceiling.", p95, p95Ceiling))
    failed = true
}
if failed { exit(1) }
print("GATES OK: determinism pass, p95 < 30s.")

