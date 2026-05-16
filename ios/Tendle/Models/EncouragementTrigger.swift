import Foundation

enum EncouragementTrigger: String, CaseIterable, Codable {
    case roundStart
    case firstClear
    case combo
    case roundEndBeatBot
    case roundEndClose
    case roundEndLow
    case streakUp
    case reopen
}
