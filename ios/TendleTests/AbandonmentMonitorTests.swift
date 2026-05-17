import XCTest
@testable import Tendle

final class AbandonmentMonitorTests: XCTestCase {
    func testGapBelowThresholdNotAbandoned() {
        let now = Date()
        XCTAssertFalse(AbandonmentMonitor.shouldMarkAbandoned(
            leftForegroundAt: now,
            returnedAt: now.addingTimeInterval(60)))
    }

    func testGapAtThresholdIsAbandoned() {
        let now = Date()
        XCTAssertTrue(AbandonmentMonitor.shouldMarkAbandoned(
            leftForegroundAt: now,
            returnedAt: now.addingTimeInterval(300)))
    }

    func testCustomThresholdHonoured() {
        let now = Date()
        XCTAssertTrue(AbandonmentMonitor.shouldMarkAbandoned(
            leftForegroundAt: now,
            returnedAt: now.addingTimeInterval(120),
            thresholdSeconds: 60))
    }
}
