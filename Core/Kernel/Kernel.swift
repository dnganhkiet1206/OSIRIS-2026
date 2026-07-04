import Foundation

/// The Executive Brain — the ONLY place allowed to choose (AD-01, AD-25).
/// Orchestrates the canonical five-phase lifecycle (AD-12):
/// Intake → Decide → Execute → Verify → Persist.
///
/// Pure decision logic (AD-33): the Kernel depends only on Core protocols,
/// performs no I/O itself, and publishes progress through an injected
/// closure. It never produces deliverables, never calls a provider, and
/// contains no business logic. "Executive State" is whatever this class
/// holds in memory during a request — never persisted separately (AD-08).
public final class Kernel: Sendable {
    public typealias EventPublisher = @Sendable (ExecutionEvent) async -> Void

    private let skills: any SkillRegistry
    /// Static tool list injected by the composition root (AD-37): a handful
    /// of tools needs no registry — the Skill Registry stays the platform's
    /// only registry (AD-17) until evidence demands otherwise.
    private let tools: [any Tool]
    private let engine: any ExecutionEngine
    private let store: any Store
    /// The only path from reflection candidates to persistable records
    /// (AD-20/41). Defaults to disabled — memory writes are opt-in via
    /// the composed policy, never an accident.
    private let writeGate: WriteGate
    private let publish: EventPublisher

    public init(
        skills: any SkillRegistry,
        tools: [any Tool] = [],
        engine: any ExecutionEngine,
        store: any Store,
        writeGate: WriteGate = WriteGate(policy: .disabled),
        publish: @escaping EventPublisher
    ) {
        self.skills = skills
        self.tools = tools
        self.engine = engine
        self.store = store
        self.writeGate = writeGate
        self.publish = publish
    }

    /// Handles one goal through the five phases: Intake → Decide → Execute →
    /// Verify → Persist. Decide follows the full resource order (reuse →
    /// tool → skill/composition → AI); persistence is via the Store only.
    /// Risky-action approval will return with the first real risky action
    /// (external/irreversible effect) — deleted meanwhile (AD-47).
    public func handle(_ goal: Goal) async throws -> Deliverable {
        // 1. INTAKE — understand the objective; never guess (AD-05).
        await publish(.understanding)
        let objective = goal.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let confidenceTier = confidence(in: objective)
        guard confidenceTier != .low else {
            await publish(.failed("Goal needs clarification"))
            throw KernelError.needsClarification("Describe what you want to accomplish.")
        }

        // 2. DECIDE — the full resource order, cheapest sufficient path
        // first (AD-12): reuse → deterministic tool (zero tokens, AI Is
        // The Last Tool) → skill/composition → plain AI.
        await publish(.planning)
        let complexity = ComplexityEstimate.estimate(for: objective)
        let strategy: ExecutionStrategy
        var tier: ModelTier = .light
        if let existing = try await reusableResult(for: objective, in: goal.projectID) {
            strategy = .reuse(existing: existing)
        } else if let tool = matchedTool(for: objective) {
            strategy = .tool(tool)
        } else {
            // Tier is earned, never hardcoded (AD-42): the skill's declared
            // tier outranks the estimate; the estimate covers the rest.
            let skill = await matchedSkill(for: objective)
            tier = skill?.preferredModelTier ?? complexity.preferredTier
            if let steps = skill?.compositionSteps, !steps.isEmpty {
                // A misconfigured composition (missing step) degrades to the
                // plain AI path — the goal still completes.
                strategy = await resolvedComposition(steps) ?? .ai(skill: nil)
            } else {
                strategy = .ai(skill: skill)
            }
        }
        let plan = ExecutionPlan(goal: goal, strategy: strategy, preferredTier: tier)

        // Medium confidence (AD-05/42): proceed, but the assumption is
        // documented — through the same Write Gate as every memory write.
        // No second path exists.
        if confidenceTier == .medium,
           let assumption = writeGate.admit(MemoryCandidate(
               projectID: goal.projectID,
               content: "Assumption (medium confidence): interpreting the goal literally — \"\(objective)\"",
               justifications: [.reusableLater]
           )) {
            try? await store.save(assumption)
        }

        // 3. EXECUTE — the engine does the work; the Kernel never does.
        await publish(.executing)
        let result = try await engine.run(plan)

        // 4. VERIFY — never return a broken deliverable.
        guard !result.deliverable.content.isEmpty else {
            await publish(.failed("Empty deliverable"))
            throw KernelError.verificationFailed
        }

        // 5. PERSIST — update the single source of truth (through Store only,
        // AD-32: the Kernel orchestrates, the Store touches disk).
        await publish(.updatingState)
        var state = try await store.projectState(for: goal.projectID)
            ?? ProjectState(projectID: goal.projectID)
        var deliverable = result.deliverable
        switch strategy {
        case .reuse:
            // Reused content already lives on disk — writing it again would
            // duplicate the deliverable and pollute future reuse detection.
            break
        case .tool:
            // Tool results are NOT persisted (AD-37): persistence exists to
            // avoid re-spending tokens, but a tool re-runs for free — while
            // a stale stored answer ("yesterday's date") is a real wrong
            // answer waiting in the reuse path.
            break
        default:
            let path = try await store.saveDeliverable(
                result.deliverable.content, goal: goal.text, for: goal.projectID
            )
            state.deliverablePaths.append(path)
            deliverable = Deliverable(content: result.deliverable.content, filePath: path)
        }
        state.recordCompletion(of: goal.text)
        try await store.save(state)

        // Reflection (AD-41): deterministic, zero tokens. A candidate only
        // becomes a record if the Write Gate admits it; persisting it is
        // best-effort — auxiliary memory never fails a completed goal.
        if let memoryCandidate = Reflection.candidate(
            goal: goal, strategy: strategy, deliverablePath: deliverable.filePath
        ), let record = writeGate.admit(memoryCandidate) {
            try? await store.save(record)
        }

        await publish(.completed)
        return deliverable
    }

