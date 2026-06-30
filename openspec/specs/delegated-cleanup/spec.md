# delegated-cleanup Specification

## Purpose
TBD - created by archiving change delegated-cleanup. Update Purpose after archive.
## Requirements
### Requirement: Registry of delegated providers with vetted commands
The app SHALL maintain a registry of delegated cleanup providers, each defined by a tool binary to detect, a category, a human-readable description, and a **fixed argument vector** for its cleanup command (and, where supported, a separate dry-run argument vector). Commands SHALL be hardcoded literals; no provider command SHALL be constructed from user input or run through a shell.

#### Scenario: Providers expose a fixed command for a known tool
- **WHEN** the registry is inspected for a known provider (e.g. Homebrew)
- **THEN** it yields the tool's binary name, category, description, and a literal argument vector for its cleanup command

#### Scenario: Edge case — every provider command is a literal argument vector
- **WHEN** any provider's command is examined
- **THEN** it is an array of literal arguments with no shell metacharacters interpreted and no interpolation of external input

#### Scenario: Edge case — a dry-run command is distinct from the destructive command
- **WHEN** a provider that supports preview is inspected
- **THEN** its dry-run argument vector is separate from its cleanup argument vector, so a preview never performs the cleanup

### Requirement: Detect installed tools and degrade gracefully
The app SHALL detect whether each provider's tool is installed by checking a fixed set of known install locations (not the shell `PATH`, which a GUI app does not inherit) and SHALL offer only providers whose tool is found and executable. Absent tools SHALL be shown as not detected rather than failing.

#### Scenario: An installed tool is detected and offered
- **WHEN** a provider's binary exists and is executable at a known location
- **THEN** that provider is reported as available and offered for cleanup

#### Scenario: Edge case — an absent tool is not offered
- **WHEN** none of a provider's known locations contain its binary
- **THEN** the provider is reported as not detected and no cleanup is offered for it, without error

#### Scenario: Edge case — detection does not rely on PATH
- **WHEN** detection runs inside the app
- **THEN** it resolves tools from known absolute locations, so a tool installed in a standard location is found even though the app has no shell `PATH`

