// Core value types for the functional core.
//
// Pure data: no imports, no I/O. The scanner (imperative shell) produces
// `FileRecord`s; the core rolls them up, classifies them, and lays them out.

/// An immutable record of one filesystem entry, produced by the scanner.
///
/// - `logicalSize`: the file's apparent size (`st_size`).
/// - `allocatedSize`: the actual on-disk footprint (`st_blocks * 512`). This is
///   what reclaiming the file would free, so it is the size used for rankings
///   and the treemap.
/// - `modifiedAt`: modification time as seconds since the Unix epoch.
public struct FileRecord: Equatable, Hashable, Sendable {
    public let path: String
    public let isDirectory: Bool
    public let isSymlink: Bool
    public let logicalSize: Int64
    public let allocatedSize: Int64
    public let modifiedAt: Int64

    public init(
        path: String,
        isDirectory: Bool,
        isSymlink: Bool,
        logicalSize: Int64,
        allocatedSize: Int64,
        modifiedAt: Int64
    ) {
        self.path = path
        self.isDirectory = isDirectory
        self.isSymlink = isSymlink
        self.logicalSize = logicalSize
        self.allocatedSize = allocatedSize
        self.modifiedAt = modifiedAt
    }
}

/// The five-tier safety model. Ordering is from most to least reclaim-friendly,
/// except `never`, which is non-negotiable: such paths may never be surfaced as
/// cleanable. See the sourced rules in the project research reference.
public enum SafetyTier: String, CaseIterable, Sendable {
    /// Regenerable / disposable, no user data (e.g. Trash, Xcode DerivedData).
    case safe
    /// Safe but apps regenerate it; transient slowdown after (e.g. caches).
    case cache
    /// Owner tool manages the data; never raw-delete (e.g. snapshots, Docker).
    case delegated
    /// User-owned and often irreplaceable (e.g. App Support, iOS backups).
    case risky
    /// SIP/system/OS-managed; the OS blocks writes. Never cleanable.
    case never
}

/// A safety tier paired with a human-readable reason for that classification.
public struct Classification: Equatable, Sendable {
    public let tier: SafetyTier
    public let reason: String

    public init(tier: SafetyTier, reason: String) {
        self.tier = tier
        self.reason = reason
    }
}
