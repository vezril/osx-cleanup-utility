import Testing
@testable import CleanupCore

// Smoke tests for the functional core.
//
// Uses the Swift Testing framework (bundled with the Swift toolchain), which
// runs both with Command Line Tools (no Xcode) locally and on CI's Xcode
// runners — unlike XCTest, which requires Xcode.
//
// These prove the Red→Green→Refactor harness runs before any feature exists.
// They exercise only pure CleanupCore code and perform no filesystem I/O, so
// the suite is safe to run anywhere.

@Suite("CleanupCore smoke tests")
struct CleanupCoreTests {

    /// The functional core exposes a semantic version identity.
    @Test("core exposes a semantic version")
    func coreExposesSemanticVersion() {
        #expect(CleanupCore.version == "0.1.0")
    }
}
