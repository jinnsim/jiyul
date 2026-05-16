import Foundation
import SwiftData

@Model
final class Settings {
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var languageOverride: String?
    var playerName: String

    init(soundEnabled: Bool = true,
         hapticsEnabled: Bool = true,
         languageOverride: String? = nil,
         playerName: String = "지율") {
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.languageOverride = languageOverride
        self.playerName = playerName
    }
}
