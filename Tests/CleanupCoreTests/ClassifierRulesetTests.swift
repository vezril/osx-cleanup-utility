import Testing
@testable import CleanupCore

// The ruleset half of the classifier (task 2.3): known user-space locations
// map to the tiers documented in the sourced research. Paths are written as a
// real scanner would produce them (absolute, under a user home). Pure: no I/O.

@Suite("Safety classifier — ruleset")
struct ClassifierRulesetTests {

    private let home = "/Users/calvin"

    @Test("Xcode DerivedData is safe")
    func derivedDataSafe() {
        let c = SafetyClassifier.classify("\(home)/Library/Developer/Xcode/DerivedData/App-abc")
        #expect(c.tier == .safe)
    }

    @Test("Trash is safe")
    func trashSafe() {
        #expect(SafetyClassifier.classify("\(home)/.Trash/old.dmg").tier == .safe)
    }

    @Test("Library/Caches is a cache")
    func cachesCache() {
        #expect(SafetyClassifier.classify("\(home)/Library/Caches/com.example.app").tier == .cache)
    }

    @Test("Docker.raw is delegated (manage via docker, never raw-delete)")
    func dockerDelegated() {
        let p = "\(home)/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw"
        #expect(SafetyClassifier.classify(p).tier == .delegated)
    }

    @Test("Application Support is risky")
    func appSupportRisky() {
        #expect(SafetyClassifier.classify("\(home)/Library/Application Support/SomeApp").tier == .risky)
    }

    @Test("iOS device backups are risky")
    func iosBackupsRisky() {
        let p = "\(home)/Library/Application Support/MobileSync/Backup/00008110"
        #expect(SafetyClassifier.classify(p).tier == .risky)
    }

    @Test("Downloads is risky (user data)")
    func downloadsRisky() {
        #expect(SafetyClassifier.classify("\(home)/Downloads/big.iso").tier == .risky)
    }

    // --- edge cases ---

    @Test("Edge: unknown path defaults conservatively (never safe)")
    func unknownConservative() {
        let c = SafetyClassifier.classify("\(home)/SomeRandomFolder/file.dat")
        #expect(c.tier != .safe)
        #expect(c.tier != .never)
    }

    @Test("Edge: most-specific rule wins — Homebrew cache is delegated, not cache")
    func mostSpecificWins() {
        // ~/Library/Caches → cache, but the nested Homebrew cache → delegated.
        let generic = SafetyClassifier.classify("\(home)/Library/Caches/foo")
        let specific = SafetyClassifier.classify("\(home)/Library/Caches/Homebrew/downloads/x.tar")
        #expect(generic.tier == .cache)
        #expect(specific.tier == .delegated)
    }
}
