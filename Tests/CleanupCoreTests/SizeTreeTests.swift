import Testing
@testable import CleanupCore

// Size roll-up (task 3.1): fold a flat set of FileRecords into a navigable tree
// whose directory sizes are the sum of their descendants' allocated sizes, with
// children ranked largest-first. Pure: no filesystem I/O.
//
// (Hardlink-counted-once is a scanner-layer concern — see the scanner tests —
// since dedup needs device/inode, which the roll-up does not see.)

@Suite("Size roll-up tree")
struct SizeTreeTests {

    private func dir(_ p: String) -> FileRecord {
        FileRecord(path: p, isDirectory: true, isSymlink: false,
                   logicalSize: 0, allocatedSize: 0, modifiedAt: 0)
    }
    private func file(_ p: String, _ size: Int64) -> FileRecord {
        FileRecord(path: p, isDirectory: false, isSymlink: false,
                   logicalSize: size, allocatedSize: size, modifiedAt: 0)
    }

    @Test("parent size equals the sum of descendant allocated sizes")
    func parentIsSumOfDescendants() {
        let records = [
            dir("/r"),
            dir("/r/a"), file("/r/a/x", 100), file("/r/a/y", 50),
            dir("/r/b"), file("/r/b/z", 25),
        ]
        let root = SizeTree.build(from: records, root: "/r")
        #expect(root.size == 175)
        let a = root.children.first { $0.path == "/r/a" }
        let b = root.children.first { $0.path == "/r/b" }
        #expect(a?.size == 150)
        #expect(b?.size == 25)
    }

    @Test("children are ranked largest-first")
    func childrenRankedBySize() {
        let records = [
            dir("/r"),
            dir("/r/small"), file("/r/small/f", 10),
            dir("/r/big"), file("/r/big/f", 1000),
            dir("/r/mid"), file("/r/mid/f", 100),
        ]
        let root = SizeTree.build(from: records, root: "/r")
        #expect(root.children.map(\.path) == ["/r/big", "/r/mid", "/r/small"])
    }

    @Test("Edge: empty root rolls up to zero")
    func emptyRootZero() {
        let root = SizeTree.build(from: [dir("/r")], root: "/r")
        #expect(root.size == 0)
        #expect(root.children.isEmpty)
    }

    @Test("Edge: deeply nested single chain sums correctly")
    func deepChain() {
        let records = [
            dir("/r"), dir("/r/a"), dir("/r/a/b"), file("/r/a/b/c", 42),
        ]
        let root = SizeTree.build(from: records, root: "/r")
        #expect(root.size == 42)
        #expect(root.children.first?.children.first?.children.first?.size == 42)
    }
}
