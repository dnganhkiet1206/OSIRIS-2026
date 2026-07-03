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
        .library(name: "OsirisApplication", targets: ["OsirisApplication"]),
        .library(name: "OsirisModules", targets: ["OsirisModules"]),
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
        // Application layer (AD-35): the only bridge between Presentation
        // and Core. Thin translation, no business logic.
        .target(
            name: "OsirisApplication",
            dependencies: ["OsirisCore"],
            path: "Application"
        ),
        // Modules (AD-44): data behind the Module Contract. Depends on
        // OsirisCore ONLY — the compiler makes "module knows Core types"
        // one-way; Architecture Tests keep it to contract data types.
        // Core never depends on this target: Core cannot know modules.
        .target(
            name: "OsirisModules",
            dependencies: ["OsirisCore"],
            path: "Modules",
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "OsirisCoreTests",
            dependencies: ["OsirisCore"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "OsirisModuleTests",
            dependencies: ["OsirisModules", "OsirisCore", "OsirisInfrastructure"],
            path: "Tests/ModuleTests"
        ),
        .testTarget(
            name: "OsirisInfrastructureTests",
            dependencies: ["OsirisInfrastructure"],
            path: "Tests/InfrastructureTests"
        ),
        .testTarget(
            name: "OsirisApplicationTests",
            dependencies: ["OsirisApplication"],
            path: "Tests/ApplicationTests"
        ),
        // Architecture Tests (AD-34): source-scanning rules that fail when
        // the architecture degrades. No target dependencies — they read files.
        .testTarget(
            name: "OsirisArchitectureTests",
            path: "Tests/ArchitectureTests"
        ),
    ]
)
