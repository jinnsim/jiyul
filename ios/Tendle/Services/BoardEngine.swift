import Foundation

struct ClearResult: Equatable {
    let board: Board
    let clearedCells: Int
}

struct ClearAction: Equatable {
    let selection: Selection
    let result: ClearResult
}

enum BoardEngine {
    static func isValid(_ selection: Selection, on board: Board) -> Bool {
        board.contains(column: selection.minColumn, row: selection.minRow)
            && board.contains(column: selection.maxColumn, row: selection.maxRow)
    }

    static func rectangleSum(_ selection: Selection, on board: Board) -> Int {
        guard isValid(selection, on: board) else { return 0 }
        var sum = 0
        for row in selection.minRow...selection.maxRow {
            for column in selection.minColumn...selection.maxColumn {
                sum += board.value(column: column, row: row)
            }
        }
        return sum
    }

    static func clear(_ selection: Selection, on board: Board) -> ClearResult? {
        guard rectangleSum(selection, on: board) == 10 else { return nil }
        var indices: [Int] = []
        for row in selection.minRow...selection.maxRow {
            for column in selection.minColumn...selection.maxColumn {
                let index = board.index(column: column, row: row)
                if !board.isCleared(index: index) {
                    indices.append(index)
                }
            }
        }
        guard !indices.isEmpty else { return nil }
        return ClearResult(board: board.clearing(indices), clearedCells: indices.count)
    }

    static func validClears(on board: Board) -> [Selection] {
        validClearActions(on: board).map(\.selection)
    }

    static func validClearActions(on board: Board) -> [ClearAction] {
        var actions: [ClearAction] = []
        for top in 0..<Board.rows {
            var columnSums = Array(repeating: 0, count: Board.columns)
            var columnIndices = Array(repeating: [Int](), count: Board.columns)
            for bottom in top..<Board.rows {
                for column in 0..<Board.columns {
                    let index = board.index(column: column, row: bottom)
                    if !board.isCleared(index: index) {
                        columnSums[column] += Int(board.digits[index])
                        columnIndices[column].append(index)
                    }
                }
                for left in 0..<Board.columns {
                    var sum = 0
                    var indices: [Int] = []
                    for right in left..<Board.columns {
                        sum += columnSums[right]
                        indices.append(contentsOf: columnIndices[right])
                        if sum == 10 {
                            let selection = Selection(minColumn: left, minRow: top, maxColumn: right, maxRow: bottom)
                            let result = ClearResult(board: board.clearing(indices), clearedCells: indices.count)
                            actions.append(ClearAction(selection: selection, result: result))
                        } else if sum > 10 {
                            break
                        }
                    }
                }
            }
        }
        return actions.sorted { $0.selection < $1.selection }
    }
}