    // MARK: Decision helpers (pure)

    /// Vague-intent signals — deliberately few: prefer High over
    /// assumption spam. Confidence reflects decision certainty, never
    /// "intelligence", and is never adjusted by AI.
    private static let vagueSignals = [
        "something", "anything", "somehow", "whatever",
        "gì đó", "đại khái", "sao cũng được",
    ]

    /// Confidence v1 (AD-05/42): Low = ask, never guess. Medium = proceed
    /// while documenting the assumption (via the Write Gate). High = go.
    private func confidence(in objective: String) -> ConfidenceTier {
        guard !objective.isEmpty else { return .low }
        let lowered = objective.lowercased()
        if Self.vagueSignals.contains(where: lowered.contains) { return .medium }
        return .high
    }

    /// Selection is data-driven (M1-1/M1-4): skills and tools declare their
    /// trigger keywords, so adding either never changes this algorithm —
    /// ONE matching algorithm for both (one concept, one representation).
    /// Most keyword hits wins; ties break deterministically by id; no hits
    /// means no match — the plain AI path is always a correct fallback.
    private func selectByKeywords<Candidate>(
        from candidates: [(candidate: Candidate, keywords: [String]?, id: String)],
        for objective: String
    ) -> Candidate? {
        let lowered = objective.lowercased()
        let scored = candidates.compactMap { entry -> (candidate: Candidate, hits: Int, id: String)? in
            guard let keywords = entry.keywords else { return nil }
            let hits = keywords.filter { lowered.contains($0.lowercased()) }.count
            return hits > 0 ? (entry.candidate, hits, entry.id) : nil
        }
        return scored
            .sorted { $0.hits != $1.hits ? $0.hits > $1.hits : $0.id < $1.id }
            .first?.candidate
    }

    private func matchedTool(for objective: String) -> (any Tool)? {
        selectByKeywords(
            from: tools.map { (candidate: $0, keywords: $0.triggerKeywords, id: $0.id.rawValue) },
            for: objective
        )
    }

    private func matchedSkill(for objective: String) async -> SkillDefinition? {
        let all = await skills.allSkills()
        return selectByKeywords(
            from: all.map { (candidate: $0, keywords: $0.triggerKeywords, id: $0.id.rawValue) },
            for: objective
        )
    }

    /// Resolves declared step IDs into full definitions during Decide, so
    /// the Execution Engine never touches the registry (AD-25). Returns nil
    /// when any step is unresolvable.
    private func resolvedComposition(_ steps: [SkillID]) async -> ExecutionStrategy? {
        var resolved: [SkillDefinition] = []
        for id in steps {
            guard let skill = await skills.skill(withID: id) else { return nil }
            resolved.append(skill)
        }
        return .composition(steps: resolved)
    }

    /// Reuse Before Create: strict match only — the full goal text must
    /// appear in a stored record. Prefer a miss over a wrong reuse;
    /// relevance ranking arrives in M1. Full content is fetched through
    /// the Store so the reused deliverable is complete, not a snippet.
    private func reusableResult(for objective: String, in projectID: ProjectID) async throws -> String? {
        guard let hit = try await store.search(
            StoreQuery(text: objective, projectID: projectID, limit: 1)
        ).first else { return nil }

        switch hit.kind {
        case .knowledge:
            return try await store.knowledge(id: hit.id)?.body
        case .deliverable:
            return try await store.deliverableContent(at: hit.id)
        case .projectState, .workingContext:
            return hit.snippet
        }
    }
}

public enum KernelError: Error, Equatable, Sendable {
    case verificationFailed
    /// Low confidence: the goal is too vague to act on. The message is a
    /// user-facing question (UI contract), not an internal detail.
    case needsClarification(String)
}
