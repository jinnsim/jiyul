import SwiftUI
import SwiftData

enum Route: Hashable {
    case game(dateKST: String)
    case result(GameSessionSnapshot)
}

/// Hashable, Codable snapshot of session state at end-of-round used in
/// NavigationStack path. We can't put the whole GameSession (with Board)
/// in NavigationPath if Board ever loses Hashable; this keeps things tight.
struct GameSessionSnapshot: Hashable, Codable {
    let dateKST: String
    let playerScore: Int
    let botScore: Int?
    let botIsFinal: Bool
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path = NavigationPath()
    @State private var liveCoordinator: GameCoordinator?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                today: KSTClock.dateString(),
                todayRecord: try? StatsStore(modelContext: modelContext)
                    .record(for: KSTClock.dateString()),
                onStart: startDaily
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .game:
                    if let liveCoordinator {
                        GameView(coordinator: liveCoordinator) { session in
                            handleFinish(session)
                        }
                    } else {
                        Text("준비 중…")
                    }
                case .result(let snapshot):
                    ResultView(session: GameSession(
                        board: Board(digits: Array(repeating: 1, count: Board.cellCount)),
                        phase: .ended,
                        playerScore: snapshot.playerScore,
                        remainingMs: 0,
                        startedAt: .now,
                        dateKSTAtStart: snapshot.dateKST,
                        solverProgress: snapshot.botScore.map {
                            SolverProgress(bestScore: $0, expandedStates: 0,
                                           isFinal: snapshot.botIsFinal)
                        }
                    )) {
                        path = NavigationPath()
                        liveCoordinator = nil
                    }
                }
            }
        }
    }

    private func startDaily() {
        let date = KSTClock.dateString()
        let session = GameSession.newDaily(dateKST: date, now: .now)
        liveCoordinator = GameCoordinator(session: session)
        path.append(Route.game(dateKST: date))
    }

    private func handleFinish(_ session: GameSession) {
        let store = StatsStore(modelContext: modelContext)
        let date = session.dateKSTAtStart
        let progress = session.solverProgress
        let record = DailyRecord(
            dateKST: date,
            seedInputHash: String(KSTClock.dailySeed(forDate: date), radix: 16),
            startedAtKST: session.startedAt,
            endedAtKST: .now,
            dateKSTAtStart: date,
            playerScore: session.playerScore,
            durationMs: GameSession.totalDurationMs - session.remainingMs,
            botStatus: (progress?.isFinal ?? false) ? .final : .pending,
            botScore: progress?.bestScore,
            botFinalizedAt: (progress?.isFinal ?? false) ? .now : nil,
            solverProfile: SolverProfile.mvpV1.solverProfile,
            outcome: "completed"
        )
        _ = try? store.saveFirstAttempt(record)
        path.append(Route.result(GameSessionSnapshot(
            dateKST: date,
            playerScore: session.playerScore,
            botScore: progress?.bestScore,
            botIsFinal: progress?.isFinal ?? false
        )))
    }
}
