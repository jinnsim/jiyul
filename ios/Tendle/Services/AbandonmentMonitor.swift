import Foundation

enum AbandonmentMonitor {
    /// Returns true when the gap between leaving foreground and returning
    /// exceeds the configured threshold (default 5 minutes).
    static func shouldMarkAbandoned(
        leftForegroundAt: Date,
        returnedAt: Date,
        thresholdSeconds: TimeInterval = 300
    ) -> Bool {
        returnedAt.timeIntervalSince(leftForegroundAt) >= thresholdSeconds
    }
}
