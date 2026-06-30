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
}
