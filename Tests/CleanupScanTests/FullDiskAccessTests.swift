import Testing
@testable import CleanupScan

// Full Disk Access detection logic (task 6.1). The *decision* is pure and
// injectable so it can be tested without real TCC state; the real probing of
// system paths is a thin wrapper exercised manually.

@Suite("Full Disk Access detection")
struct FullDiskAccessTests {

    @Test("a readable protected probe means granted")
    func readableMeansGranted() {
        #expect(FullDiskAccess.evaluate(probes: [.readable]) == .granted)
    }

    @Test("any readable probe means granted, even alongside failures")
    func anyReadableGranted() {
        #expect(FullDiskAccess.evaluate(probes: [.permissionDenied, .readable]) == .granted)
    }

    @Test("permission-denied probe means not granted")
    func deniedMeansNotGranted() {
        #expect(FullDiskAccess.evaluate(probes: [.permissionDenied]) == .notGranted)
    }

    @Test("Edge: a missing/non-existent probe is treated as not granted")
    func missingTreatedAsNotGranted() {
        #expect(FullDiskAccess.evaluate(probes: [.missing]) == .notGranted)
    }

    @Test("Edge: no probes at all is treated as not granted")
    func emptyTreatedAsNotGranted() {
        #expect(FullDiskAccess.evaluate(probes: []) == .notGranted)
    }
}
