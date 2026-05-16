import Foundation

enum ShareCardRenderer {
    static func render(dateKST: String, playerScore: Int, botScore: Int?) -> String {
        let bot = botScore ?? 0
        let ratio: Double = bot == 0 ? 0 : min(1.0, Double(playerScore) / Double(bot))
        let pct = Int((ratio * 100).rounded())
        let barWidth = 20
        let filled = Int((ratio * Double(barWidth)).rounded())
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: barWidth - filled)
        let botText = botScore.map(String.init) ?? "…"
        return """
        Tendle \(dateKST)
        🟩 \(playerScore) · 🤖 \(botText) (\(pct)%)
        \(bar)
        """
    }
}
