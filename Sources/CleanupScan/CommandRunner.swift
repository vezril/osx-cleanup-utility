import Foundation

// Safe command runner (imperative shell).
//
// Executes ONLY a binary plus a literal argument vector — never `/bin/sh -c`,
// never a constructed command string, never interpolated input. The low-level
// executor is injectable so the mapping logic is tested without spawning real
// processes; the default executor uses `Process` with `arguments` and enforces a
// timeout.

public struct CommandRunner: Sendable {

    public struct Output: Equatable, Sendable {
        public let stdout: String
        public let stderr: String
        public let exitCode: Int32
        public init(stdout: String, stderr: String, exitCode: Int32) {
            self.stdout = stdout; self.stderr = stderr; self.exitCode = exitCode
        }
    }

    /// Result of a run, classifying exit status and signals.
    public enum Result: Equatable, Sendable {
        case success(Output)   // exit code 0
        case failure(Output)   // non-zero exit
        case timedOut
        case cancelled
    }

    /// Low-level outcome of launching a process.
    public enum Raw: Equatable, Sendable {
        case finished(stdout: String, stderr: String, exitCode: Int32)
        case timedOut
        case cancelled
    }

    public typealias Executor = @Sendable (_ binary: String, _ args: [String], _ timeout: TimeInterval) -> Raw

    private let executor: Executor

    public init(executor: @escaping Executor = CommandRunner.processExecutor) {
        self.executor = executor
    }

    /// Run `binary` with literal `args`. A non-zero exit is a failure, never a
    /// success.
    public func run(binary: String, args: [String], timeout: TimeInterval = 120) -> Result {
        switch executor(binary, args, timeout) {
        case let .finished(out, err, code):
            let output = Output(stdout: out, stderr: err, exitCode: code)
            return code == 0 ? .success(output) : .failure(output)
        case .timedOut:
            return .timedOut
        case .cancelled:
            return .cancelled
        }
    }

    // MARK: - real executor

    /// Default executor: launches the binary with its argument vector via
    /// `Process` (no shell), capturing output and enforcing a timeout.
    public static let processExecutor: Executor = { binary, args, timeout in
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = args   // literal argv — no shell, no interpolation
        let outPipe = Pipe(), errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            return .finished(stdout: "", stderr: error.localizedDescription, exitCode: -1)
        }

        // Enforce the timeout on a background watchdog.
        let deadline = DispatchTime.now() + timeout
        let timedOut = DispatchQueue.global().asyncAfterCancellable(deadline: deadline) {
            if process.isRunning { process.terminate() }
        }

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        timedOut.cancel()

        let stdout = String(decoding: outData, as: UTF8.self)
        let stderr = String(decoding: errData, as: UTF8.self)
        // A SIGTERM from the watchdog surfaces as an uncaught-signal termination.
        if process.terminationReason == .uncaughtSignal {
            return .timedOut
        }
        return .finished(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus)
    }
}

private extension DispatchQueue {
    /// Schedule `work` after `deadline`, returning a handle to cancel it.
    func asyncAfterCancellable(deadline: DispatchTime, execute work: @escaping @Sendable () -> Void) -> DispatchWorkItem {
        let item = DispatchWorkItem(block: work)
        asyncAfter(deadline: deadline, execute: item)
        return item
    }
}
