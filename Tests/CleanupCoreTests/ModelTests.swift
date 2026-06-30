import Testing
@testable import CleanupCore

// Tests for the core value types (task 1.1). These are pure: no filesystem I/O.

@Suite("Core data model")
struct ModelTests {

    @Test("FileRecord carries path, kind, sizes, and mtime")
    func fileRecordHoldsAttributes() {
        let r = FileRecord(
            path: "/Users/x/Library/Caches/app/blob.bin",
            isDirectory: false,
            isSymlink: false,
            logicalSize: 1000,
            allocatedSize: 4096,
            modifiedAt: 1_700_000_000
        )
        #expect(r.path == "/Users/x/Library/Caches/app/blob.bin")
        #expect(r.isDirectory == false)
        #expect(r.isSymlink == false)
        #expect(r.logicalSize == 1000)
        #expect(r.allocatedSize == 4096)
        #expect(r.modifiedAt == 1_700_000_000)
    }

    @Test("FileRecord is a value type with structural equality")
    func fileRecordEquatable() {
        let a = FileRecord(path: "/a", isDirectory: true, isSymlink: false,
                           logicalSize: 0, allocatedSize: 0, modifiedAt: 0)
        let b = FileRecord(path: "/a", isDirectory: true, isSymlink: false,
                           logicalSize: 0, allocatedSize: 0, modifiedAt: 0)
        #expect(a == b)
    }

    @Test("SafetyTier has the five expected cases")
    func safetyTierCases() {
        let all = SafetyTier.allCases
        #expect(all.count == 5)
        #expect(all.contains(.safe))
        #expect(all.contains(.cache))
        #expect(all.contains(.delegated))
        #expect(all.contains(.risky))
        #expect(all.contains(.never))
    }

    @Test("Classification pairs a tier with a human-readable reason")
    func classificationHoldsTierAndReason() {
        let c = Classification(tier: .cache, reason: "apps will regenerate this")
        #expect(c.tier == .cache)
        #expect(c.reason == "apps will regenerate this")
    }
}
