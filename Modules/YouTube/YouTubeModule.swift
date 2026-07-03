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
        version: "0.4.0",
        purpose: "YouTube content operations — reference module proving the Module Contract",
        skills: [
            ideaGeneration, scriptOutline, scriptGeneration,
            seoPackage, publishingPackage, channelAnalysis,
            ideaToScript, researchToScript, scriptToPackage,
        ]
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

    static let seoPackage = SkillDefinition(
        id: SkillID("youtube.seo-package"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("youtube"), CapabilityTag("seo")],
        purpose: "SEO metadata for one video: title options, description, tags, hashtags",
        inputs: ["goal"],
        outputs: ["seo-metadata"],
        promptTemplate: """
        Produce the SEO metadata for the video described below: 3 title \
        options (under 60 characters each), a 2-paragraph description with \
        the hook up front, 10 search tags, and 3 hashtags. Ground everything \
        in the actual topic — no generic filler.

        Request: {goal}
        """,
        preferredModelTier: .light,
        triggerKeywords: ["seo", "tags", "hashtags", "video description", "video title", "mô tả video", "tiêu đề video"]
    )

    /// A publishing package is a DELIVERABLE, not a system: one structured
    /// output, standalone or as the final step of a pipeline (the template
    /// grounds itself in previous-step material when present).
    static let publishingPackage = SkillDefinition(
        id: SkillID("youtube.publishing-package"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("youtube"), CapabilityTag("publishing-package")],
        purpose: "Ready-to-publish package: titles, description, tags, hashtags, publish checklist",
        inputs: ["goal"],
        outputs: ["publishing-package"],
        promptTemplate: """
        Produce the complete, ready-to-publish YouTube package for the video \
        described below — grounded in the script in the previous material if \
        present: 3 title options, video description, 10 tags, 3 hashtags, \
        and a short publish checklist (thumbnail, end screen, pinned comment).

        Request: {goal}
        """,
        preferredModelTier: .light,
        triggerKeywords: ["publishing package", "publish package", "ready to publish", "gói xuất bản"]
    )

    /// Channel analysis v1 works on data the USER provides in the goal
    /// (pasted from YouTube Studio) — deliberately no API tool (AD-45):
    /// auto-fetch needs OAuth/network decisions that belong to M6 with
    /// explicit user consent, and the manifest stays Codable pure data.
    /// Insight extraction from provided text is genuine AI work — no
    /// deterministic tool could do it, so "AI Is The Last Tool" holds.
    static let channelAnalysis = SkillDefinition(
        id: SkillID("youtube.channel-analysis"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("youtube"), CapabilityTag("channel-analysis")],
        purpose: "Analyze channel data the user provides (paste from YouTube Studio)",
        inputs: ["goal"],
        outputs: ["analysis"],
        promptTemplate: """
        Analyze the YouTube channel data provided in the request below \
        (video list, views, retention — whatever was pasted). Identify: \
        what performs best and the likely why, 2 patterns worth repeating, \
        1 thing to stop doing, and 3 concrete next actions. Ground every \
        claim in the provided data — where the data is insufficient, say \
        so instead of inventing numbers.

        Request: {goal}
        """,
        preferredModelTier: .standard,
        triggerKeywords: [
            "channel analysis", "analyze my channel", "channel stats",
            "channel performance", "phân tích kênh",
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

    /// Script → publishing package: the package is grounded in the actual
    /// script, not the bare topic. Curated union (M4-1 guideline, refined):
    /// curate so every tie resolves to the SINGLE skill — here "script"
    /// stays IN the union (dual-domain goals need 3 hits to beat
    /// script-generation's 2) because all tie-breaks (script-generation,
    /// publishing-package) already sort before this id. Every overlap case
    /// is pinned by a test.
    static let scriptToPackage = SkillDefinition(
        id: SkillID("youtube.script-to-package"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("youtube"), CapabilityTag("script-generation"), CapabilityTag("publishing-package")],
        purpose: "Write the full script, then assemble the publishing package grounded in it (2 AI calls)",
        inputs: ["goal"],
        outputs: ["publishing-package"],
        preferredModelTier: .standard,
        compositionSteps: [SkillID("youtube.script-generation"), SkillID("youtube.publishing-package")],
        triggerKeywords: [
            "full script", "write the script", "script", "viết kịch bản đầy đủ",
            "publishing package", "publish package", "ready to publish", "gói xuất bản",
        ]
    )
}
