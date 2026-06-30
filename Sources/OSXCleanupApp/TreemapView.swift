import SwiftUI
import CleanupCore

// Renders a node's children as a squarified treemap. The geometry comes from the
// pure `Treemap.layout`; this view only draws and routes taps. Read-only.

struct TreemapView: View {
    let node: SizeNode
    let model: ScanModel

    var body: some View {
        GeometryReader { geo in
            let bounds = Rect(x: 0, y: 0,
                              width: Double(geo.size.width),
                              height: Double(geo.size.height))
            let childByPath = Dictionary(uniqueKeysWithValues: node.children.map { ($0.path, $0) })
            let items = node.children.map { TreemapItem(id: $0.path, size: $0.size) }
            let placed = Treemap.layout(items, in: bounds, minFraction: 0.004)

            ZStack(alignment: .topLeading) {
                ForEach(placed, id: \.id) { p in
                    cell(for: p, child: childByPath[p.id])
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for p: PlacedRect, child: SizeNode?) -> some View {
        let tier = child.map { model.classification($0).tier } ?? .risky
        let isSelected = model.selected?.path == p.id
        let w = CGFloat(p.rect.width)
        let h = CGFloat(p.rect.height)

        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(tier.color.opacity(isSelected ? 0.95 : 0.7))
                .overlay(
                    Rectangle().strokeBorder(
                        isSelected ? Color.primary : Color.black.opacity(0.25),
                        lineWidth: isSelected ? 2 : 0.5)
                )
            if w > 54 && h > 24, let child {
                VStack(alignment: .leading, spacing: 0) {
                    Text(child.name)
                        .font(.caption2).bold()
                        .lineLimit(1)
                    Text(formatBytes(child.size))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                .padding(3)
                .allowsHitTesting(false)
            }
        }
        .frame(width: w, height: h)
        .offset(x: CGFloat(p.rect.x), y: CGFloat(p.rect.y))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { if let child { model.drill(into: child) } }
        .onTapGesture(count: 1) { if let child { model.select(child) } }
        .help(child.map { "\($0.name) — \(formatBytes($0.size)) — \(model.classification($0).tier.label)" } ?? p.id)
    }
}
