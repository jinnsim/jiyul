import SwiftUI

struct BoardView: View {
    let board: Board
    let highlight: Selection?
    let cellSize: CGFloat

    private let spacing: CGFloat = 2

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<Board.rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<Board.columns, id: \.self) { column in
                        cell(column: column, row: row)
                    }
                }
            }
        }
        .frame(width: cellSize * CGFloat(Board.columns) + spacing * CGFloat(Board.columns - 1),
               height: cellSize * CGFloat(Board.rows) + spacing * CGFloat(Board.rows - 1))
    }

    @ViewBuilder
    private func cell(column: Int, row: Int) -> some View {
        let isHighlighted = highlight.map { sel in
            (sel.minColumn...sel.maxColumn).contains(column) &&
            (sel.minRow...sel.maxRow).contains(row)
        } ?? false
        let cleared = board.isCleared(column: column, row: row)
        let digit = board.digit(column: column, row: row)
        let radius = max(4, cellSize * 0.22)

        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Self.tokenFill(for: digit))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(
                            isHighlighted ? Color.accentColor : Color.black.opacity(0.06),
                            lineWidth: isHighlighted ? 2.5 : 0.6
                        )
                )
                .shadow(color: Color.black.opacity(cleared ? 0 : 0.06),
                        radius: 1.5, x: 0, y: 1)
                .opacity(cleared ? 0 : 1)
                .scaleEffect(cleared ? 0.4 : 1)
                .animation(.easeOut(duration: 0.18), value: cleared)
            if !cleared {
                Text("\(digit)")
                    .font(.system(size: cellSize * 0.58, weight: .bold, design: .rounded))
                    .foregroundStyle(Self.digitColor(for: digit))
                    .shadow(color: .white.opacity(0.7), radius: 0.5, x: 0, y: 0.5)
            }
            if isHighlighted && !cleared {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.accentColor.opacity(0.18))
            }
        }
        .frame(width: cellSize, height: cellSize)
    }

    /// Background "candy" color per digit — soft pastels keyed to the value.
    /// Subtle on purpose: the digit color carries the primary contrast.
    static func tokenFill(for digit: Int) -> Color {
        switch digit {
        case 1: return Color(red: 1.00, green: 0.93, blue: 0.85)   // peach
        case 2: return Color(red: 1.00, green: 0.96, blue: 0.78)   // butter
        case 3: return Color(red: 0.91, green: 0.97, blue: 0.86)   // mint
        case 4: return Color(red: 0.85, green: 0.93, blue: 0.98)   // sky
        case 5: return Color(red: 0.93, green: 0.88, blue: 0.97)   // lavender
        case 6: return Color(red: 0.99, green: 0.86, blue: 0.90)   // rose
        case 7: return Color(red: 0.91, green: 0.95, blue: 0.84)   // sage
        case 8: return Color(red: 0.97, green: 0.92, blue: 0.80)   // cream
        case 9: return Color(red: 0.99, green: 0.84, blue: 0.80)   // coral
        default: return Color(.systemGray6)
        }
    }

    static func digitColor(for digit: Int) -> Color {
        switch digit {
        case 1: return Color(red: 0.78, green: 0.45, blue: 0.27)   // burnt peach
        case 2: return Color(red: 0.72, green: 0.55, blue: 0.10)   // mustard
        case 3: return Color(red: 0.18, green: 0.55, blue: 0.31)   // forest mint
        case 4: return Color(red: 0.17, green: 0.40, blue: 0.71)   // ocean blue
        case 5: return Color(red: 0.43, green: 0.30, blue: 0.66)   // grape
        case 6: return Color(red: 0.78, green: 0.27, blue: 0.45)   // berry
        case 7: return Color(red: 0.30, green: 0.50, blue: 0.20)   // olive
        case 8: return Color(red: 0.62, green: 0.45, blue: 0.13)   // bronze
        case 9: return Color(red: 0.78, green: 0.27, blue: 0.20)   // brick red
        default: return Color.primary
        }
    }
}
