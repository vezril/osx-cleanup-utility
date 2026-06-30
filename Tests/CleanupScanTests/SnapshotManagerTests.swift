import Testing
import Foundation
@testable import CleanupScan

// APFS snapshot management (tasks 4.1, 4.3, 4.5). Parsing/validation are pure;
// list/delete/thin use an injected CommandRunner, so no real `tmutil` runs.

private final class ArgRec: @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [(String, [String])] = []
    func record(_ b: String, _ a: [String]) { lock.withLock { _calls.append((b, a)) } }
    var calls: [(String, [String])] { lock.withLock { _calls } }
}

@Suite("Snapshot management")
struct SnapshotManagerTests {

    // MARK: - 4.1 parsing

    @Test("well-formed tmutil output is parsed into dated snapshots")
    func parsesDates() {
        let output = """
        Snapshot dates for volume group containing disk /:
        2024-01-15-103000
        2024-01-16-120000
        """
        let dates = SnapshotManager.parseDates(output)
        #expect(dates == ["2024-01-15-103000", "2024-01-16-120000"])
    }

    @Test("Edge: empty output yields no snapshots")
    func emptyOutput() {
        #expect(SnapshotManager.parseDates("").isEmpty)
    }

    @Test("Edge: unparseable output fails safe (empty), no crash")
    func garbageOutput() {
        #expect(SnapshotManager.parseDates("totally unexpected\nformat here").isEmpty)
    }

    // MARK: - 4.3 date validation

    @Test("a well-formed snapshot date is accepted")
    func validDate() {
        #expect(SnapshotManager.isValidSnapshotDate("2024-01-15-103000"))
    }

    @Test("Edge: a malformed/injected date is rejected", arguments: [
        "2024-01-15", "2024-01-15-103000; rm -rf /", "$(whoami)", "../etc", "",
    ])
    func invalidDate(value: String) {
        #expect(!SnapshotManager.isValidSnapshotDate(value))
    }

    // MARK: - 4.5 delete / thin via tmutil with validated argv

    @Test("delete invokes tmutil deletelocalsnapshots with the validated date")
    func deleteInvokesTmutil() {
        let rec = ArgRec()
        let runner = CommandRunner(executor: { b, a, _ in rec.record(b, a); return .finished(stdout: "", stderr: "", exitCode: 0) })
        let mgr = SnapshotManager(runner: runner)
        _ = mgr.delete(date: "2024-01-15-103000")
        #expect(rec.calls.count == 1)
        #expect(rec.calls.first?.0.hasSuffix("tmutil") == true)
        #expect(rec.calls.first?.1 == ["deletelocalsnapshots", "2024-01-15-103000"])
    }

    @Test("Edge: delete with an invalid date never invokes tmutil")
    func deleteRefusesInvalidDate() {
        let rec = ArgRec()
        let runner = CommandRunner(executor: { b, a, _ in rec.record(b, a); return .finished(stdout: "", stderr: "", exitCode: 0) })
        let mgr = SnapshotManager(runner: runner)
        let result = mgr.delete(date: "2024; rm -rf /")
        #expect(result == nil)        // refused
        #expect(rec.calls.isEmpty)    // tmutil never called
    }

    @Test("thin invokes tmutil thinlocalsnapshots with the target bytes")
    func thinInvokesTmutil() {
        let rec = ArgRec()
        let runner = CommandRunner(executor: { b, a, _ in rec.record(b, a); return .finished(stdout: "", stderr: "", exitCode: 0) })
        let mgr = SnapshotManager(runner: runner, mountPoint: "/")
        _ = mgr.thin(bytes: 10_000_000_000, urgency: 4)
        #expect(rec.calls.first?.1 == ["thinlocalsnapshots", "/", "10000000000", "4"])
    }
}
