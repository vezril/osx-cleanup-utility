## MODIFIED Requirements

### Requirement: Treemap renders by safety tier and supports read-only navigation and inspection
The UI SHALL render the placed rectangles colored by safety tier, allow the user to drill into a directory and back out, and provide an inspector showing the selected node's path, size, tier, and the reason for that tier. Navigation and inspection remain non-destructive. The treemap MAY offer a deletion action, but only via the gated deletion flow: the user multi-selects items, a plan preview is shown, and removal occurs only after the tier-appropriate confirmation. The treemap SHALL NOT delete anything directly from a single click, and SHALL NOT offer any delete affordance for a `NEVER`-tier node.

#### Scenario: Nodes are colored by tier
- **WHEN** the treemap is displayed for a classified scan
- **THEN** each rectangle is colored according to its safety tier and a legend maps colors to tiers

#### Scenario: Inspector shows path, size, tier, and reason
- **WHEN** the user selects a rectangle
- **THEN** an inspector shows that node's full path, allocated size, safety tier, and the human-readable reason for the classification

#### Scenario: Edge case — drilling into and out of a directory preserves context
- **WHEN** the user drills into a subdirectory and then navigates back
- **THEN** the treemap returns to the previous level showing the same parent context

#### Scenario: Deletion is gated behind selection, preview, and confirmation
- **WHEN** the user chooses to delete one or more selected tiles
- **THEN** a deletion plan preview is shown and nothing is removed until the required tier-appropriate confirmation is given

#### Scenario: Edge case — a NEVER-tier node offers no deletion affordance
- **WHEN** a `NEVER`-tier node is selected
- **THEN** the UI offers inspection only and presents no control that deletes, trashes, or cleans that node
