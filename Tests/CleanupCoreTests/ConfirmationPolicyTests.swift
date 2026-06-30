import Testing
@testable import CleanupCore

// Confirmation policy (tasks 2.1, 2.3): the required confirmation strength is a
// pure function of the plan's highest tier, escalated for permanent deletion.

@Suite("Confirmation policy")
struct ConfirmationPolicyTests {

    private func item(_ tier: SafetyTier) -> DeletionItem {
        DeletionItem(path: "/p/\(tier.rawValue)", tier: tier, allocatedSize: 1, mode: .trash)
    }
    private func plan(_ tiers: [SafetyTier], mode: DeletionMode = .trash) -> DeletionPlan {
        DeletionPlan(items: tiers.map { item($0) }, refused: [], mode: mode)
    }

    @Test("safe-only trash plan requires a simple confirmation")
    func safeSimple() {
        #expect(ConfirmationPolicy.requiredConfirmation(plan([.safe])) == .simple)
    }

    @Test("cache plan requires a warning confirmation")
    func cacheWarning() {
        #expect(ConfirmationPolicy.requiredConfirmation(plan([.cache])) == .warning)
    }

    @Test("highest tier wins — mixed cache+risky requires type-to-confirm")
    func highestWins() {
        #expect(ConfirmationPolicy.requiredConfirmation(plan([.cache, .risky])) == .typeToConfirm)
    }

    @Test("Edge: empty plan requires no confirmation (no-op)")
    func emptyNone() {
        #expect(ConfirmationPolicy.requiredConfirmation(plan([])) == .none)
    }

    @Test("permanent mode escalates the level by one step vs trash")
    func permanentEscalates() {
        let trash = ConfirmationPolicy.requiredConfirmation(plan([.safe], mode: .trash))
        let perm  = ConfirmationPolicy.requiredConfirmation(plan([.safe], mode: .permanent))
        #expect(trash == .simple)
        #expect(perm == .warning)        // escalated one step
        #expect(perm > trash)
    }

    @Test("Edge: escalation is capped at type-to-confirm")
    func escalationCapped() {
        let perm = ConfirmationPolicy.requiredConfirmation(plan([.risky], mode: .permanent))
        #expect(perm == .typeToConfirm)  // already max; stays there
    }
}
