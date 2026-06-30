import SwiftUI
import AppKit
import CleanupCore

// OSXCleanupApp — the imperative shell.
//
// Wires the SwiftUI UI to the pure core (CleanupCore) and platform layer
// (CleanupScan): pick a root → scan → roll up → classify → treemap. M1 is
// strictly read-only: there is no delete/trash/clean affordance anywhere.

@main
struct OSXCleanupApp: App {
    var body: some Scene {
        WindowGroup("osx-cleanup-utility") {
            ContentView()
                .frame(minWidth: 820, minHeight: 560)
        }
    }
}

struct ContentView: View {
    @State private var model = ScanModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if model.fda == .notGranted {
                FDAOnboardingView(model: model).padding(8)
            }
            if model.rootTree != nil {
                presetsBar
                Divider()
            }
            content
            Divider()
            footer
        }
        .onAppear { model.refreshFDA() }
        .sheet(isPresented: Binding(get: { model.showingPlan }, set: { model.showingPlan = $0 })) {
            PlanPreviewSheet(model: model)
        }
        .sheet(isPresented: Binding(get: { model.showingResults }, set: { model.showingResults = $0 })) {
            ResultsSheet(model: model)
        }
    }

    // MARK: - presets + deletion bar

    private var presetsBar: some View {
        HStack(spacing: 8) {
            Text("Presets:").font(.caption).foregroundStyle(.secondary)
            ForEach(CleanupPresets.all) { preset in
                Button(preset.name) { model.applyPreset(preset) }
                    .buttonStyle(.bordered).controlSize(.small)
            }
            Spacer()
            if !model.deletionSelection.isEmpty {
                Text("\(model.deletionSelection.count) selected · \(formatBytes(model.selectedReclaimable))")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Clear") { model.clearDeletionSelection() }
                    .buttonStyle(.borderless).controlSize(.small)
                Button("Review & Delete…") { model.buildPlan() }
                    .buttonStyle(.borderedProminent).controlSize(.small)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - toolbar

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button {
                if let path = chooseFolder() { startScan(path) }
            } label: {
                Label("Choose Folder…", systemImage: "folder")
            }

            Button("Scan ~/Library/Caches") {
                startScan(NSHomeDirectory() + "/Library/Caches")
            }

            if model.phase == .scanning {
                ProgressView().controlSize(.small)
                Text("Scanning… \(model.scannedCount) items")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Cancel") { model.cancel() }
            } else if model.phase == .done {
                Text("\(model.scannedCount) items · \(formatBytes(model.rootTree?.size ?? 0))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
    }

    // MARK: - main content

    @ViewBuilder
    private var content: some View {
        if let current = model.current {
            HSplitView {
                VStack(spacing: 0) {
                    breadcrumb(current)
                    TreemapView(node: current, model: model)
                        .background(Color(nsColor: .windowBackgroundColor))
                }
                .frame(minWidth: 480)
                InspectorView(model: model)
                    .frame(width: 280)
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 48)).foregroundStyle(.secondary)
                Text("Choose a folder to visualize its disk usage.")
                    .foregroundStyle(.secondary)
                Text("core v\(CleanupCore.version)")
                    .font(.caption.monospaced()).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func breadcrumb(_ current: SizeNode) -> some View {
        HStack(spacing: 6) {
            Button {
                model.drillOut()
            } label: {
                Label("Up", systemImage: "chevron.up")
            }
            .disabled(model.path.isEmpty)

            Button("Root") { model.resetToRoot() }
                .disabled(model.path.isEmpty)

            Text(current.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.head)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - footer

    private var footer: some View {
        HStack {
            TierLegend()
            Spacer()
            Text("Deletions move to Trash by default · protected paths can never be removed")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - actions

    private func startScan(_ path: String) {
        Task { await model.scan(rootPath: path) }
    }

    private func chooseFolder() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan"
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
