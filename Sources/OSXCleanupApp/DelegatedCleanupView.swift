import SwiftUI
import CleanupCore
import CleanupScan

// Delegated Cleanup panel (M3): detected tools with dry-run/cleanup, and APFS
// local snapshots. Destructive actions show a preview/confirmation first.

struct DelegatedCleanupView: View {
    let model: DelegatedModel
    @Environment(\.dismiss) private var dismiss
    @State private var thinGB = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Delegated Cleanup").font(.title3.bold())
                Spacer()
                Button("Re-scan") { model.refresh() }
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            Text("Reclaim space that file deletion can't safely touch — each tool runs its own cleanup command. No sudo; commands are fixed and vetted.")
                .font(.caption).foregroundStyle(.secondary)

            snapshotsSection
            Divider()
            providersSection
        }
        .padding(18)
        .frame(width: 640, height: 560)
        .onAppear { model.refresh() }
    }

    private var snapshotsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("APFS local snapshots", systemImage: "camera.aperture").font(.headline)
            if model.snapshots.isEmpty {
                Text("No local snapshots found.").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("\(model.snapshots.count) snapshot(s) — often the biggest reclaimable space.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(model.snapshots, id: \.self) { date in
                    HStack {
                        Text(date).font(.caption.monospaced())
                        Spacer()
                        Button("Delete") { Task { await model.deleteSnapshot(date) } }
                            .controlSize(.small)
                    }
                }
                HStack {
                    Stepper("Thin to free ~\(thinGB) GB", value: $thinGB, in: 1...500, step: 5)
                        .font(.caption)
                    Button("Thin") { Task { await model.thin(gigabytes: thinGB) } }
                        .controlSize(.small)
                }
            }
            if let msg = model.snapshotMessage {
                Text(msg).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var providersSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Tools", systemImage: "wrench.and.screwdriver").font(.headline)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(model.rows) { row in providerRow(row) }
                }
            }
        }
    }

    @ViewBuilder
    private func providerRow(_ row: DelegatedModel.ProviderRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: row.installed ? "checkmark.circle.fill" : "circle.dashed")
                    .foregroundStyle(row.installed ? .green : .secondary)
                VStack(alignment: .leading) {
                    Text(row.provider.binary).font(.callout.bold())
                    Text(row.provider.description).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                if !row.installed {
                    Text("not detected").font(.caption2).foregroundStyle(.tertiary)
                } else {
                    if row.running { ProgressView().controlSize(.small) }
                    if row.provider.dryRunArgs != nil {
                        Button("Preview") { Task { await model.preview(row.id) } }
                            .controlSize(.small).disabled(row.running)
                    }
                    Button("Clean") { Task { await model.cleanup(row.id) } }
                        .controlSize(.small).disabled(row.running)
                }
            }
            if let preview = row.preview {
                Text(preview).font(.caption2.monospaced()).foregroundStyle(.secondary)
                    .lineLimit(4).padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 5))
            }
            if let result = row.result {
                Label(resultText(result), systemImage: result.outcome == .succeeded ? "checkmark.seal" : "xmark.octagon")
                    .font(.caption2)
                    .foregroundStyle(result.outcome == .succeeded ? .green : .orange)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
    }

    private func resultText(_ r: DelegatedResult) -> String {
        switch r.outcome {
        case .succeeded: return "Done — \(r.output.prefix(80))"
        case .failed: return "Failed — \(r.output.prefix(80))"
        case .timedOut: return "Timed out"
        case .cancelled: return "Cancelled"
        }
    }
}
