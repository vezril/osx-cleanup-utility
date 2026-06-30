// CleanupScan — the platform (imperative shell) layer.
//
// Foundation-backed filesystem I/O that the pure CleanupCore cannot do:
// the recursive scanner and Full Disk Access detection. Kept in a library
// target (not the SwiftUI executable) so it can be integration-tested against
// temporary directories.

import Foundation

/// Namespace marker for the platform layer.
public enum CleanupScan {}
