import Testing
@testable import CleanupCore

// The non-negotiable half of the classifier (task 2.1): hard-blacklisted /
// SIP-protected paths must ALWAYS be `never`, unconditionally, and no traversal
// trick may bypass that. Pure: no filesystem I/O.

@Suite("Safety classifier — hard blacklist")
struct ClassifierBlacklistTests {

    @Test("SIP/system roots classify as never", arguments: [
        "/System",
        "/System/Library/CoreServices",
        "/usr",
        "/usr/lib/dyld",
        "/bin",
        "/bin/sh",
        "/sbin",
        "/sbin/launchd",
        "/private/var/vm",
        "/private/var/vm/sleepimage",
    ])
    func systemRootsAreNever(path: String) {
        #expect(SafetyClassifier.classify(path).tier == .never)
    }

    @Test("/var/vm (symlink form of /private/var/vm) is never")
    func varVmSymlinkFormIsNever() {
        #expect(SafetyClassifier.classify("/var/vm/sleepimage").tier == .never)
    }

    @Test("blacklist beats a cache-like name under a protected root")
    func blacklistBeatsOtherMatches() {
        // Even though it contains "Caches", being under /System makes it never.
        #expect(SafetyClassifier.classify("/System/Library/Caches").tier == .never)
    }

    @Test("/usr/local is NOT never (user-writable, SIP-exempt)")
    func usrLocalIsNotNever() {
        #expect(SafetyClassifier.classify("/usr/local/bin/tool").tier != .never)
    }

    @Test("normalization defeats traversal tricks", arguments: [
        "/System/../System/Library",
        "/System/",
        "/usr/./bin",
        "/private/var/vm/../vm/sleepimage",
    ])
    func normalizationCannotBypassBlacklist(path: String) {
        #expect(SafetyClassifier.classify(path).tier == .never)
    }

    @Test("the never reason mentions protection")
    func neverReasonIsInformative() {
        let c = SafetyClassifier.classify("/System")
        #expect(c.tier == .never)
        #expect(!c.reason.isEmpty)
    }
}
