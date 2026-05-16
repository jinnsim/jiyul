import Foundation
import Observation

@Observable
final class GameCoordinator {
    var session: GameSession

    init(session: GameSession) {
        self.session = session
    }

    func start() {
        guard session.phase == .idle else { return }
        session.phase = .playing
    }

    /// Attempts to commit a selection. Returns the number of cells cleared.
    @discardableResult
    func commit(_ selection: Selection) -> Int {
        guard session.phase == .playing else { return 0 }
        guard let result = BoardEngine.clear(selection, on: session.board) else { return 0 }
        session.board = result.board
        session.playerScore += result.clearedCells
        return result.clearedCells
    }

    func end() {
        session.phase = .ended
    }
}
