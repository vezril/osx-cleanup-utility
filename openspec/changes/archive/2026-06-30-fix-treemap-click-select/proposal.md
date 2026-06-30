## Why

During the M1–M4 visual pass, single-click-to-select on a treemap tile was found to be unreliable — clicking a tile often did not update the inspector. Since the inspector is the primary way to see a node's path, size, tier, and the reason for that tier, this is a real UX defect. The existing `disk-usage-treemap` spec already requires it ("WHEN the user selects a rectangle THEN an inspector shows that node's full path, allocated size, safety tier, and the human-readable reason"); this change fixes the implementation to meet that requirement.

## What Changes

- Replace the competing gesture stack on each treemap tile. Today each tile stacks `.onTapGesture(count: 2)` (drill) + `.onTapGesture(count: 1)` (select) + a `.simultaneousGesture(TapGesture().modifiers(.command))` (toggle mark-for-deletion). The simultaneous command gesture interferes with single/double-tap recognition and swallows single taps.
- Fold ⌘-click detection into the single-tap handler using `NSEvent.modifierFlags`, removing the competing simultaneous gesture.
- **Fix tile hit-testing** (discovered during verification): tiles were placed with `.offset`, which moved the visual but left the hittable region at the layout origin — so a click landed on the *wrong* tile. Attach the hit area + gestures to the framed cell and place it with `.position` (center-based) instead, so taps map to the tile under the cursor.
- Result: single-click reliably **selects the tile under the cursor** (updating the inspector), double-click **drills into the correct directory**, and ⌘-click **toggles mark-for-deletion**.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
<!-- None — this is a bug fix that makes the implementation meet the existing
     `disk-usage-treemap` requirement ("Inspector shows path, size, tier, and
     reason"). No spec behavior changes. -->

## Impact

- `Sources/OSXCleanupApp/TreemapView.swift`: gesture handling on each tile; adds `import AppKit` for `NSEvent.modifierFlags`.
- No change to `CleanupCore` or any pure logic; the existing 111 tests remain green.
- Verified by rebuilding the `.app`, relaunching, and confirming single-click selects (double-click drills, ⌘-click marks).
