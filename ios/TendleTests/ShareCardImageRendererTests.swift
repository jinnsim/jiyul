import XCTest
@testable import Tendle

@MainActor
final class ShareCardImageRendererTests: XCTestCase {
    func testRenderProducesPNGFile() throws {
        let url = ShareCardImageRenderer.render(
            dateKST: "2026-05-17", playerScore: 87, botScore: 121)
        XCTAssertNotNil(url)
        if let url {
            let data = try Data(contentsOf: url)
            XCTAssertGreaterThan(data.count, 1000) // sanity
            XCTAssertTrue(data.prefix(8).starts(with: [0x89, 0x50, 0x4E, 0x47])) // PNG magic
            try? FileManager.default.removeItem(at: url)
        }
    }
}
