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
/// the skill (AD-04). Retry/fallback is declared policy executed mechanically
/// by the Execution Engine (AD-25).
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
    public var retryPolicy: RetryPolicy?

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
        retryPolicy: RetryPolicy? = nil
    ) {
        self.id = id
        self.version = version
        self.capabilityTags = capabilityTags
        self.purpose = purpose
        self.inputs = inputs
        self.outputs = outputs
        self.promptTemplate = promptTemplate
        self.preferredModelTier = preferredModelTier
        self.compositionSteps = compositionSteps
        self.retryPolicy = retryPolicy
    }
}
