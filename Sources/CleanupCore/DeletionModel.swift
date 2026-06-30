// Deletion plan value types — pure data, no I/O.
//
// A `DeletionPlan` is the mandatory gate between a user selection and the
// executor: it lists exactly what will be removed, what was refused (and why),
// and totals the reclaimable bytes. It is produced by the pure planner and is
// the only thing the executor accepts.

/// How an item is to be removed.
public enum DeletionMode: Sendable, Equatable {
    /// Reversible: moved to the Trash (the default).
    case trash
    /// Irreversible: removed permanently (explicit opt-in only).
    case permanent
}

/// One item slated for removal.
public struct DeletionItem: Equatable, Sendable {
    public let path: String
    public let tier: SafetyTier
    public let allocatedSize: Int64
    public let mode: DeletionMode

    public init(path: String, tier: SafetyTier, allocatedSize: Int64, mode: DeletionMode) {
        self.path = path
        self.tier = tier
        self.allocatedSize = allocatedSize
        self.mode = mode
    }
}

/// An item that was excluded from the plan and will never be removed.
public struct RefusedItem: Equatable, Sendable {
    public let path: String
    public let tier: SafetyTier
    public let reason: String

    public init(path: String, tier: SafetyTier, reason: String) {
        self.path = path
        self.tier = tier
        self.reason = reason
    }
}

/// A validated removal plan: removable items, refusals, and aggregates.
public struct DeletionPlan: Equatable, Sendable {
    public let items: [DeletionItem]
    public let refused: [RefusedItem]
    public let mode: DeletionMode

    public init(items: [DeletionItem], refused: [RefusedItem], mode: DeletionMode) {
        self.items = items
        self.refused = refused
        self.mode = mode
    }

    /// Total reclaimable bytes across removable items.
    public var reclaimableTotal: Int64 {
        items.reduce(0) { $0 + $1.allocatedSize }
    }

    /// Reclaimable bytes grouped by safety tier.
    public var perTierTotals: [SafetyTier: Int64] {
        var totals: [SafetyTier: Int64] = [:]
        for item in items {
            totals[item.tier, default: 0] += item.allocatedSize
        }
        return totals
    }

    /// True when there is nothing to remove (a no-op).
    public var isEmpty: Bool { items.isEmpty }
}
