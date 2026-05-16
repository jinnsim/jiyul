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

    @State private var didSplash = false

    var body: some Scene {
        WindowGroup {
            Group {
                if didSplash {
                    RootView().modelContainer(container)
                } else {
                    SplashView { didSplash = true }
                }
            }
        }
    }
}
