// Confirmation policy — pure, no I/O.
//
// Friction scales with risk: the required confirmation strength is the highest
// tier present in the plan, escalated one step when deleting permanently. The
// UI just renders the returned level.

/// How strongly a deletion must be confirmed, ordered from weakest to strongest.
public enum ConfirmationLevel: Int, Comparable, Sendable {
    case none = 0          // nothing to confirm (empty plan)
    case simple = 1        // a plain confirm
    case warning = 2       // confirm + "will be regenerated" notice
    case typeToConfirm = 3 // user must type to confirm

    public static func < (lhs: ConfirmationLevel, rhs: ConfirmationLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum ConfirmationPolicy {

    /// The confirmation level required for a plan.
    public static func requiredConfirmation(_ plan: DeletionPlan) -> ConfirmationLevel {
        guard !plan.isEmpty else { return .none }
        let base = plan.items.map { level(for: $0.tier) }.max() ?? .simple
        return plan.mode == .permanent ? escalate(base) : base
    }

    /// Base level for a single tier. `NEVER` never reaches a plan.
    static func level(for tier: SafetyTier) -> ConfirmationLevel {
        switch tier {
        case .safe:      return .simple
        case .cache:     return .warning
        case .delegated: return .typeToConfirm // raw-deleting tool data is risky
        case .risky:     return .typeToConfirm
        case .never:     return .simple        // unreachable: refused before planning
        }
    }

    /// Move up one step, capped at the strongest level.
    static func escalate(_ level: ConfirmationLevel) -> ConfirmationLevel {
        ConfirmationLevel(rawValue: min(level.rawValue + 1, ConfirmationLevel.typeToConfirm.rawValue))
            ?? .typeToConfirm
    }
}
