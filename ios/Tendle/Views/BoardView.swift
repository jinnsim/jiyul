import SwiftUI

struct BoardView: View {
    let board: Board
    let highlight: Selection?

    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(
                geometry.size.width / CGFloat(Board.columns),
                geometry.size.height / CGFloat(Board.rows)
            )
            VStack(spacing: 0) {
                ForEach(0..<Board.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<Board.columns, id: \.self) { column in
                            cell(column: column, row: row, size: cellSize)
                        }
                    }
                }
            }
            .frame(width: cellSize * CGFloat(Board.columns),
                   height: cellSize * CGFloat(Board.rows))
        }
        .aspectRatio(CGFloat(Board.columns) / CGFloat(Board.rows), contentMode: .fit)
    }

    @ViewBuilder
    private func cell(column: Int, row: Int, size: CGFloat) -> some View {
        let isHighlighted = highlight.map { sel in
            (sel.minColumn...sel.maxColumn).contains(column) &&
            (sel.minRow...sel.maxRow).contains(row)
        } ?? false
        let cleared = board.isCleared(column: column, row: row)
        ZStack {
            Rectangle()
                .fill(isHighlighted ? Color.accentColor.opacity(0.25) : Color(.systemGray6))
                .border(Color(.systemGray3).opacity(0.4))
            if !cleared {
                Text("\(board.digit(column: column, row: row))")
                    .font(.system(size: size * 0.55, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
        }
        .frame(width: size, height: size)
    }
}
