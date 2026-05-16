import Foundation

struct StatsSummary: Equatable {
    let totalPlays: Int
    let bestScore: Int
    let averageScore: Double
    let currentStreakDays: Int
    let botWinPercent: Int   // 0..100
    let last30: [Int]        // most-recent-first scores (0 for missing days)
}

enum StatsAggregator {
    static func summarize(records: [DailyRecord], today: String = KSTClock.dateString()) -> StatsSummary {
        let plays = records.count
        let best = records.map(\.playerScore).max() ?? 0
        let avg = plays > 0 ? Double(records.map(\.playerScore).reduce(0, +)) / Double(plays) : 0
        let withFinalBot = records.filter { $0.botStatus == .final && $0.botScore != nil }
        let wins = withFinalBot.filter { $0.playerScore > ($0.botScore ?? 0) }.count
        let pct = withFinalBot.isEmpty ? 0 : Int((Double(wins) / Double(withFinalBot.count) * 100).rounded())
        let streak = streakDays(records: records, today: today)
        let last30 = recentDays(records: records, days: 30, today: today)
        return StatsSummary(totalPlays: plays, bestScore: best, averageScore: avg,
                            currentStreakDays: streak, botWinPercent: pct, last30: last30)
    }

    private static func streakDays(records: [DailyRecord], today: String) -> Int {
        let set = Set(records.map(\.dateKST))
        var count = 0
        var cursor = today
        while set.contains(cursor) {
            count += 1
            cursor = addingDays(-1, to: cursor)
        }
        return count
    }

    private static func recentDays(records: [DailyRecord], days: Int, today: String) -> [Int] {
        let by = Dictionary(uniqueKeysWithValues: records.map { ($0.dateKST, $0.playerScore) })
        var out: [Int] = []
        var cursor = today
        for _ in 0..<days {
            out.append(by[cursor] ?? 0)
            cursor = addingDays(-1, to: cursor)
        }
        return out
    }

    static func addingDays(_ delta: Int, to dateString: String) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")!
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dateString) else { return dateString }
        let adjusted = Calendar(identifier: .gregorian).date(byAdding: .day, value: delta, to: date)!
        return f.string(from: adjusted)
    }
}
