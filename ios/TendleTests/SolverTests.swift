import XCTest
@testable import Tendle

final class SolverTests: XCTestCase {
    func testSolvesTrivialSingleRowBoard() {
        let board = Board(rows: ["1234"])  // 1+2+3+4 = 10
        let r = Solver.solve(board, profile: .mvpV1)
        XCTAssertEqual(r.score, 4)
        XCTAssertTrue(r.isFinal)
    }

    func testIsDeterministicAcrossReruns() {
        let board = BoardGenerator.generate(seed: 12345)
        let a = Solver.solve(board, profile: .mvpV1).score
        let b = Solver.solve(board, profile: .mvpV1).score
        XCTAssertEqual(a, b)
    }
}
