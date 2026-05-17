import SwiftUI

@MainActor
enum ShareCardImageRenderer {
    /// Renders a 1080×1080 share card PNG to a temporary file URL, returning
    /// that URL. Suitable for ShareLink(item: URL).
    static func render(dateKST: String,
                       playerScore: Int,
                       botScore: Int?,
                       playerName: String = "지율") -> URL? {
        let view = ShareCardView(
            dateKST: dateKST,
            playerScore: playerScore,
            botScore: botScore,
            playerName: playerName)
        let renderer = ImageRenderer(content: view.frame(width: 1080, height: 1080))
        renderer.scale = 2.0
        guard let uiImage = renderer.uiImage,
              let data = uiImage.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "jiyul-share-\(dateKST).png")
        try? data.write(to: url, options: .atomic)
        return url
    }
}

private struct ShareCardView: View {
    let dateKST: String
    let playerScore: Int
    let botScore: Int?
    let playerName: String

    var body: some View {
        ZStack {
            Color(red: 0.965, green: 0.957, blue: 0.918) // cream paper
            VStack(spacing: 32) {
                Text("Jiyul").font(.system(size: 96, weight: .heavy, design: .rounded))
                Text(dateKST).font(.title).foregroundStyle(.secondary)
                HStack(spacing: 60) {
                    column(label: playerName, value: "\(playerScore)", color: .accentColor)
                    column(label: "Bot", value: botScore.map(String.init) ?? "…", color: .secondary)
                }
                if let bot = botScore, bot > 0 {
                    let pct = Int((min(1.0, Double(playerScore) / Double(bot)) * 100).rounded())
                    Text("\(pct)%").font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func column(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(label).font(.title2).foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 144, weight: .heavy, design: .rounded))
                .foregroundStyle(color).monospacedDigit()
        }
    }
}
