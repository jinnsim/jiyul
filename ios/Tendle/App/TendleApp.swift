import SwiftUI
import SwiftData

@main
struct TendleApp: App {
    let container: ModelContainer = {
        do {
            return try ModelContainer(for:
                DailyRecord.self, SolverCache.self, Settings.self)
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
