import Foundation

struct SolverResult: Equatable {
    let score: Int
    let moves: [Selection]
    let expandedStates: Int
    let isFinal: Bool
}

enum Solver {
    private struct State {
        let board: Board
        let score: Int
        let moves: [Selection]
        let evaluation: Double
    }

    static func solve(_ board: Board, profile: SolverProfile = .mvpV1) -> SolverResult {
        let expandedLimit = profile.maxExpandedStates
        let visitedLimit = profile.maxVisitedStates
        let initial = State(board: board, score: 0, moves: [], evaluation: evaluate(board: board, score: 0, alpha: profile.alpha))
        var beam = [initial]
        var best = initial
        var visited = Set<[UInt64]>()
        visited.insert(board.clearedWords)
        var expandedStates = 0
        var visitedFull = false

        while !beam.isEmpty && expandedStates < expandedLimit {
            var successors: [State] = []

            for state in beam {
                if expandedStates >= expandedLimit { break }
                expandedStates += 1

                for action in BoardEngine.validClearActions(on: state.board) {
                    let clear = action.result
                    if !visitedFull {
                        guard visited.insert(clear.board.clearedWords).inserted else { continue }
                        if visited.count >= visitedLimit { visitedFull = true }
                    }
                    var moves = state.moves
                    moves.append(action.selection)
                    let score = state.score + clear.clearedCells
                    let successor = State(
                        board: clear.board,
                        score: score,
                        moves: moves,
                        evaluation: evaluate(board: clear.board, score: score, alpha: profile.alpha)
                    )
                    successors.append(successor)
                    if isBetterRealized(successor, than: best) {
                        best = successor
                    }
                }
            }

            successors.sort(by: isPreferred)
            if successors.count > profile.beamWidth {
                successors.removeLast(successors.count - profile.beamWidth)
            }
            beam = successors
        }

        return SolverResult(score: best.score, moves: best.moves, expandedStates: expandedStates, isFinal: true)
    }

    private static func evaluate(board: Board, score: Int, alpha: Double) -> Double {
        Double(score) + alpha * Double(potential(on: board))
    }

    private static func potential(on board: Board) -> Int {
        var count = 0
        for row in 0..<Board.rows {
            for column in 0..<Board.columns {
                count += linePotential(on: board, column: column, row: row, deltaColumn: 1, deltaRow: 0)
                count += linePotential(on: board, column: column, row: row, deltaColumn: 0, deltaRow: 1)
            }
        }
        return count
    }

    private static func linePotential(on board: Board, column: Int, row: Int, deltaColumn: Int, deltaRow: Int) -> Int {
        var total = 0
        var sum = 0
        for length in 1...4 {
            let nextColumn = column + (length - 1) * deltaColumn
            let nextRow = row + (length - 1) * deltaRow
            guard board.contains(column: nextColumn, row: nextRow) else { break }
            sum += board.value(column: nextColumn, row: nextRow)
            if length >= 2 && sum == 10 {
                total += 1
            }
            if sum > 10 {
                break
            }
        }
        return total
    }

    private static func isBetterRealized(_ lhs: State, than rhs: State) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        return lexicographicallyPrecedes(lhs.moves, rhs.moves)
    }

    private static func isPreferred(_ lhs: State, _ rhs: State) -> Bool {
        if lhs.evaluation != rhs.evaluation { return lhs.evaluation > rhs.evaluation }
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        return lexicographicallyPrecedes(lhs.moves, rhs.moves)
    }

    private static func lexicographicallyPrecedes(_ lhs: [Selection], _ rhs: [Selection]) -> Bool {
        for index in 0..<min(lhs.count, rhs.count) {
            if lhs[index] == rhs[index] { continue }
            return lhs[index] < rhs[index]
        }
        return lhs.count < rhs.count
    }
}

extension Solver {
    /// Background-priority detached task that emits progress updates and
    /// finalises with isFinal=true. Cancellation drops further emissions.
    static func solveAsync(
        _ board: Board,
        profile: SolverProfile = .mvpV1
    ) -> (AsyncStream<SolverProgress>, Task<Void, Never>) {
        let (stream, continuation) = AsyncStream.makeStream(of: SolverProgress.self)
        let task = Task.detached(priority: .background) {
            // For Phase 1 we run the synchronous solver in one shot and
            // emit a single final progress. Incremental "anytime" updates
            // are added in Phase 2 (see spec §5.1).
            let result = Solver.solve(board, profile: profile)
            if !Task.isCancelled {
                continuation.yield(SolverProgress(
                    bestScore: result.score,
                    expandedStates: result.expandedStates,
                    isFinal: true))
            }
            continuation.finish()
        }
        return (stream, task)
    }
}
