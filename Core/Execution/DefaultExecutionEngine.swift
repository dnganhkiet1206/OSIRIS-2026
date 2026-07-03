import Foundation

/// Bootstrap engine: executes the two strategies M0 needs (direct, ai).
/// Tool execution, parallel independent tasks, composition running and
/// resume-after-suspend arrive in M1 behind this same interface.
public struct DefaultExecutionEngine: ExecutionEngine {
    private let gateway: any AIGateway

    public init(gateway: any AIGateway) {
        self.gateway = gateway
    }

    /// The previous step's output is appended whole but capped — an
    /// unbounded chain input would silently inflate token usage.
    private static let maxPreviousCharacters = 6000

    /// Mechanical assembly of declared data (AD-25): substitute {goal} in
    /// the declared template, append the capped previous-step result.
    /// Nothing is decided or rewritten here.
    static func assembleTask(template: String?, goal: String, previous: String?) -> String {
        var task = template?.replacingOccurrences(of: "{goal}", with: goal) ?? goal
        if let previous {
            task += "\n\nResult of the previous step:\n\(String(previous.prefix(maxPreviousCharacters)))"
        }
        return task
    }

    public func run(_ plan: ExecutionPlan) async throws -> ExecutionResult {
        switch plan.strategy {
        case .reuse(let existing):
            // Mechanical materialization of the Kernel's reuse decision —
            // zero AI cost, no Store access (AD-25).
            return ExecutionResult(deliverable: Deliverable(content: existing))
        case .composition(let steps):
            // Sequential, mechanical, exactly as declared (AD-36): no step
            // reordering, no step skipping, no flow optimization. Each
            // step's output feeds the next; the last output is the
            // deliverable. Every step is one measured Gateway call.
            var previous: String?
            var lastMetrics: AIRequestMetrics?
            for step in steps {
                let response = try await gateway.complete(
                    AIRequest(
                        task: Self.assembleTask(template: step.promptTemplate, goal: plan.goal.text, previous: previous),
                        projectID: plan.goal.projectID,
                        preferredTier: plan.preferredTier
                    )
                )
                previous = response.text
                lastMetrics = response.metrics
            }
            // An empty chain yields empty content, which the Kernel's
            // Verify gate rejects — never a half-finished deliverable.
            return ExecutionResult(
                deliverable: Deliverable(content: previous ?? ""),
                aiMetrics: lastMetrics
            )
        case .ai(let skill):
            let response = try await gateway.complete(
                AIRequest(
                    task: Self.assembleTask(template: skill?.promptTemplate, goal: plan.goal.text, previous: nil),
                    projectID: plan.goal.projectID,
                    preferredTier: plan.preferredTier
                )
            )
            return ExecutionResult(
                deliverable: Deliverable(content: response.text),
                aiMetrics: response.metrics
            )
        case .direct, .tool, .hybrid:
            // M0 placeholder: only .direct is meaningfully used; the others
            // are wired in M1. Returning the goal echo keeps the pipeline
            // observable end-to-end without cost.
            return ExecutionResult(
                deliverable: Deliverable(content: "Completed directly: \(plan.goal.text)")
            )
        }
    }
}
