import Foundation

/// Unique identifier of a module. Doubles as the namespace prefix for
/// every skill the module contributes.
public struct ModuleID: Hashable, Codable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

/// Module Contract v1 (AD-44, M4-0). A module IS its manifest: pure data
/// describing what it contributes — no lifecycle, no hooks, no code
/// surface. The second and last registry-like concept allowed (AD-17:
/// Skill Registry + Module Manifest), and the manifest is a descriptor,
/// not an engine.
///
/// The contract is deliberately this small. Skills are the only
/// contribution channel in v1 because skills already carry everything a
/// capability needs (prompt template, keywords, tier, composition —
/// AD-28). New contribution channels (tools, event consumers) are added
/// here ONLY when a real module cannot ship without them.
///
/// A module never sees the Kernel, Gateway, Store, Infrastructure or the
/// composition root — it declares data; the platform decides, executes
/// and persists (enforced by Architecture Tests).
public struct ModuleManifest: Codable, Sendable {
    public let id: ModuleID
    public let version: String
    public let purpose: String
    /// The skills this module contributes. Registered into the ONE Skill
    /// Registry by the composition root — matching, precedence and
    /// execution work identically to built-in skills (one concept, one
    /// representation).
    public let skills: [SkillDefinition]

    public init(id: ModuleID, version: String, purpose: String, skills: [SkillDefinition]) {
        // Namespacing is structural, not conventional: a module cannot
        // collide with core.* or another module. Authored in code — a
        // violation is a programmer error caught by tests.
        precondition(
            skills.allSatisfy { $0.id.rawValue.hasPrefix(id.rawValue + ".") },
            "Every module skill ID must be namespaced '\(id.rawValue).'"
        )
        self.id = id
        self.version = version
        self.purpose = purpose
        self.skills = skills
    }
}
