import Testing
@testable import CleanupCore

// Treemap layout (task 4.1): a pure function from sized items + a bounding rect
// to non-overlapping placed rectangles whose areas are proportional to sizes.
// Pure: no I/O, no UI.

@Suite("Treemap layout")
struct TreemapTests {

    private let bounds = Rect(x: 0, y: 0, width: 100, height: 100)

    private func area(_ r: Rect) -> Double { r.width * r.height }

    private func overlaps(_ a: Rect, _ b: Rect) -> Bool {
        let xOverlap = max(0, min(a.x + a.width, b.x + b.width) - max(a.x, b.x))
        let yOverlap = max(0, min(a.y + a.height, b.y + b.height) - max(a.y, b.y))
        return xOverlap > 1e-6 && yOverlap > 1e-6
    }

    private func within(_ r: Rect, _ b: Rect) -> Bool {
        r.x >= b.x - 1e-6 && r.y >= b.y - 1e-6 &&
        r.x + r.width <= b.x + b.width + 1e-6 &&
        r.y + r.height <= b.y + b.height + 1e-6
    }

    @Test("areas are proportional to sizes, non-overlapping, within bounds")
    func proportionalNonOverlapping() {
        let items = [
            TreemapItem(id: "a", size: 600),
            TreemapItem(id: "b", size: 300),
            TreemapItem(id: "c", size: 100),
        ]
        let placed = Treemap.layout(items, in: bounds)
        #expect(placed.count == 3)

        let totalArea = area(bounds)
        let byId = Dictionary(uniqueKeysWithValues: placed.map { ($0.id, $0.rect) })
        // each area ≈ size/total * boundsArea
        #expect(abs(area(byId["a"]!) - 0.6 * totalArea) < 1.0)
        #expect(abs(area(byId["b"]!) - 0.3 * totalArea) < 1.0)
        #expect(abs(area(byId["c"]!) - 0.1 * totalArea) < 1.0)
        // within bounds
        for p in placed { #expect(within(p.rect, bounds)) }
        // pairwise non-overlap
        for i in 0..<placed.count {
            for j in (i + 1)..<placed.count {
                #expect(!overlaps(placed[i].rect, placed[j].rect))
            }
        }
    }

    @Test("sum of placed areas ≈ bounds area")
    func areasFillBounds() {
        let items = (1...10).map { TreemapItem(id: "n\($0)", size: Int64($0 * 7)) }
        let placed = Treemap.layout(items, in: bounds)
        let sum = placed.reduce(0.0) { $0 + area($1.rect) }
        #expect(abs(sum - area(bounds)) < 1.0)
    }

    @Test("Edge: single node fills the bounds")
    func singleFillsBounds() {
        let placed = Treemap.layout([TreemapItem(id: "only", size: 42)], in: bounds)
        #expect(placed.count == 1)
        #expect(abs(area(placed[0].rect) - area(bounds)) < 1e-6)
    }

    @Test("Edge: zero-size nodes occupy no area and cause no divide-by-zero")
    func zeroSizeNodes() {
        let items = [
            TreemapItem(id: "a", size: 100),
            TreemapItem(id: "z", size: 0),
        ]
        let placed = Treemap.layout(items, in: bounds)
        // zero-size node is omitted (no area); "a" fills the bounds
        #expect(placed.contains { $0.id == "a" })
        #expect(!placed.contains { $0.id == "z" })
    }

    @Test("Edge: all-zero input yields no rectangles, no crash")
    func allZero() {
        let placed = Treemap.layout([TreemapItem(id: "a", size: 0)], in: bounds)
        #expect(placed.isEmpty)
    }

    @Test("tiny nodes below the threshold aggregate into one Other")
    func tinyNodesAggregate() {
        var items = [TreemapItem(id: "big", size: 9000)]
        for i in 0..<50 { items.append(TreemapItem(id: "t\(i)", size: 2)) } // each 2/9100 < 1%
        let placed = Treemap.layout(items, in: bounds, minFraction: 0.01)
        #expect(placed.contains { $0.id == "big" })
        #expect(placed.contains { $0.id == "Other" })
        // the 50 tiny ones are not placed individually
        #expect(!placed.contains { $0.id == "t0" })
    }
}
