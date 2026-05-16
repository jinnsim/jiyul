import XCTest
@testable import Tendle

final class GameCoordinatorTests: XCTestCase {
    func testStartTransitionsToPlaying() {
        let g = makeCoordinator()
        g.start()
        XCTAssertEqual(g.session.phase, .playing)
    }

    func testTickReducesRemainingTime() {
        let g = makeCoordinator()
        g.start()
        g.tick(deltaMs: 1000)
        XCTAssertEqual(g.session.remainingMs, 119_000)
    }

    func testTimerReachingZeroEndsSession() {
        let g = makeCoordinator()
        g.start()
        g.tick(deltaMs: GameSession.totalDurationMs)
        XCTAssertEqual(g.session.phase, .ended)
        XCTAssertEqual(g.session.remainingMs, 0)
    }

    func testCommitOnValidRectangleScores() {
        let g = makeCoordinator(rows: ["19"])
        g.start()
        let cleared = g.commit(Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0))
        XCTAssertEqual(cleared, 2)
        XCTAssertEqual(g.session.playerScore, 2)
    }

    func testCommitWhenIdleDoesNothing() {
        let g = makeCoordinator(rows: ["19"])
        let cleared = g.commit(Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0))
        XCTAssertEqual(cleared, 0)
    }

    private func makeCoordinator(rows: [String] = ["19"]) -> GameCoordinator {
        let session = GameSession(
            board: Board(rows: rows),
            phase: .idle,
            playerScore: 0,
            remainingMs: GameSession.totalDurationMs,
            startedAt: Date(),
            dateKSTAtStart: "2026-05-17",
            solverProgress: nil
        )
        return GameCoordinator(session: session)
    }
}
