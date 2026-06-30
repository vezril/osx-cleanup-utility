import SwiftUI
import CleanupCore

// OSXCleanupApp — the imperative shell.
//
// This target wires the SwiftUI UI and (in later milestones) the side-effecting
// calls: FileManager enumeration/deletion, tmutil, NSWorkspace, security-scoped
// bookmarks. It holds NO decision logic — anything that decides *what* is safe,
// bloated, or deletable belongs in CleanupCore so it can be unit-tested.
//
// Milestone 0 ships a placeholder window only. No scanning, no deletion.

@main
struct OSXCleanupApp: App {
    var body: some Scene {
        WindowGroup("osx-cleanup-utility") {
            ContentView()
        }
    }
}

/// Placeholder root view. Displays identity from the functional core to prove
/// the app shell is correctly wired to CleanupCore. No features yet.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "internaldrive")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("osx-cleanup-utility")
                .font(.title.bold())
            Text("FOSS macOS disk cleanup — Milestone 0 scaffold")
                .foregroundStyle(.secondary)
            Text("core v\(CleanupCore.version)")
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(minWidth: 420, minHeight: 280)
    }
}
