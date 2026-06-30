import Foundation
import CleanupCore

// Bridges a DelegatedProvider to the safe CommandRunner: detects the tool from
// its known locations, then runs its vetted dry-run or cleanup argument vector.

public struct DelegatedRunner: Sendable {
    private let runner: CommandRunner
    public init(runner: CommandRunner = CommandRunner()) { self.runner = runner }

    /// Resolved binary path if the tool is installed at a known location.
    public func installedPath(_ provider: DelegatedProvider) -> String? {
        DelegatedProviders.detectedPath(provider, isExecutable: {
            FileManager.default.isExecutableFile(atPath: $0)
        })
    }

    public func isInstalled(_ provider: DelegatedProvider) -> Bool {
        installedPath(provider) != nil
    }

    /// Run the provider's non-destructive preview, if it has one and is installed.
    public func dryRun(_ provider: DelegatedProvider) -> CommandRunner.Result? {
        guard let path = installedPath(provider), let args = provider.dryRunArgs else { return nil }
        return runner.run(binary: path, args: args)
    }

    /// Run the provider's cleanup command and map it to a DelegatedResult.
    public func cleanup(_ provider: DelegatedProvider) -> DelegatedResult {
        guard let path = installedPath(provider) else {
            return DelegatedResult(providerID: provider.id, outcome: .failed, output: "Tool not detected.")
        }
        switch runner.run(binary: path, args: provider.cleanupArgs) {
        case .success(let out):
            return DelegatedResult(providerID: provider.id, outcome: .succeeded,
                                   output: out.stdout.isEmpty ? "Done." : out.stdout)
        case .failure(let out):
            return DelegatedResult(providerID: provider.id, outcome: .failed,
                                   output: out.stderr.isEmpty ? "Exited \(out.exitCode)." : out.stderr)
        case .timedOut:
            return DelegatedResult(providerID: provider.id, outcome: .timedOut, output: "Timed out.")
        case .cancelled:
            return DelegatedResult(providerID: provider.id, outcome: .cancelled, output: "Cancelled.")
        }
    }
}
