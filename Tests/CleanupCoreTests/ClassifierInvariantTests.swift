import Testing
@testable import CleanupCore

// Safety invariant (task 2.5): the non-negotiable guarantee that protected
// locations can NEVER be surfaced as deletable, no matter what suffix is
// appended or what cache-/trash-like name appears underneath.

@Suite("Safety classifier — invariants")
struct ClassifierInvariantTests {

    static let blacklistedRoots = [
        "/System", "/usr", "/bin", "/sbin", "/private/var/vm", "/var/vm",
    ]

    // Suffixes deliberately chosen to look "cleanable" (cache/trash/log names).
    // All stay WITHIN the root — note that `..` can legitimately escape any
    // directory (even a protected one) into non-protected space, so escaping
    // suffixes are not part of this invariant; the "can't disguise a protected
    // path via `..`" case is covered in ClassifierBlacklistTests.
    static let temptingSuffixes = [
        "", "/Caches", "/Caches/foo.bin", "/.Trash", "/Logs/old.log",
        "/DerivedData/X", "/Application Support/MobileSync", "/./bin/sh",
    ]

    @Test("no protected path is ever deletable",
          arguments: blacklistedRoots, temptingSuffixes)
    func protectedPathsNeverDeletable(root: String, suffix: String) {
        let tier = SafetyClassifier.classify(root + suffix).tier
        #expect(tier == .never)
    }

    @Test("/usr/local stays user-writable under any tempting suffix",
          arguments: temptingSuffixes)
    func usrLocalNeverBecomesNever(suffix: String) {
        let tier = SafetyClassifier.classify("/usr/local" + suffix).tier
        #expect(tier != .never)
    }
}
