import XCTest
@testable import Tendle

final class ShareCardRendererTests: XCTestCase {
    func testRenderIncludesDateAndScores() {
        let text = ShareCardRenderer.render(
            dateKST: "2026-05-17", playerScore: 87, botScore: 121)
        XCTAssertTrue(text.contains("2026-05-17"))
        XCTAssertTrue(text.contains("87"))
        XCTAssertTrue(text.contains("121"))
    }

    func testBarLengthsAreNonNegative() {
        let text = ShareCardRenderer.render(
            dateKST: "2026-05-17", playerScore: 0, botScore: 100)
        XCTAssertTrue(text.contains("░"))   // empty bar present
    }

    func testRatioAbove100IsClampedTo100Percent() {
        let text = ShareCardRenderer.render(
            dateKST: "2026-05-17", playerScore: 150, botScore: 100)
        XCTAssertTrue(text.contains("100%"))
    }
}
