import Testing
@testable import CleanupCore

// Delegated provider registry + model (tasks 1.1, 1.3). Pure: no I/O.

@Suite("Delegated providers")
struct DelegatedProviderTests {

    @Test("a provider carries binary, category, description, locations, and commands")
    func providerShape() {
        let p = DelegatedProvider(
            id: "homebrew", binary: "brew", category: "Package manager",
            description: "Clean up old Homebrew downloads",
            knownLocations: ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"],
            cleanupArgs: ["cleanup", "--prune=all"],
            dryRunArgs: ["cleanup", "--dry-run"])
        #expect(p.id == "homebrew")
        #expect(p.binary == "brew")
        #expect(p.knownLocations.count == 2)
        #expect(p.cleanupArgs == ["cleanup", "--prune=all"])
        #expect(p.dryRunArgs == ["cleanup", "--dry-run"])
    }

    @Test("the built-in registry is non-empty and includes Homebrew and Docker")
    func registryPopulated() {
        let ids = Set(DelegatedProviders.all.map(\.id))
        #expect(!DelegatedProviders.all.isEmpty)
        #expect(ids.contains("homebrew"))
        #expect(ids.contains("docker"))
    }

    @Test("DelegatedResult pairs a provider id with an outcome and output")
    func resultShape() {
        let r = DelegatedResult(providerID: "homebrew", outcome: .succeeded, output: "Pruned 2.1GB")
        #expect(r.providerID == "homebrew")
        #expect(r.outcome == .succeeded)
        #expect(r.output.contains("2.1GB"))
    }

    // 1.3 — commands are literal argument vectors, dry-run ≠ cleanup
    @Test("every provider command is a literal argument vector")
    func commandsAreLiteralArgs() {
        for p in DelegatedProviders.all {
            #expect(!p.cleanupArgs.isEmpty)
            // No element is a packed shell string with metacharacters.
            for arg in p.cleanupArgs + (p.dryRunArgs ?? []) {
                #expect(!arg.contains("|") && !arg.contains(";") && !arg.contains("&&"),
                        "arg '\(arg)' in \(p.id) looks like a shell fragment")
            }
        }
    }

    @Test("a provider's dry-run args differ from its cleanup args where present")
    func dryRunDistinct() {
        for p in DelegatedProviders.all {
            if let dry = p.dryRunArgs {
                #expect(dry != p.cleanupArgs, "\(p.id) dry-run must not equal cleanup")
            }
        }
    }
}
