import Foundation

enum GamePhase: Equatable {
    case idle
    case playing
    case ended
}

struct GameSession: Equatable {
    var board: Board
    var phase: GamePhase
    var playerScore: Int
    var remainingMs: Int
    var startedAt: Date
    var dateKSTAtStart: String
    var solverProgress: SolverProgress?

    static let totalDurationMs = 120_000

    static func newDaily(dateKST: String, now: Date) -> GameSession {
        let seed = KSTClock.dailySeed(forDate: dateKST)
        let board = BoardGenerator.generate(seed: seed)
        return GameSession(
            board: board,
            phase: .idle,
            playerScore: 0,
            remainingMs: Self.totalDurationMs,
            startedAt: now,
            dateKSTAtStart: dateKST,
            solverProgress: nil
        )
    }
}
