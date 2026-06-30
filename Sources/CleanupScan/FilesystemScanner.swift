import Foundation
import CleanupCore

// Recursive filesystem scanner (imperative shell).
//
// Walks a directory tree depth-first, emitting an immutable `FileRecord` per
// entry. Safety properties (design D6):
//   • symlinks are recorded but never traversed (no cycles, no double-count)
//   • hardlinked inodes are counted once (subsequent links emit allocated 0)
//   • `never`-tier / blacklisted subtrees are pruned — never descended
//   • permission-denied / vanished entries are skipped, never fatal
//   • a cancellation check is honoured between entries
//
// Sizes come from `lstat`: `st_size` (logical) and `st_blocks * 512` (allocated,
// the real on-disk footprint — what reclaiming frees).

public enum FilesystemScanner {

    /// Walk `root`, calling `emit` for each entry. Synchronous and testable;
    /// the app wraps this in a Task to stream results and stay responsive.
    ///
    /// - Parameters:
    ///   - shouldPrune: returns true for a directory whose subtree must not be
    ///     descended (default: anything the classifier rates `never`).
    public static func walk(
        root: String,
        isCancelled: () -> Bool = { false },
        shouldPrune: (String) -> Bool = { SafetyClassifier.classify($0).tier == .never },
        emit: (FileRecord) -> Void
    ) {
        var seenInodes = Set<InodeKey>()
        // Emit the root itself, then descend.
        if let record = makeRecord(path: root, seen: &seenInodes) {
            emit(record)
            if record.isDirectory, !record.isSymlink, !shouldPrune(root) {
                descend(root, isCancelled: isCancelled, shouldPrune: shouldPrune,
                        seen: &seenInodes, emit: emit)
            }
        }
    }

    // MARK: - private

    private struct InodeKey: Hashable { let device: Int; let inode: UInt64 }

    private static func descend(
        _ dir: String,
        isCancelled: () -> Bool,
        shouldPrune: (String) -> Bool,
        seen: inout Set<InodeKey>,
        emit: (FileRecord) -> Void
    ) {
        guard !isCancelled() else { return }
        // contentsOfDirectory does not follow symlinks (returns entry names).
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir) else {
            return // unreadable (permission denied) or vanished — skip, not fatal
        }
        for name in names {
            if isCancelled() { return }
            let full = dir.hasSuffix("/") ? dir + name : dir + "/" + name
            guard let record = makeRecord(path: full, seen: &seen) else { continue }
            emit(record)
            if record.isDirectory, !record.isSymlink, !shouldPrune(full) {
                descend(full, isCancelled: isCancelled, shouldPrune: shouldPrune,
                        seen: &seen, emit: emit)
            }
        }
    }

    /// Build a record via `lstat` (does not follow the final symlink). Returns
    /// nil if the entry cannot be stat'd (vanished / permission denied).
    private static func makeRecord(path: String, seen: inout Set<InodeKey>) -> FileRecord? {
        var st = stat()
        guard lstat(path, &st) == 0 else { return nil }

        let isSymlink = (st.st_mode & S_IFMT) == S_IFLNK
        let isDir = (st.st_mode & S_IFMT) == S_IFDIR
        let logical = Int64(st.st_size)
        var allocated = Int64(st.st_blocks) * 512

        // Count a hardlinked regular file's footprint only once.
        if !isDir, st.st_nlink > 1 {
            let key = InodeKey(device: Int(st.st_dev), inode: UInt64(st.st_ino))
            if seen.contains(key) {
                allocated = 0
            } else {
                seen.insert(key)
            }
        }

        return FileRecord(
            path: path,
            isDirectory: isDir,
            isSymlink: isSymlink,
            logicalSize: logical,
            allocatedSize: allocated,
            modifiedAt: Int64(st.st_mtimespec.tv_sec)
        )
    }
}
