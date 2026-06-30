# Contributing

Thanks for your interest in **osx-cleanup-utility**. This project is built with
**agentic engineering, not vibe coding** — a spec-driven, test-first SDLC (see
[*How this was built*](README.md#how-this-was-built--agentic-engineering-not-vibe-coding)
in the README). Contributions follow the same process, whether they come from a
human, an AI agent, or a human directing one.

The short version: **specify before you build, test before you implement, and
leave a paper trail.** A pull request that adds behavior without a spec and
failing-first tests will be asked to add them.

---

## Ground rules (non-negotiable)

1. **Important system files must never be touched.** The hardcoded `NEVER`
   blacklist (`/System`, `/usr` except `/usr/local`, `/bin`, `/sbin`,
   `/private/var/vm`, the sealed system volume) and the user exclusion set are
   absolute. Any change near deletion **must** keep the invariant tests green:
   *no input, under any exclusion set, may put a `NEVER` path in a deletion
   plan.* Add to the protection; never weaken it.
2. **TDD is required.** Red → Green → Refactor. Write the failing test first,
   make it pass with the minimal change, then refactor. Run `swift test` after
   every step.
3. **Keep the functional core pure.** Decision logic lives in `CleanupCore` with
   **no I/O and no UI imports**. Side effects (filesystem, `Process`, `tmutil`,
   SwiftUI) live in `CleanupScan` / `OSXCleanupApp`. If you need I/O in a test,
   inject it — don't reach for the real thing.
4. **Ground facts in sources.** If you add or change a safety classification,
   cite an authoritative source (Apple docs, the tool's own docs, etc.) in the
   spec/PR. We do not classify from memory.

---

## Architecture (where things go)

| Target | Kind | Put here |
| --- | --- | --- |
| `CleanupCore` | pure library | Classifier, planner, size roll-up, treemap layout, history records, exclusion set — **pure, exhaustively unit-tested, zero I/O** |
| `CleanupScan` | platform library | Filesystem scanner, Full Disk Access probe, command runner, `tmutil`, JSON store — Foundation I/O, **with the effect injected** so it's testable |
| `OSXCleanupApp` | SwiftUI app | Views + view models. **No decision logic** — it calls into the core |

Rule of thumb: if you can't unit-test it without touching the real filesystem
or spawning a real process, the logic is in the wrong layer or the effect needs
to be injected.

---

## Development setup

- **macOS 14+** and **Xcode** installed (not just Command Line Tools — the Swift
  testing libraries ship with Xcode).

```bash
# Point the toolchain at Xcode (only needed if `swift test` can't find Testing/XCTest)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

swift build                 # build core + platform + app
swift test                  # run the full suite (must be green before a PR)
swift run osx-cleanup       # launch the app
```

Tests use the **Swift Testing** framework and never touch your real files — the
filesystem, Trash, and external tools are injected with fakes, and the few
integration tests operate only inside temporary directories.

---

## The workflow: OpenSpec, phase by phase

All work flows through [OpenSpec](https://github.com/Fission-AI/OpenSpec).
Proposals, designs, specs, and task lists live under `openspec/`; the current
specification baseline is `openspec/specs/`, and completed work is in
`openspec/changes/archive/`. If you use Claude Code, the `/opsx:*` skills drive
each phase; otherwise use the `openspec` CLI directly.

### 1. Explore (optional, for anything non-trivial)
Think through the problem first — investigate the codebase, research with
**cited sources**, sketch options. No code. (`/opsx:explore`)

### 2. Propose
Create the change and its artifacts:

```bash
openspec new change <kebab-case-name>
# then author, in openspec/changes/<name>/:
#   proposal.md  — why + which capabilities change
#   design.md    — how, with decisions AND alternatives considered
#   specs/       — Given/When/Then requirements, ≥2 edge cases each
#   tasks.md     — TDD-sequenced (tests → implement → refactor)
openspec validate <name> --strict
```

Spec requirements use `SHALL`/`MUST`, and **every requirement needs at least one
scenario** with `#### Scenario:` + `WHEN`/`THEN` (exactly 4 hashes — 3 fails
silently). Each feature should include **at least two edge-case scenarios**.

### 3. Apply
Implement the tasks **test-first**, marking each `- [ ]` → `- [x]` as you go and
running `swift test` after each. (`/opsx:apply <name>`)

### 4. Archive
Once tasks are done and the suite is green, archive — this folds the accepted
delta specs into the baseline:

```bash
openspec archive <name>
```

> Note: a few early changes were spec-synced by hand; those are archived with
> `--skip-specs`. New changes should archive normally so the baseline stays
> authoritative.

---

## Branches, commits, releases

```
feature/*  ──PR──▶  development  ──PR──▶  main
                    (experimental CI)     (released, semver-tagged)
```

- Branch off `development` for features; PR into `development`, then into `main`.
- **CI runs on every PR and on pushes to `development`/`main`** (`swift build` +
  `swift test` on macOS). A red check blocks the merge.
- **Conventional Commits**: `feat:`, `fix:`, `docs:`, `chore:`, `test:`,
  `refactor:`; breaking changes use `feat!:` or a `BREAKING CHANGE:` footer.
- **Semantic Versioning.** Releases are cut by tagging `vX.Y.Z` on `main`, which
  triggers the release workflow (builds and publishes an unsigned `.app`).

---

## Pull request checklist

- [ ] An OpenSpec change exists for the behavior (`proposal`/`design`/`specs`/`tasks`).
- [ ] `openspec validate <name> --strict` passes.
- [ ] New behavior was **test-first**: a test that failed before the code existed.
- [ ] `swift build` and `swift test` are green locally (and on CI).
- [ ] Decision logic is in `CleanupCore` (pure); effects are injected.
- [ ] The `NEVER`/safety invariants still hold; protection was only ever added.
- [ ] Any new/changed classification cites a source.
- [ ] README/roadmap updated if user-facing behavior changed.

---

## Style

- **Functional programming favored** over imperative; prefer value types,
  immutability, and `map`/`filter`/`reduce`.
- **Type everything** — no implicit `Any`; make illegal states unrepresentable
  with enums where you can.
- **Clean, self-documenting code.** Comments explain *why*, not *what*. Match the
  surrounding style.

By contributing you agree your work is licensed under the project's
[MIT License](LICENSE).
