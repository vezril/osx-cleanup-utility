# ci-pipeline Specification

## Purpose
Defines continuous integration for the project: a GitHub Actions workflow on a macOS runner that builds and tests every pull request and every push to the long-lived `development` and `main` branches, failing the status check on any build or test failure so the released and experimental lines are never left unverified.

## Requirements

### Requirement: Continuous integration builds and tests every change
The project SHALL provide a GitHub Actions workflow that runs on a macOS runner and executes `swift build` and `swift test` on every pull request and on every push to the `development` and `main` branches. The workflow MUST report a failing status check if either the build or any test fails.

#### Scenario: Passing change reports green
- **WHEN** a pull request is opened whose code builds and whose tests all pass
- **THEN** the CI workflow runs build and test steps on a macOS runner and reports a successful (green) status check on the pull request

#### Scenario: Failing test blocks the change
- **WHEN** a pull request introduces a failing test
- **THEN** the `swift test` step exits non-zero and the workflow reports a failing (red) status check, surfacing the failing test name in the logs

#### Scenario: Edge case — compilation error fails before tests run
- **WHEN** a pushed change does not compile
- **THEN** the `swift build` step fails, the test step does not execute, and the overall check is red with the compiler error visible in the logs

#### Scenario: Edge case — push to a protected branch is verified
- **WHEN** a commit is pushed directly to `development` or `main`
- **THEN** the same build-and-test workflow runs for that push, so the released and experimental lines are never left unverified
