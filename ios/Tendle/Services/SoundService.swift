import Foundation
import AVFoundation

enum SoundEffect: String {
    case tap
    case clear
    case gameOver = "gameover"
}

final class SoundService {
    static let shared = SoundService()

    private var enabled: Bool
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    init(enabled: Bool = true) {
        self.enabled = enabled
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        preload(.tap)
        preload(.clear)
        preload(.gameOver)
    }

    func setEnabled(_ value: Bool) { enabled = value }

    func play(_ effect: SoundEffect) {
        guard enabled, let player = players[effect] else { return }
        if player.isPlaying { player.currentTime = 0 }
        player.play()
    }

    private func preload(_ effect: SoundEffect) {
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf") else {
            return
        }
        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.prepareToPlay()
            players[effect] = player
        }
    }
}
