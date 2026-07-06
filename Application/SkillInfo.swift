import Foundation
import OsirisCore

/// A skill as the Advanced panel sees it — read-only inventory (M2-5).
public struct SkillInfo: Identifiable, Equatable, Sendable {
    public let id: String
    public let version: String
    public let purpose: String
    public let isComposition: Bool

    public init(id: String, version: String, purpose: String, isComposition: Bool) {
        self.id = id
        self.version = version
        self.purpose = purpose
        self.isComposition = isComposition
    }

    /// Pure mapping — testable everywhere.
    public static func from(_ skill: SkillDefinition) -> SkillInfo {
        SkillInfo(
            id: skill.id.rawValue,
            version: skill.version,
            purpose: skill.purpose,
            isComposition: !(skill.compositionSteps ?? []).isEmpty
        )
    }
}
