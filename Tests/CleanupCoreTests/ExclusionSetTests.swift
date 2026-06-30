import Testing
@testable import CleanupCore

// User exclusion set (task 1.1): pure, ancestor-aware membership. No I/O.

@Suite("Exclusion set")
struct ExclusionSetTests {

    @Test("a protected path is contained")
    func containsAdded() {
        var set = ExclusionSet()
        set.insert("/Users/calvin/Projects/secret")
        #expect(set.contains("/Users/calvin/Projects/secret"))
    }

    @Test("a descendant of a protected folder is contained")
    func ancestorAware() {
        var set = ExclusionSet()
        set.insert("/Users/calvin/Projects")
        #expect(set.contains("/Users/calvin/Projects/app/build/out.o"))
    }

    @Test("removing a path makes it no longer contained")
    func removeWorks() {
        var set = ExclusionSet(["/Users/calvin/Projects"])
        set.remove("/Users/calvin/Projects")
        #expect(!set.contains("/Users/calvin/Projects/app"))
    }

    @Test("Edge: an unrelated path is not contained")
    func unrelatedNotContained() {
        let set = ExclusionSet(["/Users/calvin/Projects"])
        #expect(!set.contains("/Users/calvin/Downloads/x"))
        #expect(!set.contains("/Users/calvin"))   // a parent is not excluded by a child
    }

    @Test("Edge: adding a duplicate (or normalized-equal) path is idempotent")
    func idempotentAdd() {
        var set = ExclusionSet()
        set.insert("/Users/calvin/Projects")
        set.insert("/Users/calvin/Projects/")     // trailing slash normalizes equal
        set.insert("/Users/calvin/./Projects")    // normalizes equal
        #expect(set.all.count == 1)
    }
}
