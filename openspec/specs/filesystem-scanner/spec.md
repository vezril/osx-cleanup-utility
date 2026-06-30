# filesystem-scanner Specification

## Purpose
Defines the recursive disk scanner: it enumerates a directory tree into immutable, size-attributed records (logical and allocated size), streaming results so large scans stay responsive and cancellable. It is robust to permission errors and vanished entries, never follows symlinks, counts hardlinked inodes once, and prunes descent into protected/`NEVER`-tier subtrees so they are never enumerated.

## Requirements

### Requirement: Recursive size-attributed scan
The scanner SHALL recursively enumerate a given root directory and produce, for each entry, an immutable record carrying its path, whether it is a directory, its logical size, and its allocated (on-disk) size. Results SHALL be streamed incrementally rather than returned only after the whole tree is walked, and the scan SHALL be cancellable.

#### Scenario: Files and folders are enumerated with sizes
- **WHEN** the scanner runs over a directory containing nested files and subfolders
- **THEN** it emits a record for each file and directory with its allocated and logical size, and a parent directory's rolled-up size equals the sum of its descendants' allocated sizes

#### Scenario: Scan can be cancelled mid-walk
- **WHEN** a scan over a large tree is cancelled before completion
- **THEN** enumeration stops promptly, no further records are emitted, and partial results already produced remain valid

#### Scenario: Edge case — unreadable entry is skipped, not fatal
- **WHEN** the scan encounters a file or directory it cannot read (permission denied) or that vanishes mid-scan
- **THEN** that entry is recorded as skipped and the scan continues, without crashing or aborting the whole walk

#### Scenario: Edge case — empty root
- **WHEN** the scanner runs over an empty directory
- **THEN** it completes successfully and reports the root with zero descendant size

### Requirement: Scan does not follow symlinks, counts inodes once, and never enters blacklisted trees
The scanner SHALL NOT traverse symbolic links, SHALL count a hardlinked file's size only once per scan, and SHALL prune descent into any hard-blacklisted / `NEVER`-tier subtree so such paths are never enumerated or sized.

#### Scenario: Symlinks are not followed
- **WHEN** the tree contains a symlink pointing back into an ancestor directory
- **THEN** the scanner records the symlink itself but does not traverse through it, so the walk terminates without cycling or double-counting

#### Scenario: Hardlinked file counted once
- **WHEN** two directory entries are hardlinks to the same inode within the scanned tree
- **THEN** the file's allocated size contributes to the total only once

#### Scenario: Edge case — blacklisted subtree is pruned
- **WHEN** a scan root would otherwise descend into a hard-blacklisted path (e.g. `/System` or `/private/var/vm`)
- **THEN** the scanner does not enumerate inside it and emits no cleanable records for that subtree

#### Scenario: Edge case — symlink loop does not hang
- **WHEN** two symlinks point at each other forming a loop
- **THEN** the scan completes without infinite recursion because symlinks are never followed
