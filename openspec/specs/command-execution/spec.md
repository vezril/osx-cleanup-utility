# command-execution Specification

## Purpose
TBD - created by archiving change delegated-cleanup. Update Purpose after archive.
## Requirements
### Requirement: Execute only vetted commands as argument vectors
The command runner SHALL execute a tool by launching its binary directly with a literal argument array, capturing stdout, stderr, and the exit status. It SHALL NOT invoke a shell and SHALL NOT interpolate any value into a command string. A non-zero exit status SHALL be reported as a failure, never treated as success.

#### Scenario: A command runs and its output and exit status are captured
- **WHEN** the runner executes a provider's binary with its argument vector
- **THEN** it returns the captured stdout, stderr, and exit status of that process

#### Scenario: Edge case — no shell is used and arguments are passed literally
- **WHEN** an argument contains characters that a shell would interpret (e.g. `;`, `*`, `$()`)
- **THEN** the character is passed to the binary as a literal argument and is never interpreted, because no shell is involved

#### Scenario: Edge case — a non-zero exit is reported as failure
- **WHEN** the executed command exits with a non-zero status
- **THEN** the runner reports a failure with the captured stderr, rather than reporting success

### Requirement: Runs are bounded by a timeout and can be cancelled
The runner SHALL apply a timeout to each command and SHALL allow an in-progress command to be cancelled, terminating the process. A timed-out or cancelled run SHALL be reported as such rather than hanging.

#### Scenario: A long-running command is cancelled
- **WHEN** an in-progress command is cancelled
- **THEN** the process is terminated and the run is reported as cancelled

#### Scenario: Edge case — a command exceeding the timeout is terminated
- **WHEN** a command runs longer than its timeout
- **THEN** it is terminated and reported as timed out, so the app does not hang

