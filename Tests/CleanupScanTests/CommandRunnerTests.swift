import Testing
import Foundation
@testable import CleanupScan

// Safe command runner (tasks 3.1, 3.3). A fake executor is injected, so no real
// process is spawned and we can assert exactly what argv would be launched.

/// Thread-safe recorder for what the runner asked the executor to launch.
private final class Recorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _binary = ""
    private var _args: [String] = []
    var binary: String { lock.withLock { _binary } }
    var args: [String] { lock.withLock { _args } }
    func record(_ b: String, _ a: [String]) { lock.withLock { _binary = b; _args = a } }
}

@Suite("Command runner")
struct CommandRunnerTests {

    @Test("returns captured stdout, stderr, and exit status")
    func capturesOutput() {
        let runner = CommandRunner(executor: { _, _, _ in
            .finished(stdout: "ok", stderr: "", exitCode: 0)
        })
        let result = runner.run(binary: "/bin/echo", args: ["hi"])
        guard case .success(let out) = result else { Issue.record("expected success"); return }
        #expect(out.stdout == "ok")
        #expect(out.exitCode == 0)
    }

    @Test("a non-zero exit is reported as failure, not success")
    func nonZeroIsFailure() {
        let runner = CommandRunner(executor: { _, _, _ in
            .finished(stdout: "", stderr: "boom", exitCode: 3)
        })
        let result = runner.run(binary: "/x", args: [])
        guard case .failure(let out) = result else { Issue.record("expected failure"); return }
        #expect(out.exitCode == 3)
        #expect(out.stderr == "boom")
    }

    @Test("Edge: arguments are passed literally — no shell interpretation")
    func argsPassedLiterally() {
        let rec = Recorder()
        let runner = CommandRunner(executor: { binary, args, _ in
            rec.record(binary, args)
            return .finished(stdout: "", stderr: "", exitCode: 0)
        })
        let nasty = ["cleanup", ";", "rm -rf /", "$(whoami)", "*"]
        _ = runner.run(binary: "/opt/homebrew/bin/brew", args: nasty)
        #expect(rec.binary == "/opt/homebrew/bin/brew")
        #expect(rec.args == nasty)  // verbatim, nothing expanded or split
    }

    // 3.3 — timeout + cancellation

    @Test("a timed-out command is reported as timedOut")
    func timeoutReported() {
        let runner = CommandRunner(executor: { _, _, _ in .timedOut })
        #expect(runner.run(binary: "/x", args: []) == .timedOut)
    }

    @Test("a cancelled command is reported as cancelled")
    func cancelReported() {
        let runner = CommandRunner(executor: { _, _, _ in .cancelled })
        #expect(runner.run(binary: "/x", args: []) == .cancelled)
    }
}
