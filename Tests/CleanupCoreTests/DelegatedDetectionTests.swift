import Testing
@testable import CleanupCore

// Tool detection (task 2.1). Pure: existence/executability is injected, so the
// test does no real filesystem I/O and never relies on PATH.

@Suite("Delegated detection")
struct DelegatedDetectionTests {

    private let brew = DelegatedProvider(
        id: "homebrew", binary: "brew", category: "x", description: "x",
        knownLocations: ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"],
        cleanupArgs: ["cleanup"], dryRunArgs: nil)

    @Test("a tool present at a known location is detected")
    func detectedWhenPresent() {
        let path = DelegatedProviders.detectedPath(brew, isExecutable: { $0 == "/usr/local/bin/brew" })
        #expect(path == "/usr/local/bin/brew")
    }

    @Test("the first matching known location wins")
    func firstMatchWins() {
        let path = DelegatedProviders.detectedPath(brew, isExecutable: { _ in true })
        #expect(path == "/opt/homebrew/bin/brew")
    }

    @Test("Edge: absent tool is not detected")
    func notDetectedWhenAbsent() {
        let path = DelegatedProviders.detectedPath(brew, isExecutable: { _ in false })
        #expect(path == nil)
    }

    @Test("Edge: detection only consults known locations, not PATH")
    func onlyKnownLocations() {
        var probed: [String] = []
        _ = DelegatedProviders.detectedPath(brew, isExecutable: { probed.append($0); return false })
        #expect(probed == brew.knownLocations)  // exactly the declared locations, nothing else
    }
}
