import Foundation
import CleanupCore

// Deletion executor (imperative shell). Removes a plan's items, defending the
// "never touch protected paths" rule a second time: every item is re-classified
// immediately before removal and refused if it resolves to `NEVER`, regardless
// of the plan. Failures are per-item and non-fatal — the batch continues.
//
// Trash/remove are injectable so the logic can be tested hermetically without
// touching the real Trash.

public struct DeletionExecutor: Sendable {

    /// Outcome of attempting to remove one item.
    public enum Outcome: Equatable, Sendable {
        case trashed
        case deleted
        case failed(String)
        case refused(String)
    }

    public struct ItemResult: Equatable, Sendable {
        public let path: String
        public let outcome: Outcome
        public init(path: String, outcome: Outcome) {
            self.path = path
            self.outcome = outcome
        }
    }

    private let trashItem: @Sendable (URL) throws -> Void
    private let removeItem: @Sendable (URL) throws -> Void

    public init(
        trashItem: @escaping @Sendable (URL) throws -> Void = { url in
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        },
        removeItem: @escaping @Sendable (URL) throws -> Void = { url in
            try FileManager.default.removeItem(at: url)
        }
    ) {
        self.trashItem = trashItem
        self.removeItem = removeItem
    }

    /// Execute a plan, returning one result per item. Never throws.
    public func execute(_ plan: DeletionPlan) -> [ItemResult] {
        plan.items.map { remove($0) }
    }

    private func remove(_ item: DeletionItem) -> ItemResult {
        // Defense in depth: re-classify and refuse protected paths, whatever the
        // plan claimed.
        if SafetyClassifier.classify(item.path).tier == .never {
            return ItemResult(path: item.path,
                              outcome: .refused("Protected (NEVER) — refused at execution."))
        }
        // Tolerate a vanished item (race between scan and delete).
        guard FileManager.default.fileExists(atPath: item.path) else {
            return ItemResult(path: item.path, outcome: .failed("Item no longer exists."))
        }

        let url = URL(fileURLWithPath: item.path)
        do {
            switch item.mode {
            case .trash:
                try trashItem(url)
                return ItemResult(path: item.path, outcome: .trashed)
            case .permanent:
                try removeItem(url)
                return ItemResult(path: item.path, outcome: .deleted)
            }
        } catch {
            // Never silently fall back from trash to permanent — just report.
            return ItemResult(path: item.path, outcome: .failed(error.localizedDescription))
        }
    }
}
