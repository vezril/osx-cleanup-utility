import Testing
@testable import CleanupCore

// Curated presets (task 4.1). Resolution is pure: classification filters tiers,
// and existence is injected so the test needs no real filesystem.

@Suite("Cleanup presets")
struct CleanupPresetsTests {

    private let home = "/Users/calvin"

    @Test("a preset resolves only to SAFE/CACHE paths")
    func resolvesSafeOrCache() {
        for preset in CleanupPresets.all {
            let resolved = CleanupPresets.resolve(preset, home: home, exists: { _ in true })
            for path in resolved {
                let tier = SafetyClassifier.classify(path).tier
                #expect(tier == .safe || tier == .cache,
                        "\(path) resolved to \(tier) in preset \(preset.id)")
            }
        }
    }

    @Test("Edge: a risky/delegated/never candidate is filtered out")
    func filtersUnsafeCandidates() {
        let mixed = CleanupPreset(id: "test", name: "Test", candidates: [
            "Library/Caches",                 // cache → kept
            ".Trash",                         // safe → kept
            "Library/Application Support",    // risky → dropped
            "Library/Caches/Homebrew",        // delegated → dropped
        ])
        let resolved = CleanupPresets.resolve(mixed, home: home, exists: { _ in true })
        #expect(resolved.contains("\(home)/Library/Caches"))
        #expect(resolved.contains("\(home)/.Trash"))
        #expect(!resolved.contains("\(home)/Library/Application Support"))
        #expect(!resolved.contains("\(home)/Library/Caches/Homebrew"))
    }

    @Test("Edge: absent paths are skipped")
    func skipsAbsent() {
        let preset = CleanupPreset(id: "test", name: "Test", candidates: ["Library/Caches", ".Trash"])
        // pretend only .Trash exists
        let resolved = CleanupPresets.resolve(preset, home: home,
                                              exists: { $0.hasSuffix("/.Trash") })
        #expect(resolved == ["\(home)/.Trash"])
    }

    @Test("there is at least one curated preset")
    func hasPresets() {
        #expect(!CleanupPresets.all.isEmpty)
    }
}
