import XCTest
@testable import Tendle

final class BoardEngineTests: XCTestCase {
    func testRectangleSumOnPristineBoard() {
        let b = Board(rows: ["19"])
        let s = Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0)
        XCTAssertEqual(BoardEngine.rectangleSum(s, on: b), 10)
    }

    func testClearSucceedsWhenSumIsTen() {
        let b = Board(rows: ["19"])
        let s = Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0)
        let r = BoardEngine.clear(s, on: b)
        XCTAssertEqual(r?.clearedCells, 2)
        XCTAssertEqual(r?.board.isCleared(column: 0, row: 0), true)
    }

    func testClearFailsWhenSumIsNotTen() {
        let b = Board(rows: ["18"])
        let s = Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0)
        XCTAssertNil(BoardEngine.clear(s, on: b))
    }

    func testClearedCellsContributeZero() {
        let b = Board(rows: ["191"])
        let first = BoardEngine.clear(
            Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0), on: b)!.board
        XCTAssertEqual(
            BoardEngine.rectangleSum(
                Selection(minColumn: 0, minRow: 0, maxColumn: 2, maxRow: 0), on: first),
            1)
    }
}
