import Foundation
import CleanupCore

// Persistent JSON store (platform layer). Read/write are injectable so the
// load/save logic is unit-tested in memory; `Store.file(at:)` backs it with a
// real file. A missing or corrupt payload loads defaults rather than throwing,
// so a bad state file never blocks launch.

public struct Store: Sendable {
    private let read: @Sendable () -> Data?
    private let write: @Sendable (Data) -> Void

    public init(read: @escaping @Sendable () -> Data?, write: @escaping @Sendable (Data) -> Void) {
        self.read = read
        self.write = write
    }

    /// Load the persisted state, returning defaults on any failure.
    public func load() -> AppState {
        guard let data = read() else { return AppState() }
        return (try? JSONDecoder().decode(AppState.self, from: data)) ?? AppState()
    }

    /// Persist the state. Encoding failures are swallowed (state is best-effort).
    public func save(_ state: AppState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        write(data)
    }

    // MARK: - real file-backed store

    /// A store backed by a JSON file at `url`, creating parent directories.
    public static func file(at url: URL) -> Store {
        Store(
            read: { try? Data(contentsOf: url) },
            write: { data in
                try? FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? data.write(to: url, options: .atomic)
            }
        )
    }

    /// The app's state file under Application Support, namespaced by bundle id.
    /// The app never offers this container for deletion (see AppPaths).
    public static func defaultLocation(bundleID: String = AppPaths.bundleID) -> URL {
        AppPaths.stateFileURL(bundleID: bundleID)
    }
}

/// Well-known app paths, including the state container the app must never clean.
public enum AppPaths {
    public static let bundleID = "dev.vezril.osx-cleanup-utility"

    public static func supportDirectory(bundleID: String = bundleID) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent(bundleID, isDirectory: true)
    }

    public static func stateFileURL(bundleID: String = bundleID) -> URL {
        supportDirectory(bundleID: bundleID).appendingPathComponent("state.json")
    }
}
