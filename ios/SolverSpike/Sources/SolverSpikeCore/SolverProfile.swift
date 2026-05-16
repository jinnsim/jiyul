public struct SolverProfile: Equatable {
    public let solverProfile: String
    public let beamWidth: Int
    public let maxExpandedStates: Int
    public let maxVisitedStates: Int
    public let alpha: Double
    public let rngSeedForTies: UInt64
    public let solverVersion: Int
    public let scoringHash: String

    public init(
        solverProfile: String,
        beamWidth: Int,
        maxExpandedStates: Int,
        maxVisitedStates: Int,
        alpha: Double,
        rngSeedForTies: UInt64,
        solverVersion: Int,
        scoringHash: String
    ) {
        self.solverProfile = solverProfile
        self.beamWidth = beamWidth
        self.maxExpandedStates = maxExpandedStates
        self.maxVisitedStates = maxVisitedStates
        self.alpha = alpha
        self.rngSeedForTies = rngSeedForTies
        self.solverVersion = solverVersion
        self.scoringHash = scoringHash
    }

    public static let mvpV1 = SolverProfile(
        solverProfile: "mvp-v1",
        beamWidth: 64,
        maxExpandedStates: 200_000,
        maxVisitedStates: 800_000,
        alpha: 0.10,
        rngSeedForTies: 0,
        solverVersion: 1,
        scoringHash: "score+0.10*potential(pair+triple+quad,line-only,len<=4)"
    )

    public var cacheKey: String {
        "\(solverProfile)|v\(solverVersion)|w\(beamWidth)|n\(maxExpandedStates)|h\(scoringHash)"
    }
}

