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
    /// Deterministic tool execution — zero AI, zero tokens. The Kernel
    /// resolves the tool in Decide; the plan carries it so Execution never
    /// selects or swaps tools (AD-25, AD-37).
    case tool(any Tool)
    /// Sequential skill chain (AD-07, AD-36): a composition is declared as
    /// `SkillDefinition.compositionSteps` — one concept, one representation.
    /// The Kernel resolves step IDs to full definitions HERE in Decide, so
    /// the Execution Engine never touches the registry (AD-25).
    case composition(steps: [SkillDefinition])
    /// AI execution, optionally through a skill the Kernel selected. The
    /// skill rides on this case only — a skill without an AI call is
    /// meaningless in v1, and the type makes that combination impossible.
    case ai(skill: SkillDefinition?)
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
