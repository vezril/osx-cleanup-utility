import SwiftUI
import CleanupCore

// UI styling for safety tiers (a view concern, kept out of the pure core).

extension SafetyTier {
    var color: Color {
        switch self {
        case .safe:      return .green
        case .cache:     return .teal
        case .delegated: return .blue
        case .risky:     return .orange
        case .never:     return .red
        }
    }

    var label: String {
        switch self {
        case .safe:      return "Safe"
        case .cache:     return "Cache"
        case .delegated: return "Delegated"
        case .risky:     return "Risky"
        case .never:     return "Never"
        }
    }
}

/// Color-coded legend mapping each tier to its meaning.
struct TierLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            ForEach(SafetyTier.allCases, id: \.self) { tier in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(tier.color)
                        .frame(width: 11, height: 11)
                    Text(tier.label).font(.caption2)
                }
            }
        }
        .foregroundStyle(.secondary)
    }
}

/// Format a byte count as a human-readable string (UI helper).
func formatBytes(_ bytes: Int64) -> String {
    let units = ["B", "KB", "MB", "GB", "TB"]
    var value = Double(bytes)
    var unit = 0
    while value >= 1024 && unit < units.count - 1 {
        value /= 1024
        unit += 1
    }
    return unit == 0 ? "\(bytes) B" : String(format: "%.1f %@", value, units[unit])
}
