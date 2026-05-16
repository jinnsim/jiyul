import SwiftUI

struct HomeView: View {
    let today: String
    let todayRecord: DailyRecord?
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("Tendle")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
            Text(today)
                .font(.headline).foregroundStyle(.secondary)
            Spacer()
            if let record = todayRecord {
                playedCard(record)
            } else {
                Button(action: onStart) {
                    Text("오늘의 보드 시작")
                        .font(.title3.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func playedCard(_ record: DailyRecord) -> some View {
        VStack(spacing: 10) {
            Text("이미 기록됨").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 30) {
                metric("당신", value: "\(record.playerScore)", color: .accentColor)
                metric("봇", value: record.botScore.map(String.init) ?? "…", color: .secondary)
            }
            Button("다시 도전", action: onStart)
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
