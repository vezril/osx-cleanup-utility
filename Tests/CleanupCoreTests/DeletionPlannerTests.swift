import Testing
@testable import CleanupCore

// The pure deletion planner (tasks 1.3, 1.5, 1.7) — the gate every removal must
// pass. No filesystem I/O.

@Suite("Deletion planner")
struct DeletionPlannerTests {

    private let home = "/Users/calvin"

    private func sel(_ path: String, _ size: Int64) -> SelectedPath {
        SelectedPath(path: path, allocatedSize: size)
    }

    // MARK: - 1.3 basic planning

    @Test("plan lists removable items with tier and size, and totals them")
    func listsAndTotals() {
        let plan = DeletionPlanner.plan(selecting: [
            sel("\(home)/.Trash/old.dmg", 1000),
            sel("\(home)/Library/Caches/app", 500),
        ], mode: .trash)
        #expect(plan.items.count == 2)
        #expect(plan.reclaimableTotal == 1500)
        #expect(plan.items.allSatisfy { $0.mode == .trash })
        #expect(plan.items.contains { $0.tier == .safe })
        #expect(plan.items.contains { $0.tier == .cache })
    }

    @Test("NEVER/blacklisted paths are refused, never planned")
    func refusesNever() {
        let plan = DeletionPlanner.plan(selecting: [
            sel("/System/Library/CoreServices", 9999),
            sel("\(home)/Library/Caches/app", 500),
        ], mode: .trash)
        #expect(plan.items.count == 1)
        #expect(plan.items.allSatisfy { $0.tier != .never })
        #expect(plan.refused.count == 1)
        #expect(plan.refused.first?.path == "/System/Library/CoreServices")
        #expect(plan.reclaimableTotal == 500)
    }

    @Test("Edge: empty selection yields a no-op plan")
    func emptySelection() {
        let plan = DeletionPlanner.plan(selecting: [], mode: .trash)
        #expect(plan.isEmpty)
    }

    @Test("Edge: selection of only NEVER paths yields no removable items")
    func allNever() {
        let plan = DeletionPlanner.plan(selecting: [
            sel("/System/a", 1), sel("/bin/sh", 2),
        ], mode: .trash)
        #expect(plan.items.isEmpty)
        #expect(plan.refused.count == 2)
    }

    // MARK: - 1.5 de-duplication

    @Test("nested selection is de-duplicated to the ancestor")
    func dedupNested() {
        // The folder's rolled-up size (1000) already includes the child.
        let plan = DeletionPlanner.plan(selecting: [
            sel("\(home)/Library/Caches/app", 1000),
            sel("\(home)/Library/Caches/app/blob.bin", 400),
        ], mode: .trash)
        #expect(plan.items.count == 1)
        #expect(plan.items.first?.path == "\(home)/Library/Caches/app")
        #expect(plan.reclaimableTotal == 1000) // counted once, not 1400
    }

    @Test("Edge: siblings are both kept")
    func siblingsKept() {
        let plan = DeletionPlanner.plan(selecting: [
            sel("\(home)/Library/Caches/a", 100),
            sel("\(home)/Library/Caches/b", 200),
        ], mode: .trash)
        #expect(plan.items.count == 2)
        #expect(plan.reclaimableTotal == 300)
    }

    // MARK: - 1.7 invariant

    @Test("invariant: no plan ever contains a NEVER item",
          arguments: [
            "/System", "/usr/lib", "/bin/sh", "/sbin/x", "/private/var/vm/sleepimage",
            "/System/Library/Caches", "/var/vm/swapfile",
          ])
    func neverNeverPlanned(path: String) {
        let plan = DeletionPlanner.plan(selecting: [sel(path, 1234)], mode: .permanent)
        #expect(plan.items.isEmpty)
        #expect(plan.items.allSatisfy { $0.tier != .never })
    }
}
