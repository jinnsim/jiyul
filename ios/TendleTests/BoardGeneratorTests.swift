import XCTest
@testable import Tendle

final class BoardGeneratorTests: XCTestCase {
    func testSameSeedProducesSameBoard() {
        let a = BoardGenerator.generate(seed: 0xDEADBEEFCAFEBABE)
        let b = BoardGenerator.generate(seed: 0xDEADBEEFCAFEBABE)
        XCTAssertEqual(a.digits, b.digits)
    }

    func testAllDigitsInOneToNine() {
        let board = BoardGenerator.generate(seed: 42)
        XCTAssertTrue(board.digits.allSatisfy { (1...9).contains($0) })
        XCTAssertEqual(board.digits.count, Board.cellCount)
    }
}
