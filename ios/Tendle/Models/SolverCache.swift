import Foundation
import SwiftData

@Model
final class SolverCache {
    @Attribute(.unique) var cacheKey: String
    var botScore: Int
    var solverProfile: String
    var solverVersion: Int
    var computedAt: Date

    init(cacheKey: String, botScore: Int, solverProfile: String,
         solverVersion: Int, computedAt: Date) {
        self.cacheKey = cacheKey
        self.botScore = botScore
        self.solverProfile = solverProfile
        self.solverVersion = solverVersion
        self.computedAt = computedAt
    }
}
