import XCTest
@testable import SolverSpikeCore

final class SolverTests: XCTestCase {
    func testHandCraftedKnownOptimaReachAtLeastNinetyPercent() {
        let cases: [(Board, Int)] = [
            (Board(rows: ["19"]), 2),
            (Board(rows: ["1919"]), 4),
            (Board(rows: ["191919"]), 6),
            (Board(rows: ["1234"]), 4),
            (Board(rows: ["123419"]), 6),
            (Board(rows: ["1111111111"]), 10),
            (Board(rows: ["55", "55"]), 4),
            (Board(rows: ["22222"]), 5),
            (Board(rows: ["37", "37", "37"]), 6),
            (Board(rows: ["46", "19", "28", "37"]), 8)
        ]

        for (board, optimum) in cases {
            let result = Solver.solve(board, profile: .mvpV1)
            XCTAssertGreaterThanOrEqual(Double(result.score), Double(optimum) * 0.9)
        }
    }
}

