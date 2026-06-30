// Pure path normalization. No Foundation, no I/O.
//
// Resolves "." and ".." segments and collapses redundant slashes so that
// traversal tricks cannot be used to disguise a protected path. Also canonical-
// izes the well-known macOS firmlink/symlink prefixes that matter for the
// safety blacklist (notably /var -> /private/var) so /var/vm and /private/var/vm
// are treated identically.

enum PathNormalize {

    /// Split an absolute path into normalized components, resolving `.`/`..`.
    /// Relative inputs are treated as rooted at "/" for classification purposes.
    static func components(_ path: String) -> [String] {
        var stack: [String] = []
        for raw in path.split(separator: "/", omittingEmptySubsequences: true) {
            let seg = String(raw)
            switch seg {
            case ".":
                continue
            case "..":
                if !stack.isEmpty { stack.removeLast() }
            default:
                stack.append(seg)
            }
        }
        return stack
    }

    /// Normalize to a canonical absolute path string (always leading "/", no
    /// trailing slash except root), with macOS symlink prefixes canonicalized.
    static func normalize(_ path: String) -> String {
        var comps = components(path)
        // Canonicalize /var, /tmp, /etc which are symlinks into /private.
        if let first = comps.first, ["var", "tmp", "etc"].contains(first) {
            comps.insert("private", at: 0)
        }
        return comps.isEmpty ? "/" : "/" + comps.joined(separator: "/")
    }

    /// True when `path`'s normalized components are equal to, or nested under,
    /// `prefix`'s components — matched component-wise so "/usrlocal" does NOT
    /// match prefix "/usr".
    static func isUnder(_ path: String, prefix: String) -> Bool {
        let p = components(normalize(path))
        let q = components(normalize(prefix))
        guard p.count >= q.count else { return false }
        return Array(p.prefix(q.count)) == q
    }
}
