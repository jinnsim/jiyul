import Foundation
import SwiftData

final class SettingsStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Returns the single Settings row, creating defaults on first access.
    @discardableResult
    func current() throws -> Settings {
        if let existing = try modelContext.fetch(FetchDescriptor<Settings>()).first {
            return existing
        }
        let fresh = Settings()
        modelContext.insert(fresh)
        try modelContext.save()
        return fresh
    }

    func update(_ apply: (Settings) -> Void) throws {
        let settings = try current()
        apply(settings)
        try modelContext.save()
    }

    /// Deletes all DailyRecords + SolverCache rows. Settings preserved.
    func resetAllData() throws {
        try modelContext.delete(model: DailyRecord.self)
        try modelContext.delete(model: SolverCache.self)
        try modelContext.save()
    }
}
