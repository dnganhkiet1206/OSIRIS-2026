import Foundation

/// The platform's single extension point (AD-03, AD-17). There is no separate
/// Capability/Prompt/Deliverable/Workflow registry — recreating one violates
/// the architecture (SYSTEM_COMPONENTS.md §6).
public protocol SkillRegistry: Sendable {
    func register(_ skill: SkillDefinition) async
    func skill(withID id: SkillID) async -> SkillDefinition?
    func skills(providing capability: CapabilityTag) async -> [SkillDefinition]
    func allSkills() async -> [SkillDefinition]
}

/// In-memory implementation. Persistence of user-edited skills arrives with
/// evidence of need (M1).
public actor InMemorySkillRegistry: SkillRegistry {
    private var skills: [SkillID: SkillDefinition] = [:]

    public init() {}

    public func register(_ skill: SkillDefinition) {
        skills[skill.id] = skill
    }

    public func skill(withID id: SkillID) -> SkillDefinition? {
        skills[id]
    }

    public func skills(providing capability: CapabilityTag) -> [SkillDefinition] {
        skills.values
            .filter { $0.capabilityTags.contains(capability) }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public func allSkills() -> [SkillDefinition] {
        skills.values.sorted { $0.id.rawValue < $1.id.rawValue }
    }
}
