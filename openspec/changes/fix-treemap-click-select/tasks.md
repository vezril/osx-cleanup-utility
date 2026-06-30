> Bug fix to existing behavior (no spec delta). The defect is a SwiftUI gesture
> interaction with no unit-testable logic, so it is verified by rebuilding and
> visually confirming the app. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
> is required for `swift build`/`swift test`.

## 1. Fix the gesture

- [x] 1.1 In `TreemapView.swift`: add `import AppKit`; replace the three-gesture stack with `.onTapGesture(count: 2){drill}` + `.onTapGesture(count: 1){ cmd? toggle : select }` via `NSEvent.modifierFlags` (removed the competing `.simultaneousGesture`); AND fix hit-testing — attach hit area + gestures to the framed cell and place it with `.position` instead of `.offset` (the `.offset` left the hit region at the origin, so taps hit the wrong tile)
- [x] 1.2 `swift build` clean; `swift test` green (111 tests, no core change)

## 2. Verify

- [x] 2.1 ✅ Verified live: single-click selects the correct tile (Downloads/.Trash), switches between tiles, double-click drills into the correct folder. Rebuild the `.app`, relaunch, and confirm: single-click a tile updates the inspector reliably; double-click still drills into a directory; ⌘-click still toggles mark-for-deletion (GUI step; record result)
- [x] 2.2 Run `openspec validate fix-treemap-click-select`; commit
