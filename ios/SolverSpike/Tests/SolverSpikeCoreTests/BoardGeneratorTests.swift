import XCTest
@testable import SolverSpikeCore

final class BoardGeneratorTests: XCTestCase {
    func testSameSeedProducesSameBoard() {
        let first = BoardGenerator.generate(seed: 0x1234_5678_9ABC_DEF0)
        let second = BoardGenerator.generate(seed: 0x1234_5678_9ABC_DEF0)
        XCTAssertEqual(first, second)
    }

    func testDigitsAreInRange() {
        let board = BoardGenerator.generate(seed: 42)
        XCTAssertTrue(board.digits.allSatisfy { (1...9).contains($0) })
    }
}

