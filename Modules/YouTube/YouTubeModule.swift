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
        version: "0.1.0",
        purpose: "YouTube content operations — reference module proving the Module Contract",
        skills: [ideaGeneration, scriptOutline]
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
}
