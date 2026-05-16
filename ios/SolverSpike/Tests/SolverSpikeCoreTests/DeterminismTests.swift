import XCTest
@testable import SolverSpikeCore

final class DeterminismTests: XCTestCase {
    func testSameSeedAndProfileRerunResultsAreIdentical() {
        for index in 0..<100 {
            let board = deterministicFixture(seed: UInt64(index))
            let expected = Solver.solve(board, profile: .mvpV1)
            let actual = Solver.solve(board, profile: .mvpV1)
            XCTAssertEqual(actual, expected, "Seed \(index) changed result.")
        }
    }

    private func deterministicFixture(seed: UInt64) -> Board {
        let pairs = ["19", "28", "37", "46", "55"]
        return Board(rows: [pairs[Int(seed % UInt64(pairs.count))]])
    }
}
