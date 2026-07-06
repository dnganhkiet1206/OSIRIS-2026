import Foundation

/// Unique identifier of a skill.
public struct SkillID: Hashable, Codable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

/// A capability is a contract/tag, not a component (AD-03). The Kernel asks
/// for capabilities; the registry answers with skills that provide them.
public struct CapabilityTag: Hashable, Codable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

/// The single unit of capability in OSIRIS. Skills are small, single-purpose,
/// reusable and independently testable.
///
/// Schema per AD-28 — required fields only; everything else is optional and
/// added when evidence demands it. Prompt templates live here, versioned with
/// the skill (AD-04). AD-28 works both ways: a per-skill retryPolicy field
/// waited from M1 to M3 review without a consumer and was removed — retry
/// remains Gateway-owned policy from Config.
public struct SkillDefinition: Codable, Sendable {
    // Required (AD-28)
    public let id: SkillID
    public let version: String
    public let capabilityTags: [CapabilityTag]
    public let purpose: String
    public let inputs: [String]
    public let outputs: [String]

    // Optional — populate only with evidence of need (AD-28)
    public var promptTemplate: String?
    public var preferredModelTier: ModelTier?
    public var compositionSteps: [SkillID]?
    /// Data-driven matching (added M1-1 per AD-28): the skill declares what
    /// goals it serves, so adding a skill never requires a Kernel change.
    /// Keep keywords narrow — a fallback is cheaper than a wrong match.
    public var triggerKeywords: [String]?

    public init(
        id: SkillID,
        version: String,
        capabilityTags: [CapabilityTag],
        purpose: String,
        inputs: [String],
        outputs: [String],
        promptTemplate: String? = nil,
        preferredModelTier: ModelTier? = nil,
        compositionSteps: [SkillID]? = nil,
        triggerKeywords: [String]? = nil
    ) {
        self.id = id
        self.version = version
        self.capabilityTags = capabilityTags
        self.purpose = purpose
        self.inputs = inputs
        self.outputs = outputs
        self.promptTemplate = promptTemplate
        self.preferredModelTier = preferredModelTier
        // Compositions stay short by declaration (BLUEPRINT: < 5 logical
        // steps; below 3, prefer direct execution). Authored in code —
        // a violation is a programmer error caught by tests.
        precondition(
            compositionSteps.map { (1...5).contains($0.count) } ?? true,
            "compositionSteps must contain 1...5 steps"
        )
        self.compositionSteps = compositionSteps
        self.triggerKeywords = triggerKeywords
    }
}
