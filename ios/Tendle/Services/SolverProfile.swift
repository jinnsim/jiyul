import Foundation

struct SolverProfile: Equatable {
    let solverProfile: String
    let beamWidth: Int
    let maxExpandedStates: Int
    let maxVisitedStates: Int
    let alpha: Double
    let rngSeedForTies: UInt64
    let solverVersion: Int
    let scoringHash: String

    static let mvpV1 = SolverProfile(
        solverProfile: "mvp-v1",
        beamWidth: 64,
        maxExpandedStates: 200_000,
        maxVisitedStates: 800_000,
        alpha: 0.10,
        rngSeedForTies: 0,
        solverVersion: 1,
        scoringHash: "score+0.10*potential(pair+triple+quad,line-only,len<=4)"
    )

    var cacheKey: String {
        "\(solverProfile)|v\(solverVersion)|w\(beamWidth)|n\(maxExpandedStates)|h\(scoringHash)"
    }
}
