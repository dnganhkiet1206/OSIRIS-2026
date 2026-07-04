import OsirisCore

/// TikTok module v0 — the second module, built to test whether
/// MODULE_GUIDE.md alone is enough to extend OSIRIS. Like YouTube it is
/// pure data behind the Module Contract: a manifest contributing skills,
/// nothing else. Every trigger keyword carries "tiktok" so nothing here
/// can collide with another module's domain (MODULE_GUIDE §4).
public enum TikTokModule {
    public static let manifest = ModuleManifest(
        id: ModuleID("tiktok"),
        version: "0.1.0",
        purpose: "TikTok content operations — second reference module (content, trends, planning)",
        skills: [hookIdeas, contentPlan, trendBrief, researchToPlan]
    )

    static let hookIdeas = SkillDefinition(
        id: SkillID("tiktok.hook-ideas"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("tiktok"), CapabilityTag("ideation")],
        purpose: "Generate scroll-stopping hook ideas for short-form TikTok videos",
        inputs: ["goal"],
        outputs: ["hooks"],
        promptTemplate: """
        Generate 5 scroll-stopping TikTok hook ideas for the request below. \
        For each: the first spoken line (under 3 seconds), the visual that \
        opens the shot, and why it stops the scroll. Punchy over polished.

        Request: {goal}
        """,
        preferredModelTier: .light,
        triggerKeywords: ["tiktok hook", "tiktok hooks", "hook ideas for tiktok"]
    )

    static let contentPlan = SkillDefinition(
        id: SkillID("tiktok.content-plan"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("tiktok"), CapabilityTag("content-planning")],
        purpose: "Plan a week of TikTok content: themes, posting cadence, hooks",
        inputs: ["goal"],
        outputs: ["content-plan"],
        promptTemplate: """
        Plan one week of TikTok content for the request below: 7 video \
        concepts with a theme each, the best posting time slot, and one hook \
        line per video. Concrete and immediately actionable.

        Request: {goal}
        """,
        preferredModelTier: .light,
        triggerKeywords: ["tiktok content plan", "tiktok content calendar", "plan tiktok content"]
    )

    /// Trend brief works on data the USER pastes into the goal (from TikTok
    /// analytics or the Creative Center) — no API tool, matching the
    /// platform's tool-channel decision (AD-45). Analysis of provided text
    /// is genuine AI work.
    static let trendBrief = SkillDefinition(
        id: SkillID("tiktok.trend-brief"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("tiktok"), CapabilityTag("trend-research")],
        purpose: "Turn pasted TikTok trend data into an actionable brief",
        inputs: ["goal"],
        outputs: ["trend-brief"],
        promptTemplate: """
        Analyze the TikTok trend data provided in the request below \
        (sounds, hashtags, view counts — whatever was pasted). Identify: the \
        2 trends most worth riding and why, how to adapt each to the \
        channel, and 3 concrete video angles. Ground every claim in the \
        provided data — where it is insufficient, say so instead of guessing.

        Request: {goal}
        """,
        preferredModelTier: .standard,
        triggerKeywords: ["tiktok trend", "tiktok trends", "tiktok trend analysis"]
    )

    /// Cross-namespace composition (Module Contract proof, second module):
    /// step 1 is the BUILT-IN core.research-outline, referenced by ID alone
    /// through the shared registry. Curated union (MODULE_GUIDE §6): only a
    /// goal spanning research AND planning reaches the two-step pipeline; a
    /// plan-only goal tie-breaks to tiktok.content-plan (id sorts first).
    static let researchToPlan = SkillDefinition(
        id: SkillID("tiktok.research-to-plan"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("tiktok"), CapabilityTag("research"), CapabilityTag("content-planning")],
        purpose: "Research a topic first, then plan a week of TikTok content around it (2 AI calls)",
        inputs: ["goal"],
        outputs: ["content-plan"],
        preferredModelTier: .standard,
        compositionSteps: [SkillID("core.research-outline"), SkillID("tiktok.content-plan")],
        triggerKeywords: [
            "research", "nghiên cứu",
            "tiktok content plan", "plan tiktok content",
        ]
    )
}
