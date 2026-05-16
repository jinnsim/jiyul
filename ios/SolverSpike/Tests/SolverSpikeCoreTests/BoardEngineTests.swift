import XCTest
@testable import SolverSpikeCore

final class BoardEngineTests: XCTestCase {
    func testSelectionValidity() {
        let board = Board(rows: ["19"])
        XCTAssertTrue(BoardEngine.isValid(Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0), on: board))
        XCTAssertFalse(BoardEngine.isValid(Selection(minColumn: -1, minRow: 0, maxColumn: 1, maxRow: 0), on: board))
    }

    func testRectangleSumAndClear() {
        let board = Board(rows: ["19"])
        let selection = Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0)
        XCTAssertEqual(BoardEngine.rectangleSum(selection, on: board), 10)
        let result = BoardEngine.clear(selection, on: board)
        XCTAssertEqual(result?.clearedCells, 2)
        XCTAssertEqual(result?.board.isCleared(column: 0, row: 0), true)
        XCTAssertEqual(result?.board.isCleared(column: 1, row: 0), true)
    }

    func testClearedCellsContributeZero() {
        let board = Board(rows: ["191"])
        let first = BoardEngine.clear(Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0), on: board)!.board
        XCTAssertEqual(BoardEngine.rectangleSum(Selection(minColumn: 0, minRow: 0, maxColumn: 2, maxRow: 0), on: first), 1)
    }

    func testInvalidSumDoesNotClear() {
        let board = Board(rows: ["18"])
        XCTAssertNil(BoardEngine.clear(Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0), on: board))
    }
}
