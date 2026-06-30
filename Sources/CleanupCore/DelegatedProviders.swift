// Delegated cleanup providers — pure registry + model.
//
// Some bloat (package-manager caches, Docker images) must be reclaimed by the
// owner tool's own command, not by deleting files. Each provider names a binary
// to detect and a FIXED, literal argument vector for its cleanup command — never
// a shell string, never interpolated input. This file is the legible mirror of
// the sourced research's DELEGATED tier.

public struct DelegatedProvider: Equatable, Sendable, Identifiable {
    public let id: String
    public let binary: String
    public let category: String
    public let description: String
    /// Absolute locations to check for the binary (a GUI app has no shell PATH).
    public let knownLocations: [String]
    /// Literal argument vector for the cleanup command.
    public let cleanupArgs: [String]
    /// Optional literal argument vector for a non-destructive preview.
    public let dryRunArgs: [String]?

    public init(id: String, binary: String, category: String, description: String,
                knownLocations: [String], cleanupArgs: [String], dryRunArgs: [String]?) {
        self.id = id
        self.binary = binary
        self.category = category
        self.description = description
        self.knownLocations = knownLocations
        self.cleanupArgs = cleanupArgs
        self.dryRunArgs = dryRunArgs
    }
}

/// Outcome of running a delegated cleanup.
public enum DelegatedOutcome: Equatable, Sendable {
    case succeeded
    case failed
    case timedOut
    case cancelled
}

public struct DelegatedResult: Equatable, Sendable {
    public let providerID: String
    public let outcome: DelegatedOutcome
    public let output: String
    public init(providerID: String, outcome: DelegatedOutcome, output: String) {
        self.providerID = providerID
        self.outcome = outcome
        self.output = output
    }
}

public enum DelegatedProviders {

    private static let brewLocations = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]

    /// Built-in providers. Every command is a literal argument vector; the
    /// destructive `cleanupArgs` is always distinct from any `dryRunArgs`.
    public static let all: [DelegatedProvider] = [
        DelegatedProvider(
            id: "homebrew", binary: "brew", category: "Package manager",
            description: "Remove old Homebrew downloads and stale cached bottles.",
            knownLocations: brewLocations,
            cleanupArgs: ["cleanup", "--prune=all"],
            dryRunArgs: ["cleanup", "--dry-run"]),
        DelegatedProvider(
            id: "docker", binary: "docker", category: "Containers",
            description: "Prune unused Docker images, containers, and build cache.",
            knownLocations: ["/usr/local/bin/docker", "/opt/homebrew/bin/docker"],
            cleanupArgs: ["system", "prune", "-f"],
            dryRunArgs: nil),
        DelegatedProvider(
            id: "npm", binary: "npm", category: "Package manager",
            description: "Clear the npm download cache.",
            knownLocations: ["/opt/homebrew/bin/npm", "/usr/local/bin/npm"],
            cleanupArgs: ["cache", "clean", "--force"],
            dryRunArgs: nil),
        DelegatedProvider(
            id: "yarn", binary: "yarn", category: "Package manager",
            description: "Clear the Yarn cache.",
            knownLocations: ["/opt/homebrew/bin/yarn", "/usr/local/bin/yarn"],
            cleanupArgs: ["cache", "clean"],
            dryRunArgs: nil),
        DelegatedProvider(
            id: "pnpm", binary: "pnpm", category: "Package manager",
            description: "Remove unreferenced packages from the pnpm store.",
            knownLocations: ["/opt/homebrew/bin/pnpm", "/usr/local/bin/pnpm"],
            cleanupArgs: ["store", "prune"],
            dryRunArgs: nil),
        DelegatedProvider(
            id: "pip", binary: "pip3", category: "Package manager",
            description: "Purge the pip download/wheel cache.",
            knownLocations: ["/opt/homebrew/bin/pip3", "/usr/local/bin/pip3", "/usr/bin/pip3"],
            cleanupArgs: ["cache", "purge"],
            dryRunArgs: nil),
    ]

    /// Resolve a provider's binary from its known locations (not the shell PATH,
    /// which a GUI app does not inherit). Returns the first executable path, or
    /// nil if the tool is not detected.
    public static func detectedPath(
        _ provider: DelegatedProvider,
        isExecutable: (String) -> Bool
    ) -> String? {
        provider.knownLocations.first(where: isExecutable)
    }
}
