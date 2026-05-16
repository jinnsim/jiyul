import XCTest
@testable import Tendle

final class StatsAggregatorTests: XCTestCase {
    func testEmptyRecords() {
        let s = StatsAggregator.summarize(records: [], today: "2026-05-17")
        XCTAssertEqual(s.totalPlays, 0)
        XCTAssertEqual(s.bestScore, 0)
        XCTAssertEqual(s.currentStreakDays, 0)
        XCTAssertEqual(s.botWinPercent, 0)
        XCTAssertEqual(s.last30.count, 30)
    }

    func testStreakCountsConsecutiveDays() {
        let recs = [
            sample(date: "2026-05-17", playerScore: 50, botScore: 40),
            sample(date: "2026-05-16", playerScore: 60, botScore: 70),
            sample(date: "2026-05-14", playerScore: 40, botScore: 40),  // gap
        ]
        let s = StatsAggregator.summarize(records: recs, today: "2026-05-17")
        XCTAssertEqual(s.currentStreakDays, 2)
    }

    func testBotWinPercent() {
        let recs = [
            sample(date: "2026-05-17", playerScore: 100, botScore: 80),
            sample(date: "2026-05-16", playerScore: 50, botScore: 80),
        ]
        let s = StatsAggregator.summarize(records: recs, today: "2026-05-17")
        XCTAssertEqual(s.botWinPercent, 50)
    }

    private func sample(date: String, playerScore: Int, botScore: Int) -> DailyRecord {
        DailyRecord(
            dateKST: date, seedInputHash: "x",
            startedAtKST: Date(), endedAtKST: Date(), dateKSTAtStart: date,
            playerScore: playerScore, durationMs: 120_000,
            botStatus: .final, botScore: botScore, botFinalizedAt: Date(),
            solverProfile: "mvp-v1", outcome: "completed")
    }
}
