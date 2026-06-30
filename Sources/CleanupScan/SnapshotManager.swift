import Foundation

// APFS local snapshot management via `tmutil` only.
//
// Snapshot blocks are invisible to the filesystem and can only be reclaimed
// through `tmutil`. Parsing and date validation are pure; list/delete/thin run
// `tmutil` through the injectable CommandRunner. Any date parsed from tmutil
// output is validated against the expected format before being used as an
// argument, so even tmutil's own output can never become an injection vector.

public struct SnapshotManager: Sendable {

    static let tmutil = "/usr/bin/tmutil"

    private let runner: CommandRunner
    private let mountPoint: String

    public init(runner: CommandRunner = CommandRunner(), mountPoint: String = "/") {
        self.runner = runner
        self.mountPoint = mountPoint
    }

    // MARK: - pure parsing / validation

    /// Snapshot dates look like `2024-01-15-103000` (YYYY-MM-DD-HHMMSS).
    public static func isValidSnapshotDate(_ s: String) -> Bool {
        let parts = s.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        let lengths = [4, 2, 2, 6]
        for (part, len) in zip(parts, lengths) {
            guard part.count == len, part.allSatisfy(\.isNumber) else { return false }
        }
        return true
    }

    /// Parse `tmutil listlocalsnapshotdates` output into valid dates only.
    /// Anything that does not match the expected format is dropped (fail safe).
    public static func parseDates(_ output: String) -> [String] {
        output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { isValidSnapshotDate($0) }
    }

    // MARK: - tmutil operations (injected runner)

    /// List local snapshot dates for the mount point.
    public func list() -> [String] {
        let result = runner.run(binary: Self.tmutil,
                                args: ["listlocalsnapshotdates", mountPoint])
        guard case .success(let out) = result else { return [] }
        return Self.parseDates(out.stdout)
    }

    /// Delete a specific snapshot by date. Returns nil (refused) if the date is
    /// not well-formed, so a malformed/injected value is never passed to tmutil.
    @discardableResult
    public func delete(date: String) -> CommandRunner.Result? {
        guard Self.isValidSnapshotDate(date) else { return nil }
        return runner.run(binary: Self.tmutil, args: ["deletelocalsnapshots", date])
    }

    /// Thin local snapshots to reclaim a target number of bytes.
    @discardableResult
    public func thin(bytes: Int64, urgency: Int) -> CommandRunner.Result {
        runner.run(binary: Self.tmutil,
                   args: ["thinlocalsnapshots", mountPoint, String(bytes), String(urgency)])
    }
}
