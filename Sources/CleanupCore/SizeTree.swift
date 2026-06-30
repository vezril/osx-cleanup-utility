// Size roll-up — pure, no I/O.
//
// Folds a flat set of FileRecords into a navigable tree. A directory's `size`
// is the sum of its descendants' allocated sizes; children are ranked
// largest-first so the heaviest space users surface immediately.

/// A node in the rolled-up size tree.
public struct SizeNode: Equatable, Sendable {
    public let path: String
    public let name: String
    public let isDirectory: Bool
    /// Rolled-up allocated size: own size for a file, sum of descendants for a
    /// directory.
    public let size: Int64
    /// Child nodes, sorted by `size` descending (ties broken by path).
    public let children: [SizeNode]

    public init(path: String, name: String, isDirectory: Bool, size: Int64, children: [SizeNode]) {
        self.path = path
        self.name = name
        self.isDirectory = isDirectory
        self.size = size
        self.children = children
    }
}

public enum SizeTree {

    /// Build a size tree rooted at `root` from a flat record set.
    public static func build(from records: [FileRecord], root: String) -> SizeNode {
        let rootKey = PathNormalize.normalize(root)

        // Index records by normalized path, and group child paths by parent.
        var byPath: [String: FileRecord] = [:]
        var childrenOf: [String: [String]] = [:]
        for r in records {
            let key = PathNormalize.normalize(r.path)
            byPath[key] = r
            guard key != rootKey else { continue }
            let parent = parentPath(key)
            childrenOf[parent, default: []].append(key)
        }

        return node(at: rootKey, byPath: byPath, childrenOf: childrenOf)
    }

    private static func node(
        at key: String,
        byPath: [String: FileRecord],
        childrenOf: [String: [String]]
    ) -> SizeNode {
        let record = byPath[key]
        let isDir = record?.isDirectory ?? true
        let ownSize: Int64 = (record.map { $0.isDirectory ? 0 : $0.allocatedSize }) ?? 0

        let childNodes = (childrenOf[key] ?? [])
            .map { node(at: $0, byPath: byPath, childrenOf: childrenOf) }
            .sorted { ($0.size, $1.path) > ($1.size, $0.path) }

        let total = ownSize + childNodes.reduce(0) { $0 + $1.size }
        return SizeNode(
            path: key,
            name: lastComponent(key),
            isDirectory: isDir,
            size: total,
            children: childNodes
        )
    }

    static func parentPath(_ normalized: String) -> String {
        var comps = PathNormalize.components(normalized)
        guard !comps.isEmpty else { return "/" }
        comps.removeLast()
        return comps.isEmpty ? "/" : "/" + comps.joined(separator: "/")
    }

    static func lastComponent(_ normalized: String) -> String {
        PathNormalize.components(normalized).last ?? "/"
    }
}
