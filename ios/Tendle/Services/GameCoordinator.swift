import Foundation
import Observation

@Observable
final class GameCoordinator {
    var session: GameSession
    private var solverTask: Task<Void, Never>?

    init(session: GameSession) {
        self.session = session
    }

    func start() {
        guard session.phase == .idle else { return }
        session.phase = .playing
        let board = session.board
        let (stream, task) = Solver.solveAsync(board)
        solverTask = task
        Task { [weak self] in
            for await progress in stream {
                guard let self else { return }
                await MainActor.run {
                    self.session.solverProgress = progress
                }
            }
        }
    }

    /// Attempts to commit a selection. Returns the number of cells cleared.
    @discardableResult
    func commit(_ selection: Selection) -> Int {
        guard session.phase == .playing else { return 0 }
        guard let result = BoardEngine.clear(selection, on: session.board) else { return 0 }
        session.board = result.board
        session.playerScore += result.clearedCells
        if result.clearedCells > 0 {
            SoundService.shared.play(.clear)
        }
        return result.clearedCells
    }

    func tick(deltaMs: Int) {
        guard session.phase == .playing else { return }
        let next = max(0, session.remainingMs - deltaMs)
        session.remainingMs = next
        if next == 0 {
            end()
        }
    }

    func end() {
        session.phase = .ended
        // Let solver finish on its own — its result may not be ready yet;
        // ResultView shows .pending until the AsyncStream completes.
    }

    deinit {
        solverTask?.cancel()
    }
}
