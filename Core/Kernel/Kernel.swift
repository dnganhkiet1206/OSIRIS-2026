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
    private let engine: any ExecutionEngine
    private let store: any Store
    private let approvalGate: any ApprovalGate
    private let publish: EventPublisher

    public init(
        skills: any SkillRegistry,
        engine: any ExecutionEngine,
        store: any Store,
        approvalGate: any ApprovalGate,
        publish: @escaping EventPublisher
    ) {
        self.skills = skills
        self.engine = engine
        self.store = store
        self.approvalGate = approvalGate
        self.publish = publish
    }

    /// Handles one goal through the five phases. M0-4A scope: Decide is
    /// real (confidence gate, reuse-before-AI, cheapest sufficient
    /// strategy); risky-action gating activates when tools introduce risky
    /// actions (M1). Deliverable persistence is M0-4B, via Store only.
    public func handle(_ goal: Goal) async throws -> Deliverable {
        // 1. INTAKE — understand the objective; never guess (AD-05).
        await publish(.understanding)
        let objective = goal.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard confidence(in: objective) != .low else {
            await publish(.failed("Goal needs clarification"))
            throw KernelError.needsClarification("Describe what you want to accomplish.")
        }

        // 2. DECIDE — cheapest sufficient path: reuse before AI (AD-12).
        await publish(.planning)
        let strategy: ExecutionStrategy
        if let existing = try await reusableResult(for: objective, in: goal.projectID) {
            strategy = .reuse(existing: existing)
        } else {
            // Resource order continues (logic → tool → composition) as
            // skills and tools land in M1; AI is the last tool that
            // currently exists.
            strategy = .ai
        }
        let plan = ExecutionPlan(goal: goal, strategy: strategy, preferredTier: .light)

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
        if case .reuse = strategy {
            // Reused content already lives on disk — writing it again would
            // duplicate the deliverable and pollute future reuse detection.
        } else {
            let path = try await store.saveDeliverable(
                result.deliverable.content, goal: goal.text, for: goal.projectID
            )
            state.deliverablePaths.append(path)
            deliverable = Deliverable(content: result.deliverable.content, filePath: path)
        }
        state.recordCompletion(of: goal.text)
        try await store.save(state)

        await publish(.completed)
        return deliverable
    }

    // MARK: Decision helpers (pure)

    /// Confidence v0 (AD-05): an empty objective is Low — ask, never guess.
    /// Richer signals (ambiguity, missing inputs) arrive with real skills.
    private func confidence(in objective: String) -> ConfidenceTier {
        objective.isEmpty ? .low : .high
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
