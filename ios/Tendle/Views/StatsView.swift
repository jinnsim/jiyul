import SwiftUI

struct StatsView: View {
    let summary: StatsSummary

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Stats.Title").font(.largeTitle.bold())
                HStack(spacing: 24) {
                    metric(String(localized: "Stats.Plays"), "\(summary.totalPlays)")
                    metric(String(localized: "Stats.Streak"), "\(summary.currentStreakDays)")
                    metric(String(localized: "Stats.Best"), "\(summary.bestScore)")
                    metric(String(localized: "Stats.BotWinRate"), "\(summary.botWinPercent)%")
                }
                Text("Stats.Last30").font(.headline)
                sparkline
                Spacer()
            }
            .padding()
        }
        .navigationTitle(String(localized: "Stats.Title"))
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
