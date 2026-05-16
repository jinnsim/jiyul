import Foundation

enum BoardGenerator {
    static func generate(seed: UInt64) -> Board {
        var rng = SplitMix64(seed: seed)
        return Board(digits: (0..<Board.cellCount).map { _ in UInt8(nextDigit(&rng)) })
    }

    static func nextDigit(_ rng: inout SplitMix64) -> Int {
        let bound = (UInt64.max / 9) * 9
        var value: UInt64
        repeat {
            value = rng.next()
        } while value >= bound
        return Int(value % 9) + 1
    }
}
