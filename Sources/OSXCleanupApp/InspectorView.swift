import SwiftUI
import CleanupCore

// Read-only inspector for the selected node. Shows path, size, tier, and the
// human-readable reason for the classification. M1 offers NO deletion control.

struct InspectorView: View {
    let model: ScanModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspector").font(.headline)

            if let node = model.selected {
                let c = model.classification(node)
                Group {
                    field("Name", node.name)
                    field("Path", node.path, mono: true)
                    field("Size", formatBytes(node.size))
                    HStack(spacing: 6) {
                        Text("Tier").foregroundStyle(.secondary).frame(width: 52, alignment: .leading)
                        Label(c.tier.label, systemImage: "circle.fill")
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(c.tier.color)
                            .font(.callout.bold())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Why").foregroundStyle(.secondary)
                        Text(c.reason).font(.callout)
                    }
                }

                Divider()
                if c.tier == .never {
                    // NEVER-tier nodes expose no deletion affordance at all.
                    Label("Protected — cannot be deleted.", systemImage: "lock.fill")
                        .font(.caption).foregroundStyle(.red)
                } else {
                    Button {
                        model.toggleDeletion(node)
                    } label: {
                        Label(model.isMarkedForDeletion(node) ? "Unmark for deletion" : "Mark for deletion",
                              systemImage: model.isMarkedForDeletion(node) ? "checkmark.circle.fill" : "trash")
                    }
                    Button {
                        model.toggleProtect(node)
                    } label: {
                        Label(model.isProtected(node) ? "Unprotect this path" : "Protect this path",
                              systemImage: model.isProtected(node) ? "lock.open" : "lock")
                    }
                    if model.isProtected(node) {
                        Text("Protected by you — it won't be offered for deletion.")
                            .font(.caption2).foregroundStyle(.blue)
                    }
                    Text("Tip: ⌘-click tiles to mark several at once.")
                        .font(.caption2).foregroundStyle(.tertiary)
                }

                if node.isDirectory && !node.children.isEmpty {
                    Text("Double-click a tile to drill in").font(.caption2).foregroundStyle(.tertiary)
                }
            } else {
                Text("Select a tile to inspect it.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(minWidth: 240)
    }

    @ViewBuilder
    private func field(_ label: String, _ value: String, mono: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label).foregroundStyle(.secondary).frame(width: 52, alignment: .leading)
            Text(value)
                .font(mono ? .caption.monospaced() : .callout)
                .textSelection(.enabled)
                .lineLimit(mono ? 4 : 1)
        }
    }
}
