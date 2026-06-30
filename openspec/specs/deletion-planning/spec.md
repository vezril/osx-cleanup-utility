# deletion-planning Specification

## Purpose
Defines the deletion gate: a pure function that turns a user selection into a validated `DeletionPlan`. The plan lists exactly what will be removed (with tier and size), totals the reclaimable bytes per tier, excludes any `NEVER`/blacklisted path (recording it as refused), and de-duplicates nested selections. A pure confirmation policy derives the required confirmation strength from the plan's highest tier, escalating for permanent deletion. This is the single, testable place where "what gets deleted" is decided.
## Requirements
### Requirement: A selection is turned into a validated deletion plan
The planner SHALL be a pure function mapping a set of selected paths to a `DeletionPlan` that lists each item to be removed with its safety tier and allocated size, totals the reclaimable bytes, and groups the totals by tier. The planner SHALL exclude any `NEVER`/blacklisted path from the plan, recording it as refused with a reason. The planner SHALL ALSO refuse any path that is in the user exclusion set (or nested under a member of it), recording it as refused with a distinct "user-protected" reason; effective protection is therefore `NEVER` **or** user-excluded. The planner SHALL de-duplicate nested selections so that a selected ancestor subsumes its selected descendants without double-counting sizes.

#### Scenario: Plan lists items and totals reclaimable bytes
- **WHEN** the planner is given a selection of files and folders
- **THEN** the resulting plan contains an entry for each removable item with its tier and allocated size, and a reclaimable total equal to the sum of the de-duplicated items' sizes

#### Scenario: Protected paths are refused, never planned
- **WHEN** the selection includes a `NEVER`/blacklisted path (e.g. `/System/...`)
- **THEN** that path is excluded from the removable items and recorded as refused with a reason, and the plan's removable set contains no `NEVER`-tier path

#### Scenario: User-excluded paths are refused with a user-protected reason
- **WHEN** the selection includes a path that the user has protected (or a path nested under a protected folder)
- **THEN** that path is excluded from the removable items and recorded as refused with a "user-protected" reason, distinct from the system-protected reason

#### Scenario: Edge case — nested selection is de-duplicated
- **WHEN** the selection contains both a folder and a file inside that folder
- **THEN** the plan keeps only the ancestor folder and counts the reclaimable bytes once, not twice

#### Scenario: Edge case — empty or all-refused selection yields an empty plan
- **WHEN** the selection is empty, or contains only `NEVER` or user-excluded paths
- **THEN** the plan has zero removable items and a zero reclaimable total, and represents a no-op

### Requirement: Required confirmation strength is derived from the plan
The planner SHALL compute the required confirmation level from the highest safety tier among the plan's removable items: `SAFE` requires a simple confirmation; `CACHE` requires a confirmation carrying a "will be regenerated" warning; `RISKY` requires an explicit type-to-confirm. Choosing permanent deletion SHALL escalate the required confirmation by one step. A `NEVER` item can never appear in a plan and therefore has no confirmation level.

#### Scenario: Highest tier sets the confirmation level
- **WHEN** a plan contains both `CACHE` and `RISKY` items
- **THEN** the required confirmation is type-to-confirm (driven by the `RISKY` item), not the weaker `CACHE` level

#### Scenario: Edge case — safe-only plan requires only a simple confirmation
- **WHEN** a plan contains only `SAFE` items and move-to-Trash is selected
- **THEN** the required confirmation is the simple level

#### Scenario: Edge case — permanent deletion escalates confirmation
- **WHEN** the same plan is switched from move-to-Trash to permanent deletion
- **THEN** the required confirmation level is escalated by one step relative to the move-to-Trash case

