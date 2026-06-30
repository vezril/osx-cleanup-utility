import Testing
import Foundation
@testable import CleanupScan
import CleanupCore

// Persistent store (tasks 4.1, 4.3). Logic tests use an in-memory fake; one
// test exercises the real file-backed store under a temp directory.

private final class Box: @unchecked Sendable {
    private let lock = NSLock()
    private var _data: Data?
    init(_ d: Data? = nil) { _data = d }
    var data: Data? {
        get { lock.withLock { _data } }
        set { lock.withLock { _data = newValue } }
    }
}

@Suite("Persistent store")
struct StoreTests {

    private func sampleState() -> AppState {
        var ex = ExclusionSet(); ex.insert("/Users/calvin/Projects")
        let h = [HistoryEntry(id: "x", timestamp: 100, kind: .fileDeletion,
                              itemCount: 2, reclaimedBytes: 500, outcomeCounts: ["trashed": 2])]
        return AppState(version: 1, exclusions: ex, history: h)
    }

    // MARK: - 4.1 in-memory

    @Test("save then load round-trips the state")
    func roundTrip() {
        let box = Box()
        let store = Store(read: { box.data }, write: { box.data = $0 })
        store.save(sampleState())
        #expect(store.load() == sampleState())
    }

    @Test("Edge: a missing file loads defaults")
    func missingDefaults() {
        let store = Store(read: { nil }, write: { _ in })
        let state = store.load()
        #expect(state.exclusions.isEmpty)
        #expect(state.history.isEmpty)
        #expect(state.version >= 1)
    }

    @Test("Edge: a corrupt payload loads defaults without throwing")
    func corruptDefaults() {
        let store = Store(read: { Data("not json".utf8) }, write: { _ in })
        let state = store.load()
        #expect(state.exclusions.isEmpty)
        #expect(state.history.isEmpty)
    }

    // MARK: - 4.3 real file-backed store

    @Test("the real file-backed store round-trips under a temp directory")
    func fileRoundTrip() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("store-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("state.json")

        let store = Store.file(at: url)
        store.save(sampleState())
        #expect(store.load() == sampleState())
        #expect(FileManager.default.fileExists(atPath: url.path))
    }
}
