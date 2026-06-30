// Persisted application state — pure, codable. The version field eases future
// schema migrations.

public struct AppState: Codable, Sendable, Equatable {
    public var version: Int
    public var exclusions: ExclusionSet
    public var history: [HistoryEntry]

    public init(version: Int = 1,
                exclusions: ExclusionSet = ExclusionSet(),
                history: [HistoryEntry] = []) {
        self.version = version
        self.exclusions = exclusions
        self.history = history
    }
}
