import XCTest
import SwiftData
@testable import Tendle

final class SettingsStoreTests: XCTestCase {
    func makeStore() throws -> (SettingsStore, ModelContext) {
        let schema = Schema([DailyRecord.self, SolverCache.self, Settings.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [cfg])
        let ctx = ModelContext(container)
        return (SettingsStore(modelContext: ctx), ctx)
    }

    func testCurrentCreatesDefaultOnFirstCall() throws {
        let (store, _) = try makeStore()
        let s = try store.current()
        XCTAssertTrue(s.soundEnabled)
        XCTAssertEqual(s.playerName, "지율")
    }

    func testUpdateMutatesSingleRow() throws {
        let (store, _) = try makeStore()
        try store.update { $0.soundEnabled = false }
        let s = try store.current()
        XCTAssertFalse(s.soundEnabled)
    }

    func testResetAllDataDropsRecordsKeepsSettings() throws {
        let (store, ctx) = try makeStore()
        ctx.insert(DailyRecord(
            dateKST: "2026-05-17", seedInputHash: "x",
            startedAtKST: Date(), endedAtKST: Date(), dateKSTAtStart: "2026-05-17",
            playerScore: 10, durationMs: 1000,
            botStatus: .final, botScore: 20, botFinalizedAt: Date(),
            solverProfile: "mvp-v1", outcome: "completed"))
        try ctx.save()
        try store.update { $0.playerName = "Test" }
        try store.resetAllData()
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<DailyRecord>()).count, 0)
        XCTAssertEqual(try store.current().playerName, "Test")
    }
}
