## ADDED Requirements

### Requirement: Semantic-versioned release branch model
The project SHALL follow a `feature/* → development → main` branch model and semantic versioning. Releases SHALL be identified by `vX.Y.Z` tags on `main`, and the documented convention MUST be that `main` holds released versions while `development` holds experimental changes.

#### Scenario: Release is cut from main with a semver tag
- **WHEN** a maintainer tags a commit on `main` with a valid semantic version such as `v0.1.0`
- **THEN** that tag is recognized as a release point and triggers the release workflow

#### Scenario: Edge case — non-semver or non-main tag does not release
- **WHEN** a tag that is not a valid `vX.Y.Z` semantic version is pushed, or a `vX.Y.Z` tag is created on a branch other than `main`
- **THEN** the release workflow does not publish a release, avoiding accidental or malformed releases

#### Scenario: Edge case — development branch never auto-publishes a release
- **WHEN** changes land on `development` without a `vX.Y.Z` tag on `main`
- **THEN** no GitHub Release is produced (experimental builds remain CI artifacts only, not published releases)

### Requirement: Unsigned build artifact is published on release
On a release, the workflow SHALL build the macOS app and publish an **unsigned** `.app`/`.zip` artifact attached to a GitHub Release. Code signing and notarization are explicitly out of scope for this milestone and MUST NOT be required for the release to succeed.

#### Scenario: Release publishes a downloadable unsigned artifact
- **WHEN** the release workflow runs for a `vX.Y.Z` tag on `main`
- **THEN** it builds the app, packages it as a `.zip`, and attaches the artifact to a GitHub Release for that version, without requiring any Apple Developer signing secret

#### Scenario: Edge case — no signing secrets present
- **WHEN** the release workflow runs in a repository with no Apple Developer certificate or notarization credentials configured
- **THEN** the workflow still completes successfully and publishes the unsigned artifact (it does not fail for missing signing configuration)

#### Scenario: Edge case — build failure aborts the release
- **WHEN** the app fails to build during the release workflow
- **THEN** no GitHub Release is published and no partial/empty artifact is attached, so a broken build never reaches users
