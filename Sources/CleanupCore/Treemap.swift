// Squarified treemap layout — pure geometry, no I/O, no UI.
//
// Maps sized items into non-overlapping rectangles whose areas are proportional
// to their sizes, preferring near-square rectangles (Bruls, Huizing & van Wijk,
// "Squarified Treemaps", 2000). Items below `minFraction` of the total are
// aggregated into a single synthetic "Other" item so very large trees stay
// legible. SwiftUI only renders the returned rectangles.

/// An axis-aligned rectangle in layout space (origin top-left).
public struct Rect: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
    var shorterSide: Double { min(width, height) }
}

/// An item to place: an identifier and a non-negative size.
public struct TreemapItem: Equatable, Sendable {
    public let id: String
    public let size: Int64
    public init(id: String, size: Int64) { self.id = id; self.size = size }
}

/// A placed rectangle for an item.
public struct PlacedRect: Equatable, Sendable {
    public let id: String
    public let rect: Rect
    public init(id: String, rect: Rect) { self.id = id; self.rect = rect }
}

public enum Treemap {

    /// Identifier used for the aggregated bucket of sub-threshold items.
    public static let otherID = "Other"

    /// Lay out `items` within `bounds`. Items with `size <= 0` are dropped.
    /// When `minFraction > 0`, items smaller than that fraction of the total are
    /// merged into a single `Other` item.
    public static func layout(_ items: [TreemapItem], in bounds: Rect, minFraction: Double = 0) -> [PlacedRect] {
        let positive = items.filter { $0.size > 0 }
        let total = positive.reduce(0.0) { $0 + Double($1.size) }
        guard total > 0, bounds.width > 0, bounds.height > 0 else { return [] }

        // Aggregate sub-threshold items into "Other".
        var working: [TreemapItem] = []
        var otherSize: Int64 = 0
        for it in positive {
            if minFraction > 0, Double(it.size) / total < minFraction {
                otherSize += it.size
            } else {
                working.append(it)
            }
        }
        if otherSize > 0 { working.append(TreemapItem(id: otherID, size: otherSize)) }

        // Largest first (squarify expects descending order).
        working.sort { $0.size > $1.size }

        // Convert sizes to target areas that exactly fill the bounds.
        let scale = (bounds.width * bounds.height) / total
        let areas = working.map { (id: $0.id, area: Double($0.size) * scale) }

        var result: [PlacedRect] = []
        squarify(areas, [], bounds, &result)
        return result
    }

    // MARK: - Squarify

    private static func squarify(
        _ items: [(id: String, area: Double)],
        _ row: [(id: String, area: Double)],
        _ rect: Rect,
        _ result: inout [PlacedRect]
    ) {
        guard let head = items.first else {
            if !row.isEmpty { layoutRow(row, rect, &result) }
            return
        }
        let side = rect.shorterSide
        let withHead = row + [head]
        if row.isEmpty || worst(row, side) >= worst(withHead, side) {
            // Adding the item improves (or maintains) the aspect ratio.
            squarify(Array(items.dropFirst()), withHead, rect, &result)
        } else {
            // Close the current row and continue in the remaining space.
            let remaining = layoutRow(row, rect, &result)
            squarify(items, [], remaining, &result)
        }
    }

    /// Worst (largest) aspect ratio of a row laid along a side of length `side`.
    private static func worst(_ row: [(id: String, area: Double)], _ side: Double) -> Double {
        guard !row.isEmpty, side > 0 else { return .infinity }
        let areas = row.map(\.area)
        let sum = areas.reduce(0, +)
        guard sum > 0 else { return .infinity }
        let maxA = areas.max() ?? 0
        let minA = areas.min() ?? 0
        let s2 = sum * sum
        let side2 = side * side
        return max((side2 * maxA) / s2, s2 / (side2 * minA))
    }

    /// Place a finished row along the shorter side of `rect`; return the rect
    /// remaining after the row is removed.
    @discardableResult
    private static func layoutRow(
        _ row: [(id: String, area: Double)],
        _ rect: Rect,
        _ result: inout [PlacedRect]
    ) -> Rect {
        let rowArea = row.reduce(0.0) { $0 + $1.area }
        guard rowArea > 0 else { return rect }

        if rect.width >= rect.height {
            // Lay the row as a vertical strip on the left.
            let stripWidth = rowArea / rect.height
            var y = rect.y
            for item in row {
                let h = item.area / stripWidth
                result.append(PlacedRect(id: item.id, rect: Rect(
                    x: rect.x, y: y, width: stripWidth, height: h)))
                y += h
            }
            return Rect(x: rect.x + stripWidth, y: rect.y,
                        width: rect.width - stripWidth, height: rect.height)
        } else {
            // Lay the row as a horizontal strip on the top.
            let stripHeight = rowArea / rect.width
            var x = rect.x
            for item in row {
                let w = item.area / stripHeight
                result.append(PlacedRect(id: item.id, rect: Rect(
                    x: x, y: rect.y, width: w, height: stripHeight)))
                x += w
            }
            return Rect(x: rect.x, y: rect.y + stripHeight,
                        width: rect.width, height: rect.height - stripHeight)
        }
    }
}
