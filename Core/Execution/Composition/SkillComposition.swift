import Foundation

/// A workflow is nothing but a declarative sequence of skills (AD-07) —
/// there is no separate Workflow Engine/Runtime, and recreating one violates
/// the architecture. Keep compositions short: fewer than five logical steps;
/// below three, prefer direct execution.
public struct SkillComposition: Codable, Sendable {
    public let steps: [SkillID]

    public init(steps: [SkillID]) {
        self.steps = steps
    }
}
