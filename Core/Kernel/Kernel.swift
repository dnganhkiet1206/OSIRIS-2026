import Foundation
import OsirisInfrastructure

/// The Executive Brain — the ONLY place allowed to choose (AD-01, AD-25).
/// Orchestrates the canonical five-phase lifecycle (AD-12):
/// Intake → Decide → Execute → Verify → Persist.
///
/// The Kernel never produces deliverables itself, never calls a provider
/// directly, and contains no business logic. "Executive State" is whatever
/// this class holds in memory during a request — it is never persisted
/// separately (AD-08).
public final class Kernel: Sendable {
    private let skills: any SkillRegistry
    private let engine: any ExecutionEngine
    private let store: any Store
    private let approvalGate: any ApprovalGate
    private let events: EventBus<ExecutionEvent>

    public init(
        skills: any SkillRegistry,
        engine: any ExecutionEngine,
        store: any Store,
        approvalGate: any ApprovalGate,
        events: EventBus<ExecutionEvent>
    ) {
        self.skills = skills
        self.engine = engine
        self.store = store
        self.approvalGate = approvalGate
        self.events = events
    }

    /// Handles one goal through the five phases. M0 scope: linear pipeline,
    /// Decide only distinguishes direct vs ai. Resource-order decision,
    /// reuse checks via Store.search, confidence handling and risk gating
    /// are layered in during M0-4/M1 — inside these same phases, never as a
    /// second pipeline.
    public func handle(_ goal: Goal) async throws -> Deliverable {
        // 1. INTAKE — understand the objective. (M0: accept as given.)
        await events.publish(.understanding)

        // 2. DECIDE — choose the cheapest sufficient strategy.
        await events.publish(.planning)
        let plan = ExecutionPlan(goal: goal, strategy: .direct)

        // 3. EXECUTE — the engine does the work; the Kernel never does.
        await events.publish(.executing)
        let result = try await engine.run(plan)

        // 4. VERIFY — never return a broken deliverable.
        guard !result.deliverable.content.isEmpty else {
            await events.publish(.failed("Empty deliverable"))
            throw KernelError.verificationFailed
        }

        // 5. PERSIST — update the single source of truth.
        await events.publish(.updatingState)
        var state = try await store.projectState(for: goal.projectID)
            ?? ProjectState(projectID: goal.projectID)
        state.recordCompletion(of: goal.text)
        try await store.save(state)

        await events.publish(.completed)
        return result.deliverable
    }
}

public enum KernelError: Error, Sendable {
    case verificationFailed
}
