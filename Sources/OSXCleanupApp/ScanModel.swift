import Foundation
import Observation
import CleanupCore
import CleanupScan

// View model wiring the pure core to the UI: pick a root → scan (off the main
// thread) → roll up → expose a navigable, classifiable tree. Read-only.

/// Thread-safe cancellation flag shared with the background scan.
final class CancelToken: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    var isCancelled: Bool { lock.withLock { cancelled } }
    func cancel() { lock.withLock { cancelled = true } }
}

@MainActor
@Observable
final class ScanModel {
    enum Phase: Equatable { case idle, scanning, done }

    var phase: Phase = .idle
    var rootTree: SizeNode?
    /// Drill-down breadcrumb; the current node is `path.last ?? rootTree`.
    var path: [SizeNode] = []
    var selected: SizeNode?
    var fda: FullDiskAccess.Status = .notGranted
    var scannedCount = 0
    var rootPath: String = ""

    private var token = CancelToken()

    var current: SizeNode? { path.last ?? rootTree }

    /// Re-evaluate Full Disk Access state (call on appear and after returning
    /// from Settings).
    func refreshFDA() { fda = FullDiskAccess.detect() }

    /// Scan `rootPath`, build the size tree, and reset navigation.
    func scan(rootPath: String) async {
        self.rootPath = rootPath
        phase = .scanning
        scannedCount = 0
        selected = nil
        path = []
        let token = CancelToken()
        self.token = token

        let records: [FileRecord] = await Task.detached(priority: .userInitiated) {
            var out: [FileRecord] = []
            FilesystemScanner.walk(root: rootPath, isCancelled: { token.isCancelled }) {
                out.append($0)
            }
            return out
        }.value

        rootTree = SizeTree.build(from: records, root: rootPath)
        indexSizes()
        scannedCount = records.count
        phase = .done
    }

    func cancel() { token.cancel() }

    /// Classify a node (pure, cheap) for coloring and the inspector.
    func classification(_ node: SizeNode) -> Classification {
        SafetyClassifier.classify(node.path)
    }

    func select(_ node: SizeNode) { selected = node }

    func drill(into node: SizeNode) {
        selected = node
        if node.isDirectory && !node.children.isEmpty {
            path.append(node)
        }
    }

    func drillOut() {
        if !path.isEmpty { path.removeLast() }
        selected = nil
    }

    func resetToRoot() {
        path = []
        selected = nil
    }

    // MARK: - Deletion (M2)

    /// Paths selected for deletion, mapped to their allocated size.
    var deletionSelection: [String: Int64] = [:]
    /// Lookup of every scanned path → rolled-up size, for presets and totals.
    private var sizeIndex: [String: Int64] = [:]
    var mode: DeletionMode = .trash
    var plan: DeletionPlan?
    var showingPlan = false
    var results: [DeletionExecutor.ItemResult]?
    var showingResults = false

    /// Shared persisted state (exclusions + history), injected by ContentView.
    var appState: AppStateModel?

    func isProtected(_ node: SizeNode) -> Bool { appState?.isProtected(node.path) ?? false }
    func toggleProtect(_ node: SizeNode) {
        guard let appState else { return }
        if appState.isProtected(node.path) { appState.removeExclusion(node.path) }
        else { appState.addExclusion(node.path) }
    }

    func isMarkedForDeletion(_ node: SizeNode) -> Bool {
        deletionSelection[node.path] != nil
    }

    /// Toggle a node's membership in the deletion selection. `NEVER` nodes can
    /// never be marked.
    func toggleDeletion(_ node: SizeNode) {
        guard classification(node).tier != .never else { return }
        if deletionSelection[node.path] != nil {
            deletionSelection[node.path] = nil
        } else {
            deletionSelection[node.path] = node.size
        }
    }

    var selectedReclaimable: Int64 { deletionSelection.values.reduce(0, +) }

    func clearDeletionSelection() { deletionSelection = [:] }

    /// Add a curated preset's resolved paths to the deletion selection.
    func applyPreset(_ preset: CleanupPreset) {
        let resolved = CleanupPresets.resolve(
            preset, home: NSHomeDirectory(),
            exists: { FileManager.default.fileExists(atPath: $0) })
        for p in resolved {
            deletionSelection[p] = sizeIndex[p] ?? 0
        }
    }

    /// Build the deletion plan from the current selection and show the preview.
    func buildPlan() {
        let selection = deletionSelection.map { SelectedPath(path: $0.key, allocatedSize: $0.value) }
        let excluded = appState?.effectiveExclusions ?? ExclusionSet()
        plan = DeletionPlanner.plan(selecting: selection, mode: mode, excluded: excluded)
        showingPlan = true
    }

    /// Rebuild the plan when the Trash/Permanent mode changes while previewing.
    func updateMode(_ newMode: DeletionMode) {
        mode = newMode
        if showingPlan { buildPlan() }
    }

    var requiredConfirmation: ConfirmationLevel {
        plan.map { ConfirmationPolicy.requiredConfirmation($0) } ?? .none
    }

    /// Execute the current plan, then rescan and clear the selection.
    func executePlan() async {
        guard let plan else { return }
        let exec = DeletionExecutor()
        let outcome = await Task.detached(priority: .userInitiated) {
            exec.execute(plan)
        }.value
        results = outcome
        // Record this cleanup in the persisted history.
        var counts: [String: Int] = [:]
        for r in outcome {
            switch r.outcome {
            case .trashed: counts["trashed", default: 0] += 1
            case .deleted: counts["deleted", default: 0] += 1
            case .failed: counts["failed", default: 0] += 1
            case .refused: counts["refused", default: 0] += 1
            }
        }
        appState?.record(kind: .fileDeletion, itemCount: plan.items.count,
                         reclaimedBytes: plan.reclaimableTotal, outcomeCounts: counts)
        showingPlan = false
        showingResults = true
        clearDeletionSelection()
        await scan(rootPath: rootPath)
    }

    /// Build the path→size index by walking the rolled-up tree.
    func indexSizes() {
        var index: [String: Int64] = [:]
        func walk(_ node: SizeNode) {
            index[node.path] = node.size
            for child in node.children { walk(child) }
        }
        if let rootTree { walk(rootTree) }
        sizeIndex = index
    }
}
