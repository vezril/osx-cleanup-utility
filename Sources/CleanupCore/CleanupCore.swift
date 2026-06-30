// CleanupCore — the functional core.
//
// This module is intentionally pure: it imports no UI framework and performs
// no filesystem I/O. All decision logic for the cleanup utility (size roll-up,
// the 5-tier safety classifier, deletion planning) will live here in later
// milestones, where it can be unit-tested without touching real files.
//
// Milestone 0 ships no behaviour yet — only the namespace and an identity
// value that proves the test harness is wired (see CleanupCoreTests).

/// Namespace and identity for the functional core.
public enum CleanupCore {
    /// Semantic version of the functional core. Pure, deterministic, no I/O.
    public static let version = "0.1.0"
}
