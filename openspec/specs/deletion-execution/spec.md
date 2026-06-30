# deletion-execution Specification

## Purpose
Defines how a deletion plan is carried out: items are moved to the Trash by default (reversible), with permanent deletion only as an explicit opt-in and never as a silent fallback. The executor re-classifies every item immediately before removal and refuses anything resolving to `NEVER` (defense in depth), tolerates per-item failure without aborting the batch, and returns a per-item result for the whole plan.

## Requirements

### Requirement: Plans execute via Trash by default, with permanent deletion as an explicit opt-in
The executor SHALL remove a plan's items by moving them to the Trash by default, so the operation is reversible. Permanent deletion SHALL be performed only when explicitly requested for that operation. If moving an item to the Trash fails, the executor SHALL report that item as failed and SHALL NOT silently fall back to permanent deletion.

#### Scenario: Items are moved to the Trash by default
- **WHEN** a plan is executed without requesting permanent deletion
- **THEN** each removable item is moved to the Trash and reported as trashed, leaving it recoverable

#### Scenario: Permanent deletion happens only when explicitly requested
- **WHEN** a plan is executed with permanent deletion explicitly requested
- **THEN** items are removed permanently and reported as deleted

#### Scenario: Edge case — Trash failure is reported, never silently made permanent
- **WHEN** moving an item to the Trash fails (e.g. on a volume without a Trash)
- **THEN** that item is reported as failed and is not permanently deleted as a fallback

### Requirement: Execution re-validates each item and tolerates partial failure
Immediately before removing each item, the executor SHALL re-classify it and SHALL refuse to remove anything that resolves to `NEVER`, regardless of the plan. The executor SHALL continue past individual failures and SHALL return a per-item result — trashed, deleted, failed (with reason), or refused (with reason) — for every item.

#### Scenario: A protected item is refused even if present in the plan
- **WHEN** execution encounters an item that re-classifies as `NEVER`
- **THEN** the executor refuses to remove it, reports it as refused with a reason, and continues with the rest

#### Scenario: Edge case — a vanished item does not abort the batch
- **WHEN** an item no longer exists at execution time
- **THEN** it is reported as failed (gone) and the remaining items are still processed

#### Scenario: Edge case — per-item results are returned for the whole batch
- **WHEN** a plan with several items is executed and some succeed while others fail
- **THEN** the result contains an outcome entry for every item, and the successes are removed regardless of the failures
