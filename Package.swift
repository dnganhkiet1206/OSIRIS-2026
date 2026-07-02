// swift-tools-version:5.9
// OSIRIS — Core platform package.
// Core and Infrastructure are pure Swift (no UI) so they build and test on any
// platform. The iOS app shell (App/ + Presentation/) is built via the Xcode
// project generated from project.yml and links this package. (AD-30)
import PackageDescription

let package = Package(
    name: "OsirisKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "OsirisCore", targets: ["OsirisCore"]),
        .library(name: "OsirisInfrastructure", targets: ["OsirisInfrastructure"]),
    ],
    targets: [
        // Dependency direction is enforced by target boundaries:
        // Core -> Infrastructure. Never the reverse.
        .target(
            name: "OsirisInfrastructure",
            path: "Infrastructure",
            exclude: ["README.md"]
        ),
        .target(
            name: "OsirisCore",
            dependencies: ["OsirisInfrastructure"],
            path: "Core",
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "OsirisCoreTests",
            dependencies: ["OsirisCore"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "OsirisInfrastructureTests",
            dependencies: ["OsirisInfrastructure"],
            path: "Tests/InfrastructureTests"
        ),
        // Architecture Tests (AD-34): source-scanning rules that fail when
        // the architecture degrades. No target dependencies — they read files.
        .testTarget(
            name: "OsirisArchitectureTests",
            path: "Tests/ArchitectureTests"
        ),
    ]
)
