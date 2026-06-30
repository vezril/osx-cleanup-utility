# full-disk-access Specification

## Purpose
Defines how the app handles macOS Full Disk Access (TCC): it detects whether access is granted by probing known protected locations, never requests the permission programmatically (macOS forbids it), guides the user to grant it via a deep link to the Settings pane, and degrades gracefully — scanning everything reachable and clearly marking hidden regions rather than omitting them or reporting them as clean.

## Requirements

### Requirement: Full Disk Access state is detected
The app SHALL detect whether it currently has Full Disk Access by probing one or more known TCC-protected locations and observing whether they are readable. Detection SHALL NOT attempt to request the permission programmatically (macOS forbids it) and SHALL treat ambiguous results as "not granted".

#### Scenario: Granted access is detected
- **WHEN** the app can read a known TCC-protected location
- **THEN** Full Disk Access is reported as granted and protected areas are eligible to be scanned

#### Scenario: Missing access is detected
- **WHEN** reading a known TCC-protected location fails with a permission error
- **THEN** Full Disk Access is reported as not granted

#### Scenario: Edge case — ambiguous probe is treated as not granted
- **WHEN** the probe result is inconclusive (e.g. the probe path does not exist on this machine)
- **THEN** the app reports access as not granted rather than assuming it is available

### Requirement: The app guides the user to grant access and degrades gracefully without it
When Full Disk Access is not granted, the app SHALL present onboarding that explains why it is needed and SHALL deep-link to the Privacy & Security settings pane. Regardless of the grant, the app SHALL still scan everything reachable and SHALL clearly mark regions that are hidden due to missing access rather than omitting them silently.

#### Scenario: Onboarding offers a deep link to settings
- **WHEN** the user is shown the Full Disk Access onboarding
- **THEN** it explains the reason and provides an action that opens the macOS Privacy & Security → Full Disk Access settings pane

#### Scenario: Scan proceeds without access and marks hidden regions
- **WHEN** a scan runs while Full Disk Access is not granted
- **THEN** it still scans all FDA-free locations (caches, Trash, developer data, package caches) and represents the protected, unreadable regions with a distinct "needs Full Disk Access" indicator

#### Scenario: Edge case — access granted after onboarding is reflected on rescan
- **WHEN** the user grants Full Disk Access and triggers a rescan
- **THEN** the previously hidden protected regions are now scanned and shown without restarting the app being required by the design

#### Scenario: Edge case — no false "clean" claims for hidden regions
- **WHEN** protected regions remain unreadable
- **THEN** the app never reports them as empty or already-clean; it reports them as unknown/hidden pending access
