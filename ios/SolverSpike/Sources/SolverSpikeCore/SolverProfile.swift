public struct SolverProfile: Equatable {
    public let solverProfile: String
    public let beamWidth: Int
    public let maxExpandedStates: Int
    public let alpha: Double
    public let rngSeedForTies: UInt64
    public let solverVersion: Int

    public static let mvpV1 = SolverProfile(
        solverProfile: "mvp-v1",
        beamWidth: 64,
        maxExpandedStates: 200_000,
        alpha: 0.10,
        rngSeedForTies: 0,
        solverVersion: 1
    )
}

