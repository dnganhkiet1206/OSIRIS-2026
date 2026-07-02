import Foundation

/// Bootstrap engine: executes the two strategies M0 needs (direct, ai).
/// Tool execution, parallel independent tasks, composition running and
/// resume-after-suspend arrive in M1 behind this same interface.
public struct DefaultExecutionEngine: ExecutionEngine {
    private let gateway: any AIGateway

    public init(gateway: any AIGateway) {
        self.gateway = gateway
    }

    public func run(_ plan: ExecutionPlan) async throws -> ExecutionResult {
        switch plan.strategy {
        case .ai:
            let response = try await gateway.complete(
                AIRequest(task: plan.goal.text, projectID: plan.goal.projectID)
            )
            return ExecutionResult(
                deliverable: Deliverable(content: response.text),
                aiMetrics: response.metrics
            )
        case .direct, .tool, .composition, .hybrid:
            // M0 placeholder: only .direct is meaningfully used; the others
            // are wired in M1. Returning the goal echo keeps the pipeline
            // observable end-to-end without cost.
            return ExecutionResult(
                deliverable: Deliverable(content: "Completed directly: \(plan.goal.text)")
            )
        }
    }
}
