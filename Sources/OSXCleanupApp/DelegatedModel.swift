import Foundation
import Observation
import CleanupCore
import CleanupScan

// View model for delegated cleanup (M3). Detects installed tools, lists APFS
// snapshots, and runs vetted commands off the main thread.

@MainActor
@Observable
final class DelegatedModel {

    struct ProviderRow: Identifiable {
        let provider: DelegatedProvider
        var installed: Bool
        var running = false
        var preview: String?
        var result: DelegatedResult?
        var id: String { provider.id }
    }

    var rows: [ProviderRow] = []
    var snapshots: [String] = []
    var snapshotBusy = false
    var snapshotMessage: String?

    private let runner = DelegatedRunner()
    private let snapshotMgr = SnapshotManager()

    /// Detect installed tools and list snapshots.
    func refresh() {
        let r = runner
        rows = DelegatedProviders.all.map {
            ProviderRow(provider: $0, installed: r.isInstalled($0))
        }
        refreshSnapshots()
    }

    func refreshSnapshots() {
        let mgr = snapshotMgr
        Task {
            snapshots = await Task.detached(priority: .userInitiated) { mgr.list() }.value
        }
    }

    func preview(_ id: String) async {
        guard let i = rows.firstIndex(where: { $0.id == id }), rows[i].installed else { return }
        let provider = rows[i].provider
        let r = runner
        rows[i].running = true
        let result = await Task.detached(priority: .userInitiated) { r.dryRun(provider) }.value
        rows[i].running = false
        rows[i].preview = describe(result)
    }

    func cleanup(_ id: String) async {
        guard let i = rows.firstIndex(where: { $0.id == id }), rows[i].installed else { return }
        let provider = rows[i].provider
        let r = runner
        rows[i].running = true
        let result = await Task.detached(priority: .userInitiated) { r.cleanup(provider) }.value
        rows[i].running = false
        rows[i].result = result
    }

    func deleteSnapshot(_ date: String) async {
        let mgr = snapshotMgr
        snapshotBusy = true
        let result = await Task.detached(priority: .userInitiated) { mgr.delete(date: date) }.value
        snapshotBusy = false
        snapshotMessage = result == nil ? "Refused: invalid snapshot date." : "Snapshot deleted."
        refreshSnapshots()
    }

    func thin(gigabytes: Int) async {
        let mgr = snapshotMgr
        let bytes = Int64(gigabytes) * 1_000_000_000
        snapshotBusy = true
        _ = await Task.detached(priority: .userInitiated) { mgr.thin(bytes: bytes, urgency: 4) }.value
        snapshotBusy = false
        snapshotMessage = "Requested thinning to free ~\(gigabytes) GB."
        refreshSnapshots()
    }

    private func describe(_ result: CommandRunner.Result?) -> String {
        switch result {
        case .none: return "No preview available for this tool."
        case .success(let o): return o.stdout.isEmpty ? "Nothing to clean." : o.stdout
        case .failure(let o): return o.stderr.isEmpty ? "Preview failed." : o.stderr
        case .timedOut: return "Preview timed out."
        case .cancelled: return "Preview cancelled."
        }
    }
}
