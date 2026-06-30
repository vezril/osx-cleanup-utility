import Foundation
import Observation
import CleanupCore
import CleanupScan

// Shared persisted state (M4): user exclusions + cleanup history, backed by the
// JSON Store. Both the scan model and the delegated model reference this single
// owner so they never clobber each other's state.

@MainActor
@Observable
final class AppStateModel {
    private let store: Store
    var exclusions: ExclusionSet
    var history: [HistoryEntry]

    init(store: Store = .file(at: Store.defaultLocation())) {
        self.store = store
        let loaded = store.load()
        self.exclusions = loaded.exclusions
        self.history = loaded.history
    }

    /// Persisted exclusions plus the app's own state container (D6: the tool must
    /// never offer its own state for deletion).
    var effectiveExclusions: ExclusionSet {
        var e = exclusions
        e.insert(AppPaths.supportDirectory().path)
        return e
    }

    func isProtected(_ path: String) -> Bool { exclusions.contains(path) }

    func addExclusion(_ path: String) { exclusions.insert(path); persist() }
    func removeExclusion(_ path: String) { exclusions.remove(path); persist() }

    /// Record a completed cleanup. The timestamp/id come from the shell, keeping
    /// the core pure.
    func record(kind: HistoryEntry.Kind, itemCount: Int, reclaimedBytes: Int64,
                outcomeCounts: [String: Int]) {
        let entry = HistoryEntry(
            id: UUID().uuidString,
            timestamp: Int64(Date().timeIntervalSince1970),
            kind: kind, itemCount: itemCount,
            reclaimedBytes: reclaimedBytes, outcomeCounts: outcomeCounts)
        history = CleanupHistory.append(entry, to: history)
        persist()
    }

    func clearHistory() { history = []; persist() }

    private func persist() {
        store.save(AppState(version: 1, exclusions: exclusions, history: history))
    }
}
