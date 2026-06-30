import Foundation

// Full Disk Access (TCC) detection.
//
// macOS forbids requesting Full Disk Access programmatically, so the only honest
// approach is: probe known protected locations, infer the state, guide the user
// to grant it, and degrade gracefully. The *decision* (`evaluate`) is pure and
// injectable for testing; `detect()` performs the real probes.

public enum FullDiskAccess {

    public enum Status: Equatable, Sendable {
        case granted
        case notGranted
    }

    /// Outcome of probing one protected path.
    public enum ProbeOutcome: Equatable, Sendable {
        case readable          // we could read it → access present
        case permissionDenied  // exists but blocked by TCC → no access
        case missing           // not present on this machine → inconclusive
    }

    /// Pure decision: access is granted iff at least one probe was readable.
    /// Anything else — denials, missing paths, no probes — is treated
    /// conservatively as not granted.
    public static func evaluate(probes: [ProbeOutcome]) -> Status {
        probes.contains(.readable) ? .granted : .notGranted
    }

    /// Known TCC-protected locations to probe, relative to the user's home.
    static let probePaths: [String] = [
        "Library/Application Support/MobileSync",
        "Library/Mail",
        "Library/Safari",
    ]

    /// Probe the real filesystem and infer Full Disk Access state.
    public static func detect(homeDirectory: String = NSHomeDirectory()) -> Status {
        let outcomes = probePaths.map { rel -> ProbeOutcome in
            probe(homeDirectory + "/" + rel)
        }
        return evaluate(probes: outcomes)
    }

    /// The URL of the Full Disk Access settings pane, for the onboarding deep link.
    public static let settingsURLString =
        "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

    // MARK: - private

    static func probe(_ path: String) -> ProbeOutcome {
        var st = stat()
        guard lstat(path, &st) == 0 else { return .missing }
        // Try to open the directory / read the file to detect a TCC denial.
        let fd = open(path, O_RDONLY)
        if fd >= 0 {
            close(fd)
            return .readable
        }
        return errno == EACCES || errno == EPERM ? .permissionDenied : .missing
    }
}
