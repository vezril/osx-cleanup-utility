// Cleanup history — pure, append-only, newest-first. No I/O, no clock.
//
// Each completed cleanup (file deletion or delegated run) is recorded as one
// immutable, timestamped entry. Timestamps are supplied by the caller — the
// pure core never reads the clock — so ordering and capping are deterministic
// and unit-testable.

public struct HistoryEntry: Equatable, Sendable, Codable, Identifiable {
    public enum Kind: String, Sendable, Codable {
        case fileDeletion
        case delegated
    }

    public let id: String
    /// Seconds since the Unix epoch, supplied by the shell.
    public let timestamp: Int64
    public let kind: Kind
    public let itemCount: Int
    public let reclaimedBytes: Int64
    /// Outcome label → count (e.g. "trashed": 3, "failed": 1).
    public let outcomeCounts: [String: Int]

    public init(id: String, timestamp: Int64, kind: Kind, itemCount: Int,
                reclaimedBytes: Int64, outcomeCounts: [String: Int]) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
        self.itemCount = itemCount
        self.reclaimedBytes = reclaimedBytes
        self.outcomeCounts = outcomeCounts
    }
}

public enum CleanupHistory {
    /// Default retention cap on stored entries.
    public static let defaultCap = 500

    /// Append `entry`, returning history sorted newest-first and trimmed to
    /// the most recent `cap` entries.
    public static func append(_ entry: HistoryEntry, to history: [HistoryEntry], cap: Int = defaultCap) -> [HistoryEntry] {
        let combined = (history + [entry]).sorted { $0.timestamp > $1.timestamp }
        return Array(combined.prefix(max(0, cap)))
    }
}
