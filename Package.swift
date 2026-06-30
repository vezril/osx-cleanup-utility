// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MARK: - Package manifest
//
// Architecture: Functional Core / Imperative Shell.
//   • `CleanupCore`     — pure, dependency-free library. No SwiftUI, no
//                          filesystem I/O. Home of all decision logic
//                          (scanning math, safety classification, deletion
//                          planning) in later milestones. Exhaustively
//                          unit-testable in isolation.
//   • `OSXCleanupApp`   — thin SwiftUI app shell (imperative shell). Wires
//                          UI and side effects only; depends on CleanupCore.
//
// Minimum macOS deployment target: macOS 14 (Sonoma). Chosen as a modern
// floor that supports current SwiftUI and the FileManager/tmutil-era APIs
// later milestones rely on. (Resolves design open question / task 1.3.)

let package = Package(
    name: "osx-cleanup-utility",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "CleanupCore", targets: ["CleanupCore"]),
        .executable(name: "osx-cleanup", targets: ["OSXCleanupApp"]),
    ],
    targets: [
        // Functional core — pure, no dependencies.
        .target(
            name: "CleanupCore"
        ),
        // Imperative shell — SwiftUI app, depends on the core.
        .executableTarget(
            name: "OSXCleanupApp",
            dependencies: ["CleanupCore"]
        ),
        // Tests for the functional core.
        .testTarget(
            name: "CleanupCoreTests",
            dependencies: ["CleanupCore"]
        ),
    ]
)
