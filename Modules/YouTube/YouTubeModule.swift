import OsirisCore

/// YouTube module v0 — the reference implementation every later module
/// copies (AD-21). It exists to prove ONE thing: adding a module changes
/// zero lines of Core. A module is data behind the Module Contract
/// (AD-44): a manifest contributing skills, nothing else.
///
/// Trigger keywords use overlapping phrases deliberately: a goal like
/// "video script" hits both "video script" and "script", outscoring any
/// single-keyword generic skill (same mechanism that lets compositions
/// win, M1-3). Narrow beats broad — the plain AI fallback is always
/// correct, a wrong hijack never is.
public enum YouTubeModule {
    public static let manifest = ModuleManifest(
        id: ModuleID("youtube"),
        version: "0.2.0",
        purpose: "YouTube content operations — reference module proving the Module Contract",
        skills: [ideaGeneration, scriptOutline, scriptGeneration, ideaToScript, researchToScript]
    )

    static let ideaGeneration = SkillDefinition(
        id: SkillID("youtube.idea-generation"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("youtube"), CapabilityTag("ideation")],
        purpose: "Generate concrete video ideas for a channel or topic",
        inputs: ["goal"],
        outputs: ["ideas"],
        promptTemplate: """
        Generate 5 concrete YouTube video ideas for the request below. For \
        each: a working title, the core hook in one sentence, and why it \
        fits the channel. Specific over generic.

        Request: {goal}
        """,
        preferredModelTier: .light,
        triggerKeywords: ["video idea", "video ideas", "ý tưởng video"]
    )

    static let scriptOutline = SkillDefinition(
        id: SkillID("youtube.script-outline"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("youtube"), CapabilityTag("scripting")],
        purpose: "Outline a video script: hook, sections, retention beats, CTA",
        inputs: ["goal"],
        outputs: ["outline"],
        promptTemplate: """
        Outline a YouTube video script for the request below: opening hook \
        (first 15 seconds), main sections with one key point each, a \
        retention beat mid-video, and the closing call to action.

        Request: {goal}
        """,
        preferredModelTier: .light,
        triggerKeywords: ["video script", "script", "kịch bản video", "kịch bản"]
    )

    /// Full ready-to-record script — declares .standard tier: long-form
    /// spoken content is the module's heaviest single task (the declared
    /// tier outranks the estimate, AD-42).
    static let scriptGeneration = SkillDefinition(
        id: SkillID("youtube.script-generation"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("youtube"), CapabilityTag("script-generation")],
        purpose: "Write a complete, ready-to-record video script",
        inputs: ["goal"],
        outputs: ["script"],
        promptTemplate: """
        Write the complete, ready-to-record YouTube script for the request \
        below: spoken-word style, an opening hook, clear section \
        transitions, and a closing call to action. Deliver the full \
        script, not an outline.

        Request: {goal}
        """,
        preferredModelTier: .standard,
        triggerKeywords: ["full script", "write the script", "viết kịch bản đầy đủ", "script"]
    )

    /// Composition keyword unions are CURATED, not blind (refines M1-3):
    /// the broad single keyword ("script") is left out so the composition
    /// only outscores its children when BOTH domains appear in the goal —
    /// a pure script goal stays on the single skill, a pure idea goal
    /// tie-breaks back to idea-generation (ascending id, M1-1).
    static let ideaToScript = SkillDefinition(
        id: SkillID("youtube.idea-to-script"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("youtube"), CapabilityTag("ideation"), CapabilityTag("script-generation")],
        purpose: "Generate video ideas, then write the full script for the strongest one",
        inputs: ["goal"],
        outputs: ["script"],
        preferredModelTier: .standard,
        compositionSteps: [SkillID("youtube.idea-generation"), SkillID("youtube.script-generation")],
        triggerKeywords: [
            "video idea", "video ideas", "ý tưởng video",
            "full script", "write the script", "viết kịch bản đầy đủ",
        ]
    )

    /// Cross-namespace composition (AD-44 proof): step 1 is a BUILT-IN
    /// skill referenced purely by ID — modules compose with the platform
    /// through the shared registry, no special API, no module branching.
    static let researchToScript = SkillDefinition(
        id: SkillID("youtube.research-to-script"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("youtube"), CapabilityTag("research"), CapabilityTag("script-generation")],
        purpose: "Research a topic first, then write a script grounded in the outline",
        inputs: ["goal"],
        outputs: ["script"],
        preferredModelTier: .standard,
        compositionSteps: [SkillID("core.research-outline"), SkillID("youtube.script-generation")],
        triggerKeywords: [
            "research", "nghiên cứu", "investigate",
            "full script", "write the script", "viết kịch bản đầy đủ",
        ]
    )
}
