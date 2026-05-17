import SwiftUI

struct HomeView: View {
    let today: String
    let todayRecord: DailyRecord?
    let onStart: () -> Void
    let onStats: () -> Void
    let onSettings: () -> Void
    var reopenMoment: EncouragementMoment? = nil

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("App.Title")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
            Text(today)
                .font(.headline).foregroundStyle(.secondary)
            Spacer()
            if let record = todayRecord {
                playedCard(record)
            } else {
                if let reopen = reopenMoment {
                    EncouragementMomentView(moment: reopen)
                } else {
                    Image("HomeEmpty")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                }
                Button(action: onStart) {
                    Text("Home.StartCTA")
                        .font(.title3.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            Button(String(localized: "Home.StatsCTA"), action: onStats)
                .buttonStyle(.bordered)
                .controlSize(.regular)
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onSettings()
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }

    @ViewBuilder
    private func playedCard(_ record: DailyRecord) -> some View {
        VStack(spacing: 10) {
            Text("Home.AlreadyRecorded").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 30) {
                metric(String(localized: "Common.Player"), value: "\(record.playerScore)", color: .accentColor)
                metric(String(localized: "Common.Bot"), value: record.botScore.map(String.init) ?? "…", color: .secondary)
            }
            Button(String(localized: "Home.RetryCTA"), action: onStart)
                .buttonStyle(.bordered)
                .controlSize(.regular)
        }
        .padding(20)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func metric(_ label: String, value: String, color: Color) -> some View {
        VStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}
