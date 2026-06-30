# safety-classifier Specification

## Purpose
Defines the safety spine of the cleanup utility: a pure, deterministic function that maps any filesystem path to exactly one of five tiers (`SAFE`, `CACHE`, `DELEGATED`, `RISKY`, `NEVER`) with a human-readable reason, grounded in the sourced research ruleset. SIP/system-protected paths are classified `NEVER` unconditionally and non-bypassably, so no input — including traversal tricks — can ever cause a protected path to be surfaced as deletable.

## Requirements

### Requirement: Every path is classified into one of five safety tiers with a reason
The classifier SHALL be a pure function mapping any filesystem path to exactly one tier — `SAFE`, `CACHE`, `DELEGATED`, `RISKY`, or `NEVER` — together with a human-readable reason. Classification SHALL be deterministic and perform no I/O. Known locations SHALL be classified per the sourced research ruleset (e.g. `~/.Trash` and Xcode `DerivedData` → `SAFE`; `~/Library/Caches` → `CACHE`; APFS snapshots / `Docker.raw` / Homebrew cache → `DELEGATED`; `~/Library/Application Support`, iOS backups, `~/Downloads` → `RISKY`).

#### Scenario: Known safe location is classified SAFE
- **WHEN** the classifier is given `~/Library/Developer/Xcode/DerivedData`
- **THEN** it returns tier `SAFE` with a reason explaining the contents are regenerable build artifacts

#### Scenario: Known cache is classified CACHE
- **WHEN** the classifier is given `~/Library/Caches`
- **THEN** it returns tier `CACHE` with a reason noting apps will regenerate it

#### Scenario: Edge case — unknown path defaults conservatively
- **WHEN** the classifier is given a path matching no rule
- **THEN** it returns a conservative tier (never `SAFE`) — `RISKY` for user-owned data — with a reason stating it is unrecognized

#### Scenario: Edge case — most-specific rule wins
- **WHEN** a path matches both a broad rule and a more specific nested rule (e.g. an `Archives` folder inside the developer directory)
- **THEN** the most specific rule determines the tier, not the broader parent rule

### Requirement: System and SIP-protected paths are unconditionally NEVER and non-bypassable
The classifier SHALL classify hard-blacklisted paths — `/System`, `/usr` (except `/usr/local`), `/bin`, `/sbin`, `/private/var/vm`, and the sealed system volume — as tier `NEVER`, and this determination SHALL take precedence over every other rule. No input SHALL ever cause such a path to be classified as a deletable tier.

#### Scenario: System path is NEVER
- **WHEN** the classifier is given `/System/Library/CoreServices`
- **THEN** it returns tier `NEVER` with a reason noting it is SIP-protected and cannot be modified

#### Scenario: Blacklist beats any other match
- **WHEN** a path is under a blacklisted root but also resembles a cache-like name
- **THEN** the result is `NEVER`, because the blacklist is evaluated first and unconditionally

#### Scenario: Edge case — /usr/local is not blacklisted
- **WHEN** the classifier is given a path under `/usr/local`
- **THEN** it is NOT classified `NEVER` solely for being under `/usr`, since `/usr/local` is user-writable and SIP-exempt

#### Scenario: Edge case — path normalization cannot bypass the blacklist
- **WHEN** a path reaches a blacklisted location via `.`/`..` segments or a trailing slash (e.g. `/System/../System/Library`)
- **THEN** the classifier normalizes the path and still returns `NEVER`, so traversal tricks cannot bypass protection
