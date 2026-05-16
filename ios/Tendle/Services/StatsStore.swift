import Foundation
import SwiftData

final class StatsStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Returns the saved record on success, or nil if a record already
    /// exists for the same dateKST (first-record-wins per spec §3.3).
    @discardableResult
    func saveFirstAttempt(_ record: DailyRecord) throws -> DailyRecord? {
        if try recordExists(for: record.dateKST) { return nil }
        modelContext.insert(record)
        try modelContext.save()
        return record
    }

    func record(for dateKST: String) throws -> DailyRecord? {
        var descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.dateKST == dateKST })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func allRecords() throws -> [DailyRecord] {
        try modelContext.fetch(FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.dateKST, order: .reverse)]))
    }

    /// Upgrade a previously-saved record from `.pending` to `.final` with the
    /// freshly-computed bot score. No-op if the record is already `.final` or
    /// missing.
    func finalizePendingBot(date: String, botScore: Int) throws {
        guard let record = try record(for: date), record.botStatus == .pending else { return }
        record.botScore = botScore
        record.botStatus = .final
        record.botFinalizedAt = Date()
        try modelContext.save()
    }

    private func recordExists(for dateKST: String) throws -> Bool {
        try record(for: dateKST) != nil
    }
}
