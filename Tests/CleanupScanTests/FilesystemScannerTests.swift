import Testing
import Foundation
@testable import CleanupScan
import CleanupCore

// Integration tests for the recursive scanner (tasks 5.1, 5.3). These touch a
// real temporary directory only — never the user's actual files.

@Suite("Filesystem scanner")
struct FilesystemScannerTests {

    // MARK: - fixture helpers

    private func makeTempDir() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("scan-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    private func write(_ dir: URL, _ name: String, bytes: Int) throws -> URL {
        let u = dir.appendingPathComponent(name)
        try Data(repeating: 0x41, count: bytes).write(to: u)
        return u
    }

    private func collect(root: URL,
                         isCancelled: @escaping () -> Bool = { false },
                         shouldPrune: @escaping (String) -> Bool = {
                             SafetyClassifier.classify($0).tier == .never
                         }) -> [FileRecord] {
        var out: [FileRecord] = []
        FilesystemScanner.walk(root: root.path, isCancelled: isCancelled, shouldPrune: shouldPrune) {
            out.append($0)
        }
        return out
    }

    // MARK: - 5.1 enumeration

    @Test("nested files and folders are enumerated with sizes")
    func enumeratesNested() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }
        let a = root.appendingPathComponent("a")
        try FileManager.default.createDirectory(at: a, withIntermediateDirectories: true)
        _ = try write(a, "x.bin", bytes: 4096)
        _ = try write(root, "y.bin", bytes: 8192)

        let records = collect(root: root)
        let tree = SizeTree.build(from: records, root: root.path)
        // total allocated rolls up the two files (allocated >= logical bytes)
        #expect(tree.size >= 4096 + 8192)
        #expect(records.contains { $0.path.hasSuffix("/a/x.bin") })
        #expect(records.contains { $0.path.hasSuffix("/y.bin") })
    }

    @Test("empty root reports zero descendant size")
    func emptyRoot() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }
        let records = collect(root: root)
        let tree = SizeTree.build(from: records, root: root.path)
        #expect(tree.size == 0)
    }

    @Test("unreadable directory is skipped, not fatal")
    func unreadableSkipped() throws {
        let root = try makeTempDir()
        defer {
            // restore perms so cleanup can remove it
            try? FileManager.default.setAttributes([.posixPermissions: 0o755],
                ofItemAtPath: root.appendingPathComponent("locked").path)
            try? FileManager.default.removeItem(at: root)
        }
        _ = try write(root, "ok.bin", bytes: 1024)
        let locked = root.appendingPathComponent("locked")
        try FileManager.default.createDirectory(at: locked, withIntermediateDirectories: true)
        _ = try write(locked, "secret.bin", bytes: 4096)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: locked.path)

        // Should not crash; the readable file is still found.
        let records = collect(root: root)
        #expect(records.contains { $0.path.hasSuffix("/ok.bin") })
    }

    @Test("cancellation stops the walk promptly")
    func cancellation() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }
        for i in 0..<20 { _ = try write(root, "f\(i).bin", bytes: 128) }

        var count = 0
        var out: [FileRecord] = []
        FilesystemScanner.walk(root: root.path, isCancelled: { count >= 3 }) { rec in
            count += 1
            out.append(rec)
        }
        #expect(out.count < 20)
    }

    // MARK: - 5.3 safety rules

    @Test("symlinks are recorded but not followed")
    func symlinksNotFollowed() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }
        let real = root.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: real, withIntermediateDirectories: true)
        _ = try write(real, "inside.bin", bytes: 2048)
        let link = root.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)

        let records = collect(root: root)
        // the symlink node exists, but its target's contents are not enumerated
        // *through* the link path
        #expect(records.contains { $0.path.hasSuffix("/link") && $0.isSymlink })
        #expect(!records.contains { $0.path.hasSuffix("/link/inside.bin") })
    }

    @Test("symlink loop does not hang")
    func symlinkLoop() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }
        let a = root.appendingPathComponent("a")
        let b = root.appendingPathComponent("b")
        try FileManager.default.createSymbolicLink(at: a, withDestinationURL: b)
        try FileManager.default.createSymbolicLink(at: b, withDestinationURL: a)
        // Completes without infinite recursion.
        let records = collect(root: root)
        #expect(records.count >= 2)
    }

    @Test("hardlinked file is counted once")
    func hardlinkOnce() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }
        let original = try write(root, "orig.bin", bytes: 4096)
        let hardlink = root.appendingPathComponent("dup.bin")
        try FileManager.default.linkItem(at: original, to: hardlink)

        let records = collect(root: root)
        let tree = SizeTree.build(from: records, root: root.path)
        // counted once: total ~ one file's allocated size, not two
        #expect(tree.size < 4096 * 2)
        #expect(tree.size >= 4096)
    }

    @Test("pruned subtree is not descended")
    func prunePruned() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }
        let skip = root.appendingPathComponent("skip")
        try FileManager.default.createDirectory(at: skip, withIntermediateDirectories: true)
        _ = try write(skip, "hidden.bin", bytes: 9999)
        _ = try write(root, "visible.bin", bytes: 100)

        let records = collect(root: root, shouldPrune: { $0.hasSuffix("/skip") })
        #expect(records.contains { $0.path.hasSuffix("/visible.bin") })
        #expect(!records.contains { $0.path.hasSuffix("/hidden.bin") })
    }
}
