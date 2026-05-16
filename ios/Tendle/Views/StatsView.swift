import SwiftUI

struct StatsView: View {
    let summary: StatsSummary

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("통계").font(.largeTitle.bold())
                HStack(spacing: 24) {
                    metric("플레이", "\(summary.totalPlays)")
                    metric("연속", "\(summary.currentStreakDays)")
                    metric("최고", "\(summary.bestScore)")
                    metric("봇 승률", "\(summary.botWinPercent)%")
                }
                Text("최근 30일").font(.headline)
                sparkline
                Spacer()
            }
            .padding()
        }
        .navigationTitle("통계")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var sparkline: some View {
        let maxVal = max(1, summary.last30.max() ?? 1)
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(summary.last30.enumerated().reversed()), id: \.offset) { _, score in
                Rectangle()
                    .fill(score == 0 ? Color(.systemGray5) : Color.accentColor)
                    .frame(width: 8, height: CGFloat(score) / CGFloat(maxVal) * 80 + 4)
            }
        }
        .frame(height: 90)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 24, weight: .bold, design: .rounded))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
