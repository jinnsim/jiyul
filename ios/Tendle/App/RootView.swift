import SwiftUI
import SwiftData

enum Route: Hashable {
    case game(dateKST: String)
    case result(GameSessionSnapshot)
    case stats
}

/// Hashable, Codable snapshot of the round's terminal state used in
/// NavigationPath. Captures everything Result needs without holding the
/// (non-Codable) Board or Coordinator. When the user returns to the round's
/// Result screen mid-finalization, RootView pairs this snapshot with the
/// still-live `liveCoordinator` so the bot score can keep updating.
struct GameSessionSnapshot: Hashable, Codable {
    let dateKST: String
    let playerScore: Int
    let botScore: Int?
    let botIsFinal: Bool
    let streakDays: Int
    let isStreakUp: Bool
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path = NavigationPath()
    @State private var liveCoordinator: GameCoordinator?
    @AppStorage("lastForegroundAt") private var lastForegroundAt: Double = 0
    @State private var reopenMoment: EncouragementMoment? = nil

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                today: KSTClock.dateString(),
                todayRecord: try? StatsStore(modelContext: modelContext)
                    .record(for: KSTClock.dateString()),
                onStart: startDaily,
                onStats: { path.append(Route.stats) },
                reopenMoment: reopenMoment
            )
            .onAppear {
                let now = Date().timeIntervalSince1970
                let gapHours = (now - lastForegroundAt) / 3600
                if gapHours >= 8 {
                    reopenMoment = EncouragementService().line(
                        trigger: .reopen, language: lang(),
                        playerName: "지율", dateKST: KSTClock.dateString(), streak: 0)
                }
                lastForegroundAt = now
                finalizePendingBots()
            }
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
                    ResultView(
                        snapshot: snapshot,
                        liveCoordinator: liveCoordinator,
                        encouragementMoment: momentFor(snapshot: snapshot),
                        streakUpMoment: snapshot.isStreakUp ? streakUpMoment(for: snapshot) : nil
                    ) {
                        path = NavigationPath()
                        liveCoordinator = nil
                    }
                case .stats:
                    let store = StatsStore(modelContext: modelContext)
                    let records = (try? store.allRecords()) ?? []
                    StatsView(summary: StatsAggregator.summarize(records: records))
                }
            }
        }
    }

    private func lang() -> String {
        Locale.current.language.languageCode?.identifier ?? "ko"
    }

    private func momentFor(snapshot s: GameSessionSnapshot) -> EncouragementMoment {
        let trigger: EncouragementTrigger = {
            guard let bot = s.botScore, s.botIsFinal else { return .roundEndLow }
            if s.playerScore > bot { return .roundEndBeatBot }
            if Double(s.playerScore) >= 0.8 * Double(bot) { return .roundEndClose }
            return .roundEndLow
        }()
        return EncouragementService().line(
            trigger: trigger,
            language: lang(),
            playerName: "지율",
            dateKST: s.dateKST,
            streak: s.streakDays)
    }

    private func streakUpMoment(for s: GameSessionSnapshot) -> EncouragementMoment {
        EncouragementService().line(
            trigger: .streakUp,
            language: lang(),
            playerName: "지율",
            dateKST: s.dateKST,
            streak: s.streakDays)
    }

    /// Walks any DailyRecord rows whose `botStatus == .pending` and runs the
    /// deterministic solver on their seed in the background. On success,
    /// upgrades the record to `.final` with the score. SwiftData access is
    /// pinned to the main actor; only scalar dates cross the actor boundary.
    private func finalizePendingBots() {
        let context = modelContext
        Task.detached(priority: .background) {
            let pendingDates: [String] = await MainActor.run {
                let store = StatsStore(modelContext: context)
                return ((try? store.allRecords()) ?? [])
                    .filter { $0.botStatus == .pending }
                    .map(\.dateKST)
            }
            for date in pendingDates {
                let seed = KSTClock.dailySeed(forDate: date)
                let board = BoardGenerator.generate(seed: seed)
                let result = Solver.solve(board, profile: .mvpV1)
                await MainActor.run {
                    let store = StatsStore(modelContext: context)
                    try? store.finalizePendingBot(date: date, botScore: result.score)
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
        let priorRecords = (try? store.allRecords()) ?? []
        let priorStreak = StatsAggregator.summarize(records: priorRecords).currentStreakDays
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
        let saved = (try? store.saveFirstAttempt(record)) != nil
        let postRecords = (try? store.allRecords()) ?? priorRecords
        let postStreak = StatsAggregator.summarize(records: postRecords).currentStreakDays
        let isStreakUp = saved && postStreak == priorStreak + 1
        path.append(Route.result(GameSessionSnapshot(
            dateKST: date,
            playerScore: session.playerScore,
            botScore: progress?.bestScore,
            botIsFinal: progress?.isFinal ?? false,
            streakDays: postStreak,
            isStreakUp: isStreakUp
        )))
    }
}
