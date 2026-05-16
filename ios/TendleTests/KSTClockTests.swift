import XCTest
@testable import Tendle

final class KSTClockTests: XCTestCase {
    func testTodayStringRendersKSTDate() {
        // 2026-05-17 14:00 UTC == 2026-05-17 23:00 KST → "2026-05-17"
        let d = Date(timeIntervalSince1970: 1779022800)
        XCTAssertEqual(KSTClock.dateString(for: d), "2026-05-17")
    }

    func testJustAfterUTCMidnightStillSameKSTDay() {
        // 2026-05-17 00:30 UTC == 2026-05-17 09:30 KST → "2026-05-17"
        let d = Date(timeIntervalSince1970: 1778974200)
        XCTAssertEqual(KSTClock.dateString(for: d), "2026-05-17")
    }

    func testSeedHashForDailyIsStable() {
        XCTAssertEqual(KSTClock.dailySeed(forDate: "2026-05-17"),
                       KSTClock.dailySeed(forDate: "2026-05-17"))
        XCTAssertNotEqual(KSTClock.dailySeed(forDate: "2026-05-17"),
                          KSTClock.dailySeed(forDate: "2026-05-18"))
    }
}
