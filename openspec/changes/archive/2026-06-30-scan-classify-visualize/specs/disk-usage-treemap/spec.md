## ADDED Requirements

### Requirement: Treemap layout is computed as a pure function of sizes and bounds
The treemap layout SHALL be a pure function mapping a set of sized nodes and a bounding rectangle to a set of non-overlapping placed rectangles whose areas are proportional to node sizes. To remain renderable on very large trees, the layout SHALL aggregate nodes below a size/pixel threshold into a single synthetic "Other" node and SHALL bound drill depth.

#### Scenario: Rectangle areas are proportional to sizes
- **WHEN** the layout is computed for a set of nodes within a bounding rectangle
- **THEN** each placed rectangle's area is proportional to its node's size and the rectangles do not overlap and fit within the bounds

#### Scenario: Tiny nodes are aggregated into "Other"
- **WHEN** many nodes are individually smaller than the rendering threshold
- **THEN** they are combined into a single "Other (N items)" rectangle so the layout stays legible

#### Scenario: Edge case — single node fills the bounds
- **WHEN** the layout is given exactly one node
- **THEN** that node's rectangle fills the entire bounding rectangle

#### Scenario: Edge case — zero-size nodes do not break layout
- **WHEN** the node set includes zero-size entries
- **THEN** the layout completes without division-by-zero and zero-size nodes occupy no area

### Requirement: Treemap renders by safety tier and supports read-only navigation and inspection
The UI SHALL render the placed rectangles colored by safety tier, allow the user to drill into a directory and back out, and provide an inspector showing the selected node's path, size, tier, and the reason for that tier. M1 is read-only: the treemap SHALL NOT offer any delete or "clean" affordance.

#### Scenario: Nodes are colored by tier
- **WHEN** the treemap is displayed for a classified scan
- **THEN** each rectangle is colored according to its safety tier and a legend maps colors to tiers

#### Scenario: Inspector shows path, size, tier, and reason
- **WHEN** the user selects a rectangle
- **THEN** an inspector shows that node's full path, allocated size, safety tier, and the human-readable reason for the classification

#### Scenario: Edge case — drilling into and out of a directory preserves context
- **WHEN** the user drills into a subdirectory and then navigates back
- **THEN** the treemap returns to the previous level showing the same parent context

#### Scenario: Edge case — no deletion affordance is present
- **WHEN** any node, including a `SAFE`-tier one, is selected
- **THEN** the UI offers inspection only and presents no control that deletes, trashes, or cleans the node
