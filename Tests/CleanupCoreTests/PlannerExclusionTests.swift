import Testing
@testable import CleanupCore

// Planner refuses user-excluded paths (tasks 2.1, 2.3). Pure: no I/O.

@Suite("Planner — user exclusions")
struct PlannerExclusionTests {

    private let home = "/Users/calvin"
    private func sel(_ p: String, _ s: Int64) -> SelectedPath { SelectedPath(path: p, allocatedSize: s) }

    @Test("a user-excluded path is refused with a user-protected reason")
    func refusesExcluded() {
        var ex = ExclusionSet(); ex.insert("\(home)/Projects")
        let plan = DeletionPlanner.plan(
            selecting: [sel("\(home)/Projects/build", 1000), sel("\(home)/.Trash/x", 50)],
            mode: .trash, excluded: ex)
        #expect(plan.items.count == 1)                         // only the Trash item remains
        #expect(plan.items.first?.path == "\(home)/.Trash/x")
        let refused = plan.refused.first { $0.path == "\(home)/Projects/build" }
        #expect(refused != nil)
        #expect(refused?.reason.lowercased().contains("you") == true)  // user-protected wording
    }

    @Test("a NEVER path keeps the system-protected reason, not the user one")
    func neverKeepsSystemReason() {
        var ex = ExclusionSet(); ex.insert("/System")  // even if user also 'excludes' it
        let plan = DeletionPlanner.plan(selecting: [sel("/System/x", 1)], mode: .trash, excluded: ex)
        #expect(plan.items.isEmpty)
        let r = plan.refused.first
        #expect(r?.tier == .never)
        #expect(r?.reason.lowercased().contains("sip") == true)  // system reason, not user wording
    }

    @Test("Edge: an all-excluded selection yields an empty plan")
    func allExcludedEmpty() {
        var ex = ExclusionSet(); ex.insert("\(home)/A"); ex.insert("\(home)/B")
        let plan = DeletionPlanner.plan(
            selecting: [sel("\(home)/A/x", 1), sel("\(home)/B/y", 2)], mode: .trash, excluded: ex)
        #expect(plan.isEmpty)
    }

    @Test("Edge: default (no exclusions) preserves prior behavior")
    func defaultUnchanged() {
        let plan = DeletionPlanner.plan(selecting: [sel("\(home)/.Trash/x", 10)], mode: .trash)
        #expect(plan.items.count == 1)
    }

    // 2.3 invariants
    @Test("invariant: no plan contains a NEVER item, for any exclusion set",
          arguments: ["/System/x", "/bin/sh", "/private/var/vm/swapfile"])
    func neverNeverPlanned(path: String) {
        var ex = ExclusionSet(); ex.insert(path)  // exclusions must not change NEVER handling
        let plan = DeletionPlanner.plan(selecting: [SelectedPath(path: path, allocatedSize: 9)],
                                        mode: .permanent, excluded: ex)
        #expect(plan.items.isEmpty)
        #expect(plan.items.allSatisfy { $0.tier != .never })
    }
}
