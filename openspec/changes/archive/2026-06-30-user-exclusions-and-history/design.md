## Context

M4 adds the first **persistent state** to the app (everything before was computed fresh from a scan): a user exclusion set and a cleanup history. Both are small, user-owned data that must survive launches. The design keeps faith with the established pattern — pure decision logic in `CleanupCore` (exclusion membership, history records), side effects in `CleanupScan` (a JSON store), SwiftUI in the app — and preserves the non-negotiable safety guarantee: exclusions can only *add* protection, and the hardcoded `NEVER` blacklist plus the executor's independent re-check are untouched.

There is a nice irony worth noting: the app's own persisted state lives under `~/Library/Application Support/<bundle id>` — exactly the kind of `RISKY` location the classifier warns about. The store is therefore namespaced under the bundle id and the app never offers to clean its own container.

## Goals / Non-Goals

**Goals:**
- A persisted, user-managed set of protected paths that augments (never replaces) the hardcoded blacklist.
- Pure, ancestor-aware membership: a path is excluded if it or any ancestor is in the set.
- The deletion planner refuses user-excluded paths exactly as it refuses `NEVER` paths, with a distinct "user-protected" reason.
- A persisted, append-only, timestamped cleanup history with reclaimed totals and outcome counts, shown newest-first.
- A small JSON store with injectable read/write so all logic is unit-tested without real files.

**Non-Goals:**
- Editing/removing the hardcoded system blacklist (absolute, separate).
- Scheduled/automatic cleaning; cloud sync; signing/notarization.
- Any path by which an exclusion could *reduce* protection.

## Decisions

### D1: Exclusions augment, never override — protection is monotonic
The effective protection for an action is `hardcoded NEVER  OR  user-excluded`. A path can be added to the exclusion set to gain protection; nothing in the exclusion system can mark a `NEVER` path as deletable.
**Why:** keeps the core safety guarantee a strict superset; the exclusion feature can only make the tool safer. 
**Alternative:** a general allow/deny ruleset (could whitelist) — rejected; reintroduces a way to expose protected paths.

### D2: Membership is pure and ancestor-aware
`isExcluded(path, set)` returns true if the normalized path equals, or is nested under, any path in the set. The planner takes the exclusion set as an injected input and refuses matches.
**Why:** protecting a folder must protect everything inside it; keeping it pure (set passed in) means the planner stays unit-testable and the existing `NEVER` invariant test pattern extends naturally. 
**Alternative:** exact-path matching only — rejected; protecting a folder wouldn't protect its contents.

### D3: Planner refusal reason distinguishes user-protected from system-protected
A path refused because it is user-excluded gets a reason like "Protected by you" — separate from the SIP/`NEVER` reason — so the UI can explain *why* and offer to unprotect.
**Why:** transparency; the two protections have different remedies (one is removable by the user, one never is). 
**Alternative:** a single generic "refused" reason — rejected; loses actionable context.

### D4: A small injectable JSON store under Application Support
Persistence is a `Store` abstraction with `load()/save()` over a codable payload, backed by a JSON file at `~/Library/Application Support/<bundle id>/state.json`. File read/write is injected (a closure/protocol), so `CleanupCore`/logic tests use an in-memory fake; only a thin platform test touches a temp directory.
**Why:** keeps decision logic pure and hermetically testable; JSON is human-inspectable and trivially versionable. 
**Alternative:** `UserDefaults` — workable but opaque and awkward for a growing history list; a real file is clearer and portable.

### D5: History is append-only and capped
Each completed cleanup appends one `HistoryEntry` (timestamp, kind, item count, bytes reclaimed, outcome counts). The list is capped (most-recent N, e.g. 500) to bound file growth; presentation is newest-first.
**Why:** an audit trail should be immutable and cheap; a cap prevents unbounded growth. Timestamps are passed in (the pure core does not read the clock). 
**Alternative:** unbounded history / mutable entries — rejected; growth and integrity concerns.

### D6: The app never cleans its own state container
The path of the app's Application Support container is excluded from being offered for deletion (added to the effective protection at runtime), so a user can't accidentally delete the tool's own exclusions/history from within the tool.
**Why:** avoid self-foot-guns; the store must be stable. 
**Alternative:** allow it — rejected; confusing and destructive.

## Risks / Trade-offs

- **A user expects an exclusion to also hide the path from the scan view** → for M4 exclusions affect *actions* (never deletable/offered), and the UI marks excluded tiles distinctly; hiding from the view entirely is a later option (decision: mark, don't hide, so size is still visible).
- **Persisted file corrupted / unreadable** → the store loads defaults (empty exclusions, empty history) on any decode failure rather than crashing; a corrupt file never blocks launch.
- **Clock skew / ordering of history** → entries store an absolute timestamp passed in by the shell; display sorts by it; the core never reads the clock (keeps it pure/testable).
- **Bytes-reclaimed accuracy** → recorded from the plan's reclaimable total / executor results, which are best-effort estimates (consistent with M2); history notes them as reclaimed-estimate.
- **Exclusion set growth** → small, user-curated; no cap needed, but membership is O(n·depth) — fine for realistic sizes.

## Migration Plan

Additive; introduces a new persisted file that does not exist yet, so first launch simply starts with empty exclusions/history. Modifies `deletion-planning` (refusal now also covers user exclusions) — backward compatible (strictly more refusals, never fewer). Land on `development` behind CI. Rollback = revert; the state file is ignored by older builds and the planner reverts to blacklist-only refusal.

## Open Questions

- History entry granularity: one entry per cleanup batch (chosen) vs per item — batch keeps it readable; per-item detail can live behind a disclosure later.
- Whether to let users export/clear history in M4 or defer (leaning: offer "clear history", defer export).
- State file schema versioning: add a `version` field now (cheap) to ease future migrations — yes, include it.
- Should excluded tiles be visually hidden or just badged in the treemap — leaning badged (keep size visible).
