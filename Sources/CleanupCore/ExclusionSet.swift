// User exclusion set — pure, ancestor-aware. No I/O.
//
// A user-curated set of personally protected paths. Membership is ancestor-
// aware: a path is excluded if it equals, or is nested under, any member, so
// protecting a folder protects everything inside it. Paths are normalized on
// insert so trailing slashes / `.` / `..` cannot create duplicates or bypass
// membership. `Codable` for persistence.

public struct ExclusionSet: Equatable, Sendable, Codable {
    private var paths: Set<String>

    public init(_ paths: [String] = []) {
        self.paths = Set(paths.map(PathNormalize.normalize))
    }

    /// The protected paths, sorted for stable presentation.
    public var all: [String] { paths.sorted() }

    public var isEmpty: Bool { paths.isEmpty }

    public mutating func insert(_ path: String) {
        paths.insert(PathNormalize.normalize(path))
    }

    public mutating func remove(_ path: String) {
        paths.remove(PathNormalize.normalize(path))
    }

    /// True if `path` equals, or is nested under, any member of the set.
    public func contains(_ path: String) -> Bool {
        let target = PathNormalize.normalize(path)
        if paths.contains(target) { return true }
        return paths.contains { member in PathNormalize.isUnder(target, prefix: member) }
    }
}
