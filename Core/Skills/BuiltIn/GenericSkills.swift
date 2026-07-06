import Foundation

/// Built-in generic skills — pure data, no logic (M1-1). Only
/// domain-neutral capabilities live here; business skills belong to
/// Modules (AD-21). Prompt templates are data managed through the
/// registry, never hardcoded in execution code (AD-04).
///
/// `{goal}` is the single substitution point the Execution Engine fills in
/// mechanically. Trigger keywords are deliberately narrow: an unmatched
/// goal falls back to the plain AI path, which is always correct.
public enum GenericSkills {
    public static var all: [SkillDefinition] {
        [summarize, draft, researchOutline, researchThenDraft]
    }

    public static let summarize = SkillDefinition(
        id: SkillID("core.summarize"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("summarization")],
        purpose: "Condense text or a topic into clear key points",
        inputs: ["goal"],
        outputs: ["summary"],
        promptTemplate: """
        Summarize the following request into clear, actionable key points. \
        Be concise, no filler. End with the single most important takeaway.

        Request: {goal}
        """,
        preferredModelTier: .light,
        triggerKeywords: ["summarize", "summary", "tóm tắt"]
    )

    public static let draft = SkillDefinition(
        id: SkillID("core.draft"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("content-drafting")],
        purpose: "Draft a first version of a piece of writing",
        inputs: ["goal"],
        outputs: ["draft"],
        promptTemplate: """
        Draft the following. Deliver a complete, immediately usable first \
        version — no preamble about what you are going to do, just the draft.

        Request: {goal}
        """,
        preferredModelTier: .light,
        // "viết bài" not bare "viết": the single word was a substring of
        // module keywords like "viết kịch bản đầy đủ", tying 1-1 and winning
        // by id over the more specific skill (fixed at M6-1 debt sweep).
        triggerKeywords: ["draft", "soạn", "viết bài"]
    )

    /// Composition (AD-36): declared as compositionSteps on a parent skill —
    /// no separate type. Its trigger keywords are the UNION of its steps'
    /// keywords: a goal hitting several of them outscores any single skill
    /// naturally, while a single-keyword goal tie-breaks to the single skill
    /// (ascending id) — no matcher changes needed.
    public static let researchThenDraft = SkillDefinition(
        id: SkillID("core.research-then-draft"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("research"), CapabilityTag("content-drafting")],
        purpose: "Research a topic first, then draft content grounded in the outline",
        inputs: ["goal"],
        outputs: ["draft"],
        preferredModelTier: .light,
        compositionSteps: [SkillID("core.research-outline"), SkillID("core.draft")],
        triggerKeywords: ["research", "nghiên cứu", "investigate", "draft", "soạn", "viết bài"]
    )

    public static let researchOutline = SkillDefinition(
        id: SkillID("core.research-outline"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("research")],
        purpose: "Produce a structured research outline with next actions",
        inputs: ["goal"],
        outputs: ["outline"],
        promptTemplate: """
        Produce a structured research outline for the request below: what is \
        known, what must be found out, and the 3 most valuable next actions. \
        Actionable over exhaustive.

        Request: {goal}
        """,
        preferredModelTier: .light,
        triggerKeywords: ["research", "nghiên cứu", "investigate"]
    )
}
