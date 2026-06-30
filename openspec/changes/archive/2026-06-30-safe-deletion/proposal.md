## Why

M1 lets users *see* their disk usage and the safety tier of every location, but it is strictly read-only. M2 delivers the actual payoff: **reclaiming space by deleting selected files and folders** — safely. This is the highest-stakes milestone, because for the first time the app removes data. So the design centers on defense-in-depth: a pure, tested **deletion planner** that is the single gate every removal must pass, **move-to-Trash by default** (so deletions are reversible), and **tiered confirmation** that scales friction to risk. Important system files remain untouchable — enforced again at execution time, not just in the UI. Per our scope, M2 is **Mechanism A only** (direct file/folder removal); delegated cleanup (`tmutil`/`docker`/`brew`) is M3.

## What Changes

- Add a pure **deletion planner** in `CleanupCore`: given a user selection, produce a `DeletionPlan` that lists exactly what would be removed, totals the reclaimable bytes, **refuses to include any `NEVER`/blacklisted path** (recording why), and de-duplicates redundant selections (a selected folder subsumes its selected descendants).
- Add a pure **confirmation policy**: the plan's highest tier determines the required confirmation strength — `SAFE` → simple confirm; `CACHE` → confirm with "apps will regenerate" warning; `RISKY` → **type-to-confirm**; `NEVER` → cannot be planned at all.
- Add **deletion execution** in the platform layer: move items to the **Trash by default** (reversible), with an explicit opt-in for permanent deletion. Every item is **re-classified at execution time** and refused if it resolves to `NEVER` (defense in depth). Execution reports **per-item results** and continues past individual failures (partial success).
- Add **curated safe presets**: one-click selections of known-safe categories (e.g. Trash, Xcode `DerivedData`, user caches) drawn from the classifier, plus full **manual multi-select** of individual files and folders.
- Extend the M1 UI: multi-select in the treemap/list, a **dry-run plan preview** (what will be deleted, how much is reclaimed, the tier breakdown) shown before anything happens, the tiered confirmation flow, and a post-deletion result summary with a rescan.

Non-goals (explicit): no delegated cleanup or APFS snapshot reclamation (M3); no scheduling, exclusion lists, or background cleaning (M4+); no code signing/notarization. Permanent deletion is supported but never the default and never auto-selected.

## Capabilities

### New Capabilities
- `deletion-planning`: a pure function turning a selection into a validated `DeletionPlan` — excludes `NEVER`/blacklisted paths, de-duplicates nested selections, totals reclaimable bytes per tier, and derives the required confirmation strength.
- `deletion-execution`: platform-layer execution of a plan — move-to-Trash (default) or permanent delete, re-validated against the classifier per item, with per-item results and partial-failure tolerance.
- `safe-deletion-presets`: curated, classifier-backed one-click selections of known-safe categories, alongside manual multi-selection.

### Modified Capabilities
- `disk-usage-treemap`: the M1 read-only treemap gains multi-selection and a path into the deletion flow. The "no deletion affordance" guarantee is intentionally replaced by a gated, confirmation-protected delete action; the relevant requirement is updated to reflect that deletion now exists but is gated.

## Impact

- **New `CleanupCore` modules**: `DeletionPlan`, the planner, and the confirmation-policy function — all pure and unit-tested. This is the new safety spine for removal.
- **New `CleanupScan` (platform) code**: a deletion executor using `FileManager.trashItem(at:)` (default) / `removeItem` (opt-in), with re-classification and per-item result reporting.
- **App-shell changes**: multi-select state, plan-preview sheet, tiered confirmation dialogs (including type-to-confirm), permanent-vs-Trash toggle, and post-deletion rescan.
- **Safety/UX**: deletions are reversible by default (Trash); friction scales with tier; nothing is removed without an explicit, tier-appropriate confirmation; a broken/locked item never aborts the whole batch.
- **Specs**: three new capability specs plus a delta to `disk-usage-treemap`; baseline updated on archive.
- **Dependencies**: none new expected (Foundation `FileManager` Trash APIs + SwiftUI).
