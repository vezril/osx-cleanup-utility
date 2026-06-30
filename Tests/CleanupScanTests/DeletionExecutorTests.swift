import Testing
import Foundation
@testable import CleanupScan
import CleanupCore

// Deletion executor integration tests (tasks 3.1, 3.3, 3.5). The trash/remove
// operations are injected so tests stay hermetic — they never touch the real
// Trash and only operate inside a temporary directory.

@Suite("Deletion executor")
struct DeletionExecutorTests {

    private func tempDir() throws -> URL {
        let u = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("del-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }
    private func makeFile(_ dir: URL, _ name: String) throws -> URL {
        let u = dir.appendingPathComponent(name)
        try Data(repeating: 0x42, count: 256).write(to: u)
        return u
    }
    private func item(_ path: String, _ tier: SafetyTier, _ mode: DeletionMode) -> DeletionItem {
        DeletionItem(path: path, tier: tier, allocatedSize: 256, mode: mode)
    }

    // MARK: - 3.1 trash by default

    @Test("trash mode moves items to trash and reports trashed")
    func trashMode() throws {
        let root = try tempDir(); defer { try? FileManager.default.removeItem(at: root) }
        let fakeTrash = try tempDir(); defer { try? FileManager.default.removeItem(at: fakeTrash) }
        let f = try makeFile(root, "junk.bin")

        let exec = DeletionExecutor(
            trashItem: { url in
                try FileManager.default.moveItem(at: url, to: fakeTrash.appendingPathComponent(url.lastPathComponent))
            },
            removeItem: { _ in Issue.record("permanent delete should not be called") }
        )
        let plan = DeletionPlan(items: [item(f.path, .safe, .trash)], refused: [], mode: .trash)
        let results = exec.execute(plan)

        #expect(results.count == 1)
        #expect(results.first?.outcome == .trashed)
        #expect(!FileManager.default.fileExists(atPath: f.path))      // removed from origin
        // recoverable: now lives in the (fake) trash
        #expect(FileManager.default.fileExists(atPath: fakeTrash.appendingPathComponent("junk.bin").path))
    }

    // MARK: - 3.3 permanent + no silent fallback

    @Test("permanent mode removes items and reports deleted")
    func permanentMode() throws {
        let root = try tempDir(); defer { try? FileManager.default.removeItem(at: root) }
        let f = try makeFile(root, "gone.bin")
        let exec = DeletionExecutor()  // real removeItem; operating only inside temp dir
        let plan = DeletionPlan(items: [item(f.path, .cache, .permanent)], refused: [], mode: .permanent)
        let results = exec.execute(plan)
        #expect(results.first?.outcome == .deleted)
        #expect(!FileManager.default.fileExists(atPath: f.path))
    }

    @Test("Edge: trash failure is reported and never silently permanent")
    func trashFailureNoFallback() throws {
        let root = try tempDir(); defer { try? FileManager.default.removeItem(at: root) }
        let f = try makeFile(root, "keep.bin")
        let exec = DeletionExecutor(
            trashItem: { _ in throw NSError(domain: "test", code: 1) },
            removeItem: { _ in Issue.record("must not permanently delete on trash failure") }
        )
        let plan = DeletionPlan(items: [item(f.path, .cache, .trash)], refused: [], mode: .trash)
        let results = exec.execute(plan)
        if case .failed = results.first?.outcome {} else { Issue.record("expected .failed") }
        #expect(FileManager.default.fileExists(atPath: f.path))  // still there
    }

    // MARK: - 3.5 re-validation + partial failure

    @Test("a protected item is refused even if present in the plan")
    func refusesNeverAtExecution() throws {
        // Construct a plan that (incorrectly) contains a NEVER path, bypassing the
        // planner, to prove the executor's independent re-check.
        let exec = DeletionExecutor(
            trashItem: { _ in Issue.record("must not trash a protected path") },
            removeItem: { _ in Issue.record("must not delete a protected path") }
        )
        let plan = DeletionPlan(items: [item("/System/Library/X", .safe, .trash)], refused: [], mode: .trash)
        let results = exec.execute(plan)
        if case .refused = results.first?.outcome {} else { Issue.record("expected .refused") }
    }

    @Test("Edge: vanished item is failed(gone) and the batch continues")
    func vanishedContinues() throws {
        let root = try tempDir(); defer { try? FileManager.default.removeItem(at: root) }
        let present = try makeFile(root, "here.bin")
        let missing = root.appendingPathComponent("nope.bin").path
        let fakeTrash = try tempDir(); defer { try? FileManager.default.removeItem(at: fakeTrash) }

        let exec = DeletionExecutor(
            trashItem: { url in try FileManager.default.moveItem(at: url, to: fakeTrash.appendingPathComponent(url.lastPathComponent)) },
            removeItem: { try FileManager.default.removeItem(at: $0) }
        )
        let plan = DeletionPlan(items: [
            item(missing, .cache, .trash),
            item(present.path, .safe, .trash),
        ], refused: [], mode: .trash)
        let results = exec.execute(plan)

        #expect(results.count == 2)  // per-item result for every item
        let byPath = Dictionary(uniqueKeysWithValues: results.map { ($0.path, $0.outcome) })
        if case .failed = byPath[missing] {} else { Issue.record("missing should be failed") }
        #expect(byPath[present.path] == .trashed)  // success despite the sibling's failure
    }
}
