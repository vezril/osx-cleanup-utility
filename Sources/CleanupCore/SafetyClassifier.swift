// The safety classifier — the spine of the product.
//
// `classify` is a pure function: deterministic, no I/O. The hard blacklist is
// evaluated FIRST and unconditionally, so no input can ever cause a SIP/system
// path to be classified as a deletable tier. The ruleset for other tiers
// (task 2.3/2.4) is layered on top.

public enum SafetyClassifier {

    /// Hard-blacklisted roots that are always `never`. Stored normalized
    /// (/var -> /private/var). `/usr` is blacklisted EXCEPT `/usr/local`,
    /// handled explicitly below.
    static let blacklistRoots: [String] = [
        "/System",
        "/bin",
        "/sbin",
        "/usr",
        "/private/var/vm",
    ]

    /// A classification rule: if `match` appears as a contiguous run of
    /// components anywhere in a path, the path takes this tier/reason. The most
    /// specific match (longest `match`) wins across all rules.
    struct Rule {
        let match: [String]
        let tier: SafetyTier
        let reason: String
    }

    /// Ordered ruleset mirroring the sourced research reference. Specificity is
    /// the number of components in `match`; longest match wins, so nested
    /// overrides (e.g. Homebrew inside Caches) take precedence automatically.
    static let rules: [Rule] = [
        Rule(match: ["Library", "Developer", "Xcode", "DerivedData"], tier: .safe,
             reason: "Regenerable Xcode build artifacts — rebuilt on next build."),
        Rule(match: ["Library", "Developer", "Xcode", "Archives"], tier: .risky,
             reason: "App archives for distribution — cannot be regenerated."),
        Rule(match: ["Library", "Developer", "Xcode", "iOS DeviceSupport"], tier: .cache,
             reason: "Symbol data — re-downloads when a device connects."),
        Rule(match: ["Library", "Developer", "CoreSimulator"], tier: .cache,
             reason: "Simulator runtimes and device data — re-download on demand."),
        Rule(match: [".Trash"], tier: .safe,
             reason: "Items already in the Trash."),
        Rule(match: ["Library", "Caches", "Homebrew"], tier: .delegated,
             reason: "Use `brew cleanup --prune=all` so Homebrew's index stays consistent."),
        Rule(match: ["Library", "Caches"], tier: .cache,
             reason: "Application cache — apps will regenerate it."),
        // Ordered before the generic Containers rule: Docker's data lives inside
        // Library/Containers but must be managed via Docker, not raw-deleted. On
        // a specificity tie the earliest rule wins, so this takes precedence.
        Rule(match: ["Containers", "com.docker.docker"], tier: .delegated,
             reason: "Manage via Docker (`docker system prune`); never delete the raw disk image."),
        Rule(match: ["Library", "Application Support", "MobileSync"], tier: .risky,
             reason: "iOS device backups — often the only local copy."),
        Rule(match: ["Library", "Application Support"], tier: .risky,
             reason: "May hold the only copy of an app's data."),
        Rule(match: ["Library", "Group Containers"], tier: .risky,
             reason: "Shared by multiple apps — deleting can break several at once."),
        Rule(match: ["Library", "Containers"], tier: .risky,
             reason: "Live data for sandboxed apps."),
        Rule(match: ["Library", "Logs"], tier: .cache,
             reason: "Diagnostic logs — regenerated as needed."),
        Rule(match: ["Downloads"], tier: .risky,
             reason: "User downloads — review before removing."),
    ]

    /// Classify any path into a safety tier with a human-readable reason.
    public static func classify(_ path: String) -> Classification {
        if let reason = blacklistReason(path) {
            return Classification(tier: .never, reason: reason)
        }
        let comps = PathNormalize.components(PathNormalize.normalize(path))
        var best: Rule?
        for rule in rules where containsRun(comps, rule.match) {
            if best == nil || rule.match.count > best!.match.count {
                best = rule
            }
        }
        if let best {
            return Classification(tier: best.tier, reason: best.reason)
        }
        // Unrecognized — conservative default, never `safe`.
        return Classification(
            tier: .risky,
            reason: "Unrecognized location — treated conservatively as risky."
        )
    }

    /// True if `needle` appears as a contiguous run within `haystack`.
    static func containsRun(_ haystack: [String], _ needle: [String]) -> Bool {
        guard !needle.isEmpty, haystack.count >= needle.count else { return false }
        for start in 0...(haystack.count - needle.count) {
            if Array(haystack[start..<start + needle.count]) == needle { return true }
        }
        return false
    }

    /// Returns a reason string if the path is hard-blacklisted, else nil.
    static func blacklistReason(_ path: String) -> String? {
        // /usr/local is user-writable and SIP-exempt — carve it out before the
        // /usr blacklist rule applies.
        if PathNormalize.isUnder(path, prefix: "/usr/local") {
            return nil
        }
        for root in blacklistRoots where PathNormalize.isUnder(path, prefix: root) {
            if root == "/private/var/vm" {
                return "OS-managed virtual memory (sleep image / swap) — never modify."
            }
            return "SIP-protected system location (\(root)) — the OS blocks modification, even with sudo."
        }
        return nil
    }
}
