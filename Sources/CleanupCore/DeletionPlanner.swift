// The deletion planner — pure gate, no I/O.
//
// Turns a user selection into a validated `DeletionPlan`:
//   • classifies each path; `NEVER`/blacklisted paths are refused, never planned
//   • de-duplicates nested selections (a selected ancestor subsumes descendants,
//     whose rolled-up size is already included — so bytes are counted once)
//   • totals the reclaimable bytes
//
// This is the single place where "what gets deleted" is decided, so the safety
// properties are assertable in unit tests (no plan ever contains a `NEVER`).

/// One selected path with its rolled-up allocated size.
public struct SelectedPath: Equatable, Sendable {
    public let path: String
    public let allocatedSize: Int64
    public init(path: String, allocatedSize: Int64) {
        self.path = path
        self.allocatedSize = allocatedSize
    }
}

public enum DeletionPlanner {

    public static func plan(selecting selection: [SelectedPath], mode: DeletionMode) -> DeletionPlan {
        var items: [DeletionItem] = []
        var refused: [RefusedItem] = []

        for entry in selection {
            let c = SafetyClassifier.classify(entry.path)
            if c.tier == .never {
                refused.append(RefusedItem(path: entry.path, tier: .never, reason: c.reason))
            } else {
                items.append(DeletionItem(path: entry.path, tier: c.tier,
                                          allocatedSize: entry.allocatedSize, mode: mode))
            }
        }

        items = deduplicateNested(items)
        return DeletionPlan(items: items, refused: refused, mode: mode)
    }

    /// Drop any item whose path is nested under another selected item's path,
    /// so an ancestor's removal subsumes its descendants without double-counting.
    static func deduplicateNested(_ items: [DeletionItem]) -> [DeletionItem] {
        items.filter { candidate in
            !items.contains { other in
                other.path != candidate.path &&
                PathNormalize.isUnder(candidate.path, prefix: other.path)
            }
        }
    }
}
