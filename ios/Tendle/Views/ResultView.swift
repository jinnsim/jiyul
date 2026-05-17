import SwiftUI

struct ResultView: View {
    let snapshot: GameSessionSnapshot
    /// Optional live coordinator — when present, the bot score and finality
    /// stream from `coordinator.session.solverProgress` so a `.pending` result
    /// upgrades to `.final` in-place. When nil (e.g. revisiting an older
    /// result), the static `snapshot` values are used.
    var liveCoordinator: GameCoordinator? = nil
    var encouragementMoment: EncouragementMoment? = nil
    var streakUpMoment: EncouragementMoment? = nil
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            HStack(spacing: 40) {
                column(label: "지율", value: "\(snapshot.playerScore)", color: .accentColor)
                column(label: "봇", value: botText, color: .secondary)
            }
            if let moment = encouragementMoment {
                EncouragementMomentView(moment: moment)
            } else {
                Text(microcopy)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            if let streakUpMoment {
                streakBanner(streakUpMoment)
            }
            Spacer()
            HStack(spacing: 16) {
                ShareLink(item: ShareCardRenderer.render(
                    dateKST: snapshot.dateKST,
                    playerScore: snapshot.playerScore,
                    botScore: currentBotScore))
                {
                    Label("공유", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("홈으로", action: onHome)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }

    /// Live bot score if coordinator is producing it; otherwise snapshot fallback.
    private var currentBotScore: Int? {
        if let live = liveCoordinator?.session.solverProgress, live.isFinal {
            return live.bestScore
        }
        return snapshot.botIsFinal ? snapshot.botScore : nil
    }

    private var botText: String {
        if let live = liveCoordinator?.session.solverProgress {
            return live.isFinal ? "\(live.bestScore)" : "…"
        }
        if snapshot.botIsFinal, let score = snapshot.botScore { return "\(score)" }
        return "…"
    }

    private var microcopy: String {
        guard let score = currentBotScore else { return "봇이 아직 계산 중이에요." }
        switch snapshot.playerScore - score {
        case let d where d > 0: return "봇을 이겼어요!"
        case 0: return "봇과 동점!"
        default: return "다음엔 분명 이길 거예요."
        }
    }

    @ViewBuilder
    private func streakBanner(_ moment: EncouragementMoment) -> some View {
        VStack(spacing: 8) {
            Image("StreakMilestone")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 140)
                .accessibilityHidden(true)
            Text(moment.line)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func column(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }
}
