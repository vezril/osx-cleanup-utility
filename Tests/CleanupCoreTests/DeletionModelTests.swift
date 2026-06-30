import Testing
@testable import CleanupCore

// Deletion plan value types (task 1.1). Pure: no filesystem I/O.

@Suite("Deletion model")
struct DeletionModelTests {

    @Test("DeletionItem carries path, tier, size, and mode")
    func deletionItem() {
        let item = DeletionItem(path: "/u/x/Library/Caches/a", tier: .cache,
                                allocatedSize: 4096, mode: .trash)
        #expect(item.path == "/u/x/Library/Caches/a")
        #expect(item.tier == .cache)
        #expect(item.allocatedSize == 4096)
        #expect(item.mode == .trash)
    }

    @Test("DeletionMode has trash and permanent")
    func deletionMode() {
        #expect(DeletionMode.trash != DeletionMode.permanent)
    }

    @Test("DeletionPlan exposes items, refusals, totals, and per-tier breakdown")
    func deletionPlan() {
        let items = [
            DeletionItem(path: "/u/x/.Trash/a", tier: .safe, allocatedSize: 100, mode: .trash),
            DeletionItem(path: "/u/x/Library/Caches/b", tier: .cache, allocatedSize: 200, mode: .trash),
        ]
        let refused = [RefusedItem(path: "/System/x", tier: .never, reason: "SIP-protected")]
        let plan = DeletionPlan(items: items, refused: refused, mode: .trash)
        #expect(plan.reclaimableTotal == 300)
        #expect(plan.perTierTotals[.safe] == 100)
        #expect(plan.perTierTotals[.cache] == 200)
        #expect(plan.refused.count == 1)
        #expect(plan.isEmpty == false)
    }

    @Test("An empty plan is a no-op")
    func emptyPlan() {
        let plan = DeletionPlan(items: [], refused: [], mode: .trash)
        #expect(plan.isEmpty)
        #expect(plan.reclaimableTotal == 0)
    }
}
