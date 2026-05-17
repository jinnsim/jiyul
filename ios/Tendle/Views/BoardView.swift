import SwiftUI

struct BoardView: View {
    let board: Board
    let highlight: Selection?
    let cellSize: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<Board.rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<Board.columns, id: \.self) { column in
                        cell(column: column, row: row)
                    }
                }
            }
        }
        .frame(width: cellSize * CGFloat(Board.columns),
               height: cellSize * CGFloat(Board.rows))
    }

    @ViewBuilder
    private func cell(column: Int, row: Int) -> some View {
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
                    .font(.system(size: cellSize * 0.55, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
        }
        .frame(width: cellSize, height: cellSize)
    }
}
