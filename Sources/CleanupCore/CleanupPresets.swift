// Curated cleanup presets — pure definitions + resolution.
//
// A preset is a named set of candidate paths (relative to the user home) for a
// known-safe category. Resolution keeps only candidates that (a) exist (via an
// injected predicate, so this stays pure and testable) and (b) classify as
// `SAFE` or `CACHE` — never `RISKY`, `DELEGATED`, or `NEVER`. Sizes are filled
// in later from a scan.

public struct CleanupPreset: Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    /// Candidate paths relative to the user's home directory.
    public let candidates: [String]

    public init(id: String, name: String, candidates: [String]) {
        self.id = id
        self.name = name
        self.candidates = candidates
    }
}

public enum CleanupPresets {

    /// The built-in curated presets. Every candidate is expected to classify
    /// `SAFE`/`CACHE`; resolution enforces it defensively regardless.
    public static let all: [CleanupPreset] = [
        CleanupPreset(id: "trash", name: "Empty Trash",
                      candidates: [".Trash"]),
        CleanupPreset(id: "xcode-derived", name: "Xcode DerivedData",
                      candidates: ["Library/Developer/Xcode/DerivedData"]),
        CleanupPreset(id: "user-caches", name: "User Caches",
                      candidates: ["Library/Caches"]),
        CleanupPreset(id: "dev-caches", name: "Developer Caches",
                      candidates: ["Library/Developer/Xcode/iOS DeviceSupport",
                                   "Library/Developer/CoreSimulator"]),
    ]

    /// Resolve a preset to absolute paths that exist and are safe to surface.
    public static func resolve(
        _ preset: CleanupPreset,
        home: String,
        exists: (String) -> Bool
    ) -> [String] {
        preset.candidates.compactMap { candidate in
            let full = home + "/" + candidate
            guard exists(full) else { return nil }
            let tier = SafetyClassifier.classify(full).tier
            return (tier == .safe || tier == .cache) ? full : nil
        }
    }
}
