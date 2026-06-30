# user-exclusions Specification

## Purpose
TBD - created by archiving change user-exclusions-and-history. Update Purpose after archive.
## Requirements
### Requirement: Users can protect and unprotect paths, persisted across launches
The app SHALL let the user add any path to, and remove any path from, a personal exclusion set. The set SHALL be persisted and restored across app launches. Adding a path already covered by the set SHALL be idempotent.

#### Scenario: A protected path is remembered
- **WHEN** the user adds a path to the exclusion set and the app is relaunched
- **THEN** the path is still in the exclusion set after the persisted state is loaded

#### Scenario: Unprotecting removes the path
- **WHEN** the user removes a previously protected path
- **THEN** the path is no longer in the exclusion set

#### Scenario: Edge case — adding an already-protected path is idempotent
- **WHEN** the user adds a path that is already in the set
- **THEN** the set is unchanged and contains no duplicate entry

#### Scenario: Edge case — a corrupt or missing store loads an empty set
- **WHEN** the persisted state is missing or cannot be decoded
- **THEN** the exclusion set loads as empty and the app does not crash

### Requirement: Exclusion membership is ancestor-aware and only adds protection
Membership SHALL be ancestor-aware: a path is excluded if it equals, or is nested under, any path in the exclusion set. Exclusions SHALL only ever add protection — no exclusion operation SHALL cause a hardcoded `NEVER` path to become deletable.

#### Scenario: A descendant of a protected folder is protected
- **WHEN** a folder is in the exclusion set and a file inside it is tested
- **THEN** the file is reported as excluded

#### Scenario: Edge case — an unrelated path is not protected
- **WHEN** a path that is neither in the set nor under any set member is tested
- **THEN** it is reported as not excluded

#### Scenario: Edge case — exclusions cannot weaken NEVER protection
- **WHEN** the exclusion set is manipulated in any way
- **THEN** a hardcoded `NEVER` path remains protected regardless, because effective protection is "NEVER OR user-excluded"

