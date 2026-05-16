import XCTest
import SwiftData
@testable import Tendle

final class StatsStoreTests: XCTestCase {
    func makeStore() throws -> StatsStore {
        let schema = Schema([DailyRecord.self, SolverCache.self, Settings.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [cfg])
        return StatsStore(modelContext: ModelContext(container))
    }

    func testFirstSaveCreatesRecord() throws {
        let s = try makeStore()
        let r = makeSampleRecord(date: "2026-05-17")
        let stored = try s.saveFirstAttempt(r)
        XCTAssertNotNil(stored)
        XCTAssertEqual(try s.record(for: "2026-05-17")?.playerScore, 87)
    }

    func testSecondSaveOnSameDateIsRejected() throws {
        let s = try makeStore()
        _ = try s.saveFirstAttempt(makeSampleRecord(date: "2026-05-17", score: 87))
        let again = try s.saveFirstAttempt(makeSampleRecord(date: "2026-05-17", score: 99))
        XCTAssertNil(again)  // already recorded
        XCTAssertEqual(try s.record(for: "2026-05-17")?.playerScore, 87)
    }

    func testDifferentDatesCoexist() throws {
        let s = try makeStore()
        _ = try s.saveFirstAttempt(makeSampleRecord(date: "2026-05-17", score: 87))
        _ = try s.saveFirstAttempt(makeSampleRecord(date: "2026-05-18", score: 99))
        XCTAssertEqual(try s.allRecords().count, 2)
    }

    private func makeSampleRecord(date: String, score: Int = 87) -> DailyRecord {
        DailyRecord(
            dateKST: date,
            seedInputHash: "abc",
            startedAtKST: Date(),
            endedAtKST: Date(),
            dateKSTAtStart: date,
            playerScore: score,
            durationMs: 120_000,
            botStatus: .final,
            botScore: 121,
            botFinalizedAt: Date(),
            solverProfile: "mvp-v1",
            outcome: "completed"
        )
    }
}
