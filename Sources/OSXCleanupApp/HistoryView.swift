import SwiftUI
import CleanupCore

// Cleanup history panel (M4): past cleanups newest-first, with reclaimed totals.

struct HistoryView: View {
    let appState: AppStateModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cleanup History").font(.title3.bold())
                Spacer()
                Button("Clear", role: .destructive) { appState.clearHistory() }
                    .disabled(appState.history.isEmpty)
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }

            if appState.history.isEmpty {
                Text("No cleanups recorded yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(appState.history) { entry in
                    HStack {
                        Image(systemName: entry.kind == .delegated ? "wrench.and.screwdriver" : "trash")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dateText(entry.timestamp)).font(.callout)
                            Text(summary(entry)).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if entry.reclaimedBytes > 0 {
                            Text(formatBytes(entry.reclaimedBytes))
                                .font(.callout.monospaced()).foregroundStyle(.green)
                        }
                    }
                }
            }

            if let exclusions = nonEmptyExclusions {
                Divider()
                Text("Protected paths").font(.headline)
                ForEach(exclusions, id: \.self) { path in
                    HStack {
                        Image(systemName: "lock.fill").foregroundStyle(.blue).font(.caption2)
                        Text(path).font(.caption.monospaced()).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Button("Unprotect") { appState.removeExclusion(path) }
                            .controlSize(.small).buttonStyle(.borderless)
                    }
                }
            }
        }
        .padding(18)
        .frame(width: 560, height: 480)
    }

    private var nonEmptyExclusions: [String]? {
        let all = appState.exclusions.all
        return all.isEmpty ? nil : all
    }

    private func dateText(_ ts: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func summary(_ e: HistoryEntry) -> String {
        let kind = e.kind == .delegated ? "Delegated cleanup" : "Deletion"
        let outcomes = e.outcomeCounts.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", ")
        return "\(kind) · \(e.itemCount) item(s)" + (outcomes.isEmpty ? "" : " · \(outcomes)")
    }
}
