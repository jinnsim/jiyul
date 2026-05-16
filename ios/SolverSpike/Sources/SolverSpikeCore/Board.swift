public struct Selection: Hashable, Comparable {
    public let minColumn: Int
    public let minRow: Int
    public let maxColumn: Int
    public let maxRow: Int

    public init(minColumn: Int, minRow: Int, maxColumn: Int, maxRow: Int) {
        self.minColumn = min(minColumn, maxColumn)
        self.minRow = min(minRow, maxRow)
        self.maxColumn = max(minColumn, maxColumn)
        self.maxRow = max(minRow, maxRow)
    }

    public static func < (lhs: Selection, rhs: Selection) -> Bool {
        if lhs.minRow != rhs.minRow { return lhs.minRow < rhs.minRow }
        if lhs.minColumn != rhs.minColumn { return lhs.minColumn < rhs.minColumn }
        if lhs.maxRow != rhs.maxRow { return lhs.maxRow < rhs.maxRow }
        return lhs.maxColumn < rhs.maxColumn
    }
}

public struct Board: Hashable {
    public static let columns = 17
    public static let rows = 10
    public static let cellCount = columns * rows
    public static let maskWordCount = 3

    public let digits: [UInt8]
    public let clearedWords: [UInt64]

    public init(digits: [UInt8], clearedWords: [UInt64] = Array(repeating: 0, count: maskWordCount)) {
        precondition(digits.count == Self.cellCount, "Board must contain 170 digits.")
        precondition(clearedWords.count == Self.maskWordCount, "Board mask must contain 3 words.")
        precondition(digits.allSatisfy { (1...9).contains($0) }, "Digits must be 1...9.")
        self.digits = digits
        self.clearedWords = clearedWords
    }

    public init(rows: [String]) {
        precondition(rows.count <= Self.rows, "Fixture has too many rows.")
        var values: [UInt8] = []
        var active = Set<Int>()
        for row in rows {
            precondition(row.count <= Self.columns, "Fixture row is too wide.")
            let rowIndex = values.count / Self.columns
            var columnIndex = 0
            for character in row {
                precondition(("1"..."9").contains(character), "Fixture digits must be 1...9.")
                values.append(UInt8(String(character))!)
                active.insert(rowIndex * Self.columns + columnIndex)
                columnIndex += 1
            }
            values.append(contentsOf: Array(repeating: 9, count: Self.columns - row.count))
        }
        values.append(contentsOf: Array(repeating: 9, count: Self.cellCount - values.count))
        var clearedWords = Array(repeating: UInt64.max, count: Self.maskWordCount)
        for index in active {
            clearedWords[index / 64] &= ~(UInt64(1) << UInt64(index % 64))
        }
        let validBitsInLastWord = Self.cellCount - (Self.maskWordCount - 1) * 64
        clearedWords[Self.maskWordCount - 1] &= (UInt64(1) << UInt64(validBitsInLastWord)) - 1
        self.init(digits: values, clearedWords: clearedWords)
    }

    public func index(column: Int, row: Int) -> Int {
        row * Self.columns + column
    }

    public func contains(column: Int, row: Int) -> Bool {
        column >= 0 && column < Self.columns && row >= 0 && row < Self.rows
    }

    public func digit(column: Int, row: Int) -> Int {
        Int(digits[index(column: column, row: row)])
    }

    public func isCleared(index: Int) -> Bool {
        let word = index / 64
        let bit = UInt64(1) << UInt64(index % 64)
        return (clearedWords[word] & bit) != 0
    }

    public func isCleared(column: Int, row: Int) -> Bool {
        isCleared(index: index(column: column, row: row))
    }

    public func value(column: Int, row: Int) -> Int {
        isCleared(column: column, row: row) ? 0 : digit(column: column, row: row)
    }

    public var clearedCount: Int {
        clearedWords.reduce(0) { $0 + $1.nonzeroBitCount }
    }

    public func clearing(_ indices: [Int]) -> Board {
        var words = clearedWords
        for index in indices {
            words[index / 64] |= UInt64(1) << UInt64(index % 64)
        }
        return Board(digits: digits, clearedWords: words)
    }
}
