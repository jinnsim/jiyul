import Foundation
import SwiftData

@Model
final class DailyRecord {
    @Attribute(.unique) var dateKST: String
    var seedInputHash: String
    var startedAtKST: Date
    var endedAtKST: Date
    var dateKSTAtStart: String
    var playerScore: Int
    var durationMs: Int
    var botStatusRaw: String
    var botScore: Int?
    var botFinalizedAt: Date?
    var solverProfile: String
    var outcome: String   // "completed" | "abandoned"

    init(dateKST: String,
         seedInputHash: String,
         startedAtKST: Date,
         endedAtKST: Date,
         dateKSTAtStart: String,
         playerScore: Int,
         durationMs: Int,
         botStatus: BotStatus,
         botScore: Int?,
         botFinalizedAt: Date?,
         solverProfile: String,
         outcome: String) {
        self.dateKST = dateKST
        self.seedInputHash = seedInputHash
        self.startedAtKST = startedAtKST
        self.endedAtKST = endedAtKST
        self.dateKSTAtStart = dateKSTAtStart
        self.playerScore = playerScore
        self.durationMs = durationMs
        self.botStatusRaw = botStatus.rawValue
        self.botScore = botScore
        self.botFinalizedAt = botFinalizedAt
        self.solverProfile = solverProfile
        self.outcome = outcome
    }

    var botStatus: BotStatus {
        get { BotStatus(rawValue: botStatusRaw) ?? .failed }
        set { botStatusRaw = newValue.rawValue }
    }
}
