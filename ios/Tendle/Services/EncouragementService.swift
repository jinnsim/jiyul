import Foundation
import CryptoKit

final class EncouragementService {
    private struct Catalog: Codable {
        let version: Int
        let triggers: [String: [String: [String]]]
    }

    private let catalog: Catalog

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "Encouragement", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Catalog.self, from: data) else {
            // Should never happen — JSON is bundled. Fail loud in debug.
            assertionFailure("Encouragement.json not found in bundle")
            self.catalog = Catalog(version: 0, triggers: [:])
            return
        }
        self.catalog = decoded
    }

    /// Returns the line for a trigger using deterministic per-(player, date, trigger) selection.
    func line(trigger: EncouragementTrigger,
              language: String,
              playerName: String,
              dateKST: String,
              streak: Int) -> EncouragementMoment {
        let key = trigger.rawValue
        let lang = language.hasPrefix("ko") ? "ko" : "en"
        guard let lines = catalog.triggers[key]?[lang], !lines.isEmpty else {
            return EncouragementMoment(trigger: trigger, line: "", illustrationAssetName: nil)
        }
        let seedString = "\(playerName)|\(dateKST)|\(key)"
        let seed = stableHash(seedString)
        var index = Int(seed % UInt64(lines.count))
        var picked = lines[index]
        // {streak} substitution with fallback
        if picked.contains("{streak}") {
            if streak > 0 {
                picked = picked.replacingOccurrences(of: "{streak}", with: "\(streak)")
            } else {
                // Pick the next deterministic index that has no placeholder
                var found = false
                for offset in 1...lines.count {
                    let candidate = lines[(index + offset) % lines.count]
                    if !candidate.contains("{streak}") {
                        picked = candidate
                        found = true
                        break
                    }
                }
                // All lines contain {streak} — substitute 0 to clear the placeholder
                if !found {
                    picked = picked.replacingOccurrences(of: "{streak}", with: "0")
                }
            }
        }
        return EncouragementMoment(
            trigger: trigger,
            line: picked,
            illustrationAssetName: illustration(for: trigger)
        )
    }

    private func illustration(for trigger: EncouragementTrigger) -> String? {
        switch trigger {
        case .roundStart: return "LoadingScene"
        case .firstClear, .combo: return nil
        case .roundEndBeatBot: return "ResultWin"
        case .roundEndClose: return "ResultClose"
        case .roundEndLow: return "ResultLow"
        case .streakUp: return "StreakMilestone"
        case .reopen: return "WelcomeBack"
        }
    }

    private func stableHash(_ s: String) -> UInt64 {
        let digest = SHA256.hash(data: Data(s.utf8))
        var seed: UInt64 = 0
        for (i, byte) in digest.prefix(8).enumerated() {
            seed |= UInt64(byte) << (UInt64(i) * 8)
        }
        return seed
    }
}
