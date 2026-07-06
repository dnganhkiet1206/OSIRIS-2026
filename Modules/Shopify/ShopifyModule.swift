import OsirisCore

/// Shopify module v0 — the third module, and the second guide-validation:
/// a domain (e-commerce) unlike the first two (content creation). Built
/// from MODULE_GUIDE.md alone. Pure data behind the Module Contract; no
/// state, sessions, OAuth, uploads or persistence — a Shopify API belongs
/// to M6 (AD-45), not the manifest.
///
/// Single-skill keywords deliberately avoid the built-in words "research"
/// and "draft" so an e-commerce goal never ties into a generic skill
/// (MODULE_GUIDE §4). The composition MAY reuse "research" in its curated
/// union — compositions are exempt from the collision sweep.
public enum ShopifyModule {
    public static let manifest = ModuleManifest(
        id: ModuleID("shopify"),
        version: "0.1.0",
        purpose: "Shopify store operations — third reference module (products, listings, store analysis)",
        skills: [productResearch, listingOptimization, storeAnalysis, researchToListing]
    )

    static let productResearch = SkillDefinition(
        id: SkillID("shopify.product-research"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("shopify"), CapabilityTag("product-research")],
        purpose: "Find product opportunities worth selling in a store",
        inputs: ["goal"],
        outputs: ["product-opportunities"],
        promptTemplate: """
        Find 5 product opportunities for the store described below. For each: \
        the product, the target buyer, why demand exists now, and one risk to \
        watch. Concrete niches over broad categories.

        Request: {goal}
        """,
        preferredModelTier: .standard,
        triggerKeywords: ["winning products", "product opportunities", "products to sell", "sản phẩm nên bán"]
    )

    static let listingOptimization = SkillDefinition(
        id: SkillID("shopify.listing-optimization"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("shopify"), CapabilityTag("listing-optimization")],
        purpose: "Write and optimize a product listing: title, description, bullets",
        inputs: ["goal"],
        outputs: ["listing"],
        promptTemplate: """
        Write an optimized Shopify product listing for the request below: a \
        title (under 70 characters), a benefit-led description, 5 bullet \
        points, and 8 search keywords. Persuasive and specific — no filler.

        Request: {goal}
        """,
        preferredModelTier: .light,
        triggerKeywords: ["product listing", "listing optimization", "optimize product listing", "tối ưu listing"]
    )

    /// Store analysis works on data the USER pastes into the goal (from the
    /// Shopify admin/analytics) — no API tool (AD-45). Insight from provided
    /// numbers is genuine AI work.
    static let storeAnalysis = SkillDefinition(
        id: SkillID("shopify.store-analysis"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("shopify"), CapabilityTag("store-analysis")],
        purpose: "Analyze store data the user provides (paste from Shopify analytics)",
        inputs: ["goal"],
        outputs: ["analysis"],
        promptTemplate: """
        Analyze the store data provided in the request below (sales, \
        conversion, traffic — whatever was pasted). Identify: the biggest \
        lever to pull and why, 2 quick wins, 1 thing to stop, and 3 next \
        actions. Ground every claim in the provided data — where it is \
        insufficient, say so instead of inventing numbers.

        Request: {goal}
        """,
        preferredModelTier: .standard,
        triggerKeywords: ["store analysis", "analyze my store", "store performance", "phân tích cửa hàng"]
    )

    /// Cross-namespace composition (Module Contract proof, third module):
    /// step 1 is the BUILT-IN core.research-outline, referenced by ID alone
    /// through the shared registry. Curated union (MODULE_GUIDE §6): only a
    /// goal spanning research AND listing reaches the two-step pipeline; a
    /// listing-only goal tie-breaks to shopify.listing-optimization (id
    /// sorts before this one).
    static let researchToListing = SkillDefinition(
        id: SkillID("shopify.research-to-listing"),
        version: "1.0.0",
        capabilityTags: [CapabilityTag("shopify"), CapabilityTag("research"), CapabilityTag("listing-optimization")],
        purpose: "Research the product first, then write an optimized listing grounded in it (2 AI calls)",
        inputs: ["goal"],
        outputs: ["listing"],
        preferredModelTier: .standard,
        compositionSteps: [SkillID("core.research-outline"), SkillID("shopify.listing-optimization")],
        triggerKeywords: [
            "research", "nghiên cứu",
            "product listing", "optimize product listing",
        ]
    )
}
