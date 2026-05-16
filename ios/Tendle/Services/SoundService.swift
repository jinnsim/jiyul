import Foundation

enum SoundEffect {
    case tap
    case clear
    case gameOver
}

final class SoundService {
    private var enabled: Bool

    init(enabled: Bool = true) {
        self.enabled = enabled
    }

    func setEnabled(_ value: Bool) { enabled = value }

    func play(_ effect: SoundEffect) {
        guard enabled else { return }
        // Phase 1: no-op. Phase 2 wires AVAudioPlayer pool with .caf clips.
    }
}
