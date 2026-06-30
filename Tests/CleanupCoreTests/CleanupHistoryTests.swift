import Testing
@testable import CleanupCore

// Cleanup history records (task 3.1). Pure: timestamps are injected, the core
// never reads the clock. No I/O.

@Suite("Cleanup history")
struct CleanupHistoryTests {

    private func entry(_ id: String, _ ts: Int64) -> HistoryEntry {
        HistoryEntry(id: id, timestamp: ts, kind: .fileDeletion,
                     itemCount: 1, reclaimedBytes: 100, outcomeCounts: ["trashed": 1])
    }

    @Test("an entry carries its fields")
    func entryShape() {
        let e = HistoryEntry(id: "a", timestamp: 1000, kind: .delegated,
                             itemCount: 3, reclaimedBytes: 2048, outcomeCounts: ["succeeded": 2])
        #expect(e.kind == .delegated)
        #expect(e.itemCount == 3)
        #expect(e.reclaimedBytes == 2048)
        #expect(e.outcomeCounts["succeeded"] == 2)
    }

    @Test("append yields newest-first ordering")
    func newestFirst() {
        let h0 = [entry("old", 100)]
        let h1 = CleanupHistory.append(entry("new", 200), to: h0, cap: 10)
        #expect(h1.map(\.id) == ["new", "old"])
    }

    @Test("Edge: history is capped, dropping the oldest")
    func capped() {
        var history: [HistoryEntry] = []
        for i in 1...5 { history = CleanupHistory.append(entry("e\(i)", Int64(i)), to: history, cap: 3) }
        #expect(history.count == 3)
        #expect(history.map(\.id) == ["e5", "e4", "e3"])   // newest kept, oldest dropped
    }

    @Test("Edge: out-of-order timestamps still sort newest-first")
    func outOfOrder() {
        var history = [entry("b", 200)]
        history = CleanupHistory.append(entry("a", 100), to: history, cap: 10) // older arrives later
        #expect(history.map(\.id) == ["b", "a"])
    }
}
