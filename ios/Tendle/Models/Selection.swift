import Foundation

struct Selection: Hashable, Comparable {
    let minColumn: Int
    let minRow: Int
    let maxColumn: Int
    let maxRow: Int

    init(minColumn: Int, minRow: Int, maxColumn: Int, maxRow: Int) {
        self.minColumn = min(minColumn, maxColumn)
        self.minRow = min(minRow, maxRow)
        self.maxColumn = max(minColumn, maxColumn)
        self.maxRow = max(minRow, maxRow)
    }

    static func < (lhs: Selection, rhs: Selection) -> Bool {
        if lhs.minRow != rhs.minRow { return lhs.minRow < rhs.minRow }
        if lhs.minColumn != rhs.minColumn { return lhs.minColumn < rhs.minColumn }
        if lhs.maxRow != rhs.maxRow { return lhs.maxRow < rhs.maxRow }
        return lhs.maxColumn < rhs.maxColumn
    }
}
