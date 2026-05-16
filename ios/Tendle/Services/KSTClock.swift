import Foundation
import CryptoKit

enum KSTClock {
    private static let kst = TimeZone(identifier: "Asia/Seoul")!
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = kst
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dateString(for date: Date = Date()) -> String {
        formatter.string(from: date)
    }

    static func dailySeed(forDate kstDateString: String) -> UInt64 {
        let input = "\(kstDateString)|daily"
        let digest = SHA256.hash(data: Data(input.utf8))
        var seed: UInt64 = 0
        for (i, byte) in digest.prefix(8).enumerated() {
            seed |= UInt64(byte) << (UInt64(i) * 8)
        }
        return seed
    }
}
