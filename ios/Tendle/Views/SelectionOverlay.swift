import SwiftUI

struct SelectionOverlay: View {
    let sum: Int

    var body: some View {
        Text("Selection.Sum \(sum)")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(background, in: Capsule())
            .foregroundStyle(.white)
    }

    private var background: Color {
        switch sum {
        case 10: return .green
        case ..<10: return .gray
        default: return .red
        }
    }
}
