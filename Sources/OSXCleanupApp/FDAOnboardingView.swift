import SwiftUI
import AppKit
import CleanupScan

// Full Disk Access onboarding banner. Shown when access is not granted: it
// explains why, deep-links to the Settings pane (macOS forbids requesting it
// programmatically), and makes clear that protected areas are hidden — never
// reported as empty/clean — until access is granted (graceful degradation).

struct FDAOnboardingView: View {
    let model: ScanModel

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Full Disk Access not granted")
                    .font(.callout.bold())
                Text("Areas like Mail, Messages, and iOS backups are hidden — not empty — until you grant access. Everything else still scans.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Open Settings…") { openSettings() }
                    Button("Re-check") { model.refreshFDA() }
                        .buttonStyle(.borderless)
                }
                .padding(.top, 2)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.orange.opacity(0.4)))
    }

    private func openSettings() {
        if let url = URL(string: FullDiskAccess.settingsURLString) {
            NSWorkspace.shared.open(url)
        }
    }
}
