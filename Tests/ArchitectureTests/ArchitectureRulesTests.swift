import XCTest

/// Architecture Tests (AD-34) — not unit tests. These scan the source tree
/// and fail when the architecture degrades. The compiler enforces the target
/// graph (Core -> Infrastructure only, Modules invisible to Core); these
/// rules cover what the compiler cannot see inside targets.
///
/// Every rule cites the Architecture Decision it enforces. When a new AD
/// lands with a checkable rule, add it here.
final class ArchitectureRulesTests: XCTestCase {
    // MARK: Source scanning

    private struct SourceFile {
        let relativePath: String
        let content: String
    }

    /// Repo root derived from this file's location: Tests/ArchitectureTests/x.swift
    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static let sourceDirectories = ["Core", "Infrastructure", "Application", "Modules", "App", "Presentation", "Shared"]

    private static let allSources: [SourceFile] = {
        var files: [SourceFile] = []
        for directory in sourceDirectories {
            let base = repoRoot.appendingPathComponent(directory)
            guard let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil) else {
                continue
            }
            for case let url as URL in enumerator where url.pathExtension == "swift" {
                guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
                let relative = url.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
                files.append(SourceFile(relativePath: relative, content: strippingComments(from: content)))
            }
        }
        return files.sorted { $0.relativePath < $1.relativePath }
    }()

    /// Rules judge code, not prose: comments must not trigger violations.
    private static func strippingComments(from source: String) -> String {
        var text = source
        if let blocks = try? NSRegularExpression(pattern: #"/\*([^*]|\*(?!/))*\*/"#) {
            text = blocks.stringByReplacingMatches(
                in: text, range: NSRange(text.startIndex..., in: text), withTemplate: ""
            )
        }
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                if let index = line.range(of: "//") {
                    return String(line[line.startIndex..<index.lowerBound])
                }
                return String(line)
            }
            .joined(separator: "\n")
    }

    private func sources(under prefix: String) -> [SourceFile] {
        Self.allSources.filter { $0.relativePath.hasPrefix(prefix) }
    }

    private func sources(notUnder prefixes: [String]) -> [SourceFile] {
        Self.allSources.filter { file in !prefixes.contains { file.relativePath.hasPrefix($0) } }
    }

    private func assertNoMatch(
        _ files: [SourceFile], pattern: String, rule: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let regex = try! NSRegularExpression(pattern: pattern)
        for source in files {
            let range = NSRange(source.content.startIndex..., in: source.content)
            if regex.firstMatch(in: source.content, range: range) != nil {
                XCTFail("\(rule) — violated by \(source.relativePath)", file: file, line: line)
            }
        }
    }

    override func setUpWithError() throws {
        // Guard against silently passing when the scan finds nothing.
        XCTAssertFalse(Self.allSources.isEmpty, "Architecture scan found no sources — repo root resolution broke")
    }

    // MARK: Layer import matrix (AD-30, dependency direction)

    func testInfrastructureImportsNoOsirisTarget() {
        assertNoMatch(
            sources(under: "Infrastructure/"),
            pattern: #"^import Osiris"#.multiline,
            rule: "Infrastructure is domain-free: it must not import any Osiris target"
        )
    }

    func testCoreImportsOnlyInfrastructure() {
        let regex = try! NSRegularExpression(pattern: #"(?m)^import (Osiris\w+)"#)
        for source in sources(under: "Core/") {
            let range = NSRange(source.content.startIndex..., in: source.content)
            for match in regex.matches(in: source.content, range: range) {
                let name = (source.content as NSString).substring(with: match.range(at: 1))
                XCTAssertEqual(
                    name, "OsirisInfrastructure",
                    "Core may import only OsirisInfrastructure — \(source.relativePath) imports \(name)"
                )
            }
        }
    }

    // MARK: Kernel purity (AD-33)

    func testKernelIsPureDecisionLogic() {
        let kernel = sources(under: "Core/Kernel/")
        assertNoMatch(
            kernel,
            pattern: #"(?m)^import OsirisInfrastructure"#,
            rule: "AD-33: Kernel depends only on Core protocols, never on Infrastructure"
        )
        assertNoMatch(
            kernel,
            pattern: #"\b(FileManager|URLSession|LocalStorage|FileStorage)\b"#,
            rule: "AD-33: Kernel performs no I/O — it decides, others do"
        )
    }

    // MARK: One door for AI (AD-06, AD-24, AD-31)

    func testOnlyGatewayTouchesProviders() {
        assertNoMatch(
            sources(notUnder: ["Core/AIGateway/", "App/AppComposition/"]),
            pattern: #"\b(AIProvider|ProviderResponse)\b"#,
            rule: "AD-06/AD-24: only the AI Gateway (and the composition root wiring it) touches providers"
        )
    }

    // MARK: One persister (AD-22, AD-32)

    func testOnlyStoreTouchesLocalStorage() {
        assertNoMatch(
            sources(notUnder: ["Core/Store/", "Infrastructure/Storage/", "App/AppComposition/"]),
            pattern: #"\b(LocalStorage|FileStorage)\b"#,
            rule: "AD-32: only Store persists — no other component touches LocalStorage"
        )
    }

    // MARK: Decision/Execution boundary (AD-25)

    func testOnlyKernelConstructsExecutionPlans() {
        assertNoMatch(
            sources(notUnder: ["Core/Kernel/"]),
            pattern: #"ExecutionPlan\("#,
            rule: "AD-25: only the Kernel decides — no one else constructs an ExecutionPlan"
        )
    }

    func testExecutionEngineDoesNotDecideOrPersist() {
        assertNoMatch(
            sources(under: "Core/Execution/"),
            pattern: #"\b(SkillRegistry|ApprovalGate|ConfidenceTier|Store)\b"#,
            rule: "AD-25: Execution executes mechanically — it never selects skills, gates, or touches state"
        )
    }

    // MARK: Single source of truth (AD-22)

    func testExactlyOneStoreAndOneGatewayImplementation() {
        let conformances: (String) -> Int = { protocolName in
            let regex = try! NSRegularExpression(pattern: #":\s*"# + protocolName + #"\s*\{"#)
            return self.sources(under: "Core/").reduce(0) { count, source in
                let range = NSRange(source.content.startIndex..., in: source.content)
                return count + regex.numberOfMatches(in: source.content, range: range)
            }
        }
        XCTAssertEqual(conformances("Store"), 1, "AD-22: exactly one Store implementation in Core")
        XCTAssertEqual(conformances("AIGateway"), 1, "AD-06: exactly one AIGateway implementation in Core")
    }

    // MARK: Banned components (SYSTEM_COMPONENTS.md §6)

    func testEliminatedComponentsAreNotRecreated() {
        let banned = [
            "ContextEngine", "ContextLoader", "ContextBuilder",
            "MemoryStore", "StateStore", "ExecutiveState",
            "PromptRegistry", "DeliverableRegistry", "CapabilityRegistry",
            "WorkflowEngine", "WorkflowRuntime",
            "ModelRouter", "TokenManager", "IntelligenceEngine",
            // Deleted at its M4 deadline (AD-46): zero dynamic consumers.
            "EventBus",
        ].joined(separator: "|")
        assertNoMatch(
            Self.allSources,
            pattern: #"\b(class|struct|actor|protocol|enum)\s+(\#(banned))\b"#,
            rule: "SYSTEM_COMPONENTS.md §6: eliminated components must not be recreated"
        )
    }

    // MARK: Presentation boundary (added M0-4B — rules are only ever added)

    func testPresentationNeverTouchesInfrastructure() {
        assertNoMatch(
            sources(under: "Presentation/"),
            pattern: #"(?m)^import OsirisInfrastructure"#,
            rule: "Presentation reaches the platform through Core and the composition root, never Infrastructure directly"
        )
    }

    // MARK: Application layer boundary (AD-35, added M0-5 — rules are only ever added)

    func testPresentationTouchesOnlyApplicationLayer() {
        let regex = try! NSRegularExpression(pattern: #"(?m)^import (Osiris\w+)"#)
        for source in sources(under: "Presentation/") {
            let range = NSRange(source.content.startIndex..., in: source.content)
            for match in regex.matches(in: source.content, range: range) {
                let name = (source.content as NSString).substring(with: match.range(at: 1))
                XCTAssertEqual(
                    name, "OsirisApplication",
                    "AD-35: Presentation may import only OsirisApplication — \(source.relativePath) imports \(name)"
                )
            }
        }
    }

    func testApplicationImportsOnlyCore() {
        let regex = try! NSRegularExpression(pattern: #"(?m)^import (Osiris\w+)"#)
        for source in sources(under: "Application/") {
            let range = NSRange(source.content.startIndex..., in: source.content)
            for match in regex.matches(in: source.content, range: range) {
                let name = (source.content as NSString).substring(with: match.range(at: 1))
                XCTAssertEqual(
                    name, "OsirisCore",
                    "AD-35: the Application layer may import only OsirisCore — \(source.relativePath) imports \(name)"
                )
            }
        }
    }

    // MARK: Memory write gate (AD-20/41, added M3-1 — rules are only ever added)

    func testMemoryRecordsAreBornInTheGate() {
        assertNoMatch(
            sources(notUnder: ["Core/Store/"]),
            pattern: #"(WorkingContextRecord|KnowledgeRecord)\("#,
            rule: "AD-20/41: memory records are constructed only inside Core/Store (the Write Gate) — nothing bypasses it"
        )
    }

    // MARK: UI preference boundary (AD-40, added M2-5 — rules are only ever added)

    func testUIPreferencesStayInPresentationAndApp() {
        assertNoMatch(
            sources(under: "Core/") + sources(under: "Application/") + sources(under: "Infrastructure/"),
            pattern: #"\b(UserDefaults|AppStorage)\b"#,
            rule: "AD-40: UserDefaults/@AppStorage are UI preferences — App/Presentation only; platform data lives in the Store"
        )
    }

    // MARK: Tool layer boundary (AD-37, added M1-4 — rules are only ever added)

    func testToolsAreLeafAdapters() {
        assertNoMatch(
            sources(under: "Core/Tools/"),
            pattern: #"\b(AIGateway|AIProvider|SkillRegistry|SkillDefinition|Store|Kernel)\b"#,
            rule: "AD-37: tools are deterministic leaf adapters — they never know AI, skills, state or the Kernel"
        )
    }

    // MARK: Module isolation (AD-19, AD-21, AD-44) — strengthened at M4-0:
    // modules were allowed OsirisCore+OsirisInfrastructure before any module
    // existed; the Module Contract narrows this to OsirisCore only.

    func testModulesImportOnlyCore() {
        let regex = try! NSRegularExpression(pattern: #"(?m)^import (Osiris\w+)"#)
        for source in sources(under: "Modules/") {
            let range = NSRange(source.content.startIndex..., in: source.content)
            for match in regex.matches(in: source.content, range: range) {
                let name = (source.content as NSString).substring(with: match.range(at: 1))
                XCTAssertEqual(
                    name, "OsirisCore",
                    "AD-44: modules see only the Module Contract surface (OsirisCore data types) — \(source.relativePath) imports \(name)"
                )
            }
        }
    }

    // MARK: Modules are data behind the contract (AD-44, added M4-0)

    func testModulesAreDataOnly() {
        assertNoMatch(
            sources(under: "Modules/"),
            pattern: #"\b(Kernel|AIGateway|AIProvider|ExecutionEngine|ExecutionPlan|WriteGate|MemoryCandidate|EventBus|LocalStorage|FileStorage|URLSession|FileManager|UserDefaults)\b"#,
            rule: "AD-44: a module is data behind the Module Contract — it never touches the Kernel, Gateway, Store machinery, Execution, Infrastructure or I/O"
        )
        // `Store` needs word-boundary care separate from the list above
        // because FileBackedStore would also match \bStore\b via substring
        // patterns; keep it explicit and exact.
        assertNoMatch(
            sources(under: "Modules/"),
            pattern: #"\bStore\b"#,
            rule: "AD-44: modules never see the Store"
        )
    }

    // MARK: Core never knows concrete modules (AD-44, added M4-0)

    func testOnlyModulesAndCompositionRootKnowConcreteModules() {
        assertNoMatch(
            sources(notUnder: ["Modules/", "App/"]),
            pattern: #"(?i)youtube"#,
            rule: "AD-44: Core/Application/Infrastructure/Presentation never reference a concrete module — only Modules/ and the composition root do"
        )
    }
}

private extension String {
    /// Convenience: prefix a pattern with the multiline flag.
    var multiline: String { "(?m)" + self }
}
