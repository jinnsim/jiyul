import SwiftUI

struct ResultView: View {
    let session: GameSession
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            HStack(spacing: 40) {
                column(label: "당신", value: "\(session.playerScore)", color: .accentColor)
                column(label: "봇", value: botText, color: .secondary)
            }
            Text(microcopy)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            HStack(spacing: 16) {
                ShareLink(item: ShareCardRenderer.render(
                    dateKST: session.dateKSTAtStart,
                    playerScore: session.playerScore,
                    botScore: session.solverProgress?.isFinal == true ? session.solverProgress?.bestScore : nil))
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

    private var botText: String {
        if let progress = session.solverProgress, progress.isFinal {
            return "\(progress.bestScore)"
        }
        return "…"
    }

    private var microcopy: String {
        guard let progress = session.solverProgress, progress.isFinal else {
            return "봇이 아직 계산 중이에요."
        }
        switch session.playerScore - progress.bestScore {
        case let d where d > 0: return "봇을 이겼어요!"
        case 0: return "봇과 동점!"
        default: return "다음엔 분명 이길 거예요."
        }
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
