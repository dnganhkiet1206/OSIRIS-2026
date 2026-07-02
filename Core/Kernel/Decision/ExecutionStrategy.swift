import Foundation

/// Strategies the Kernel chooses among. The simplest successful strategy
/// always wins, following the resource order: existing data → cache →
/// application logic → tool → composition → AI (AI Is The Last Tool).
public enum ExecutionStrategy: Sendable {
    /// The answer already exists — materialize it, execute nothing new
    /// (Reuse Before Create). Carries the found content so Execution stays
    /// mechanical and never touches the Store (AD-25).
    case reuse(existing: String)
    case direct
    case tool(ToolID)
    case composition(SkillComposition)
    case ai
    case hybrid
}

/// Confidence is a tier, never a numeric score (AD-05). Low confidence on
/// anything important triggers clarification instead of guessing.
public enum ConfidenceTier: String, Sendable {
    /// Proceed automatically.
    case high
    /// Proceed while documenting assumptions.
    case medium
    /// Ask the minimum clarification required. Never guess.
    case low
}
