import Foundation
import OsirisInfrastructure

/// The production engine: executes exactly what the Kernel decided —
/// reuse materialization, deterministic tools, skill compositions and AI
/// calls via the Gateway. Mechanical throughout (AD-25): it never selects,
/// swaps or reorders anything.
public struct DefaultExecutionEngine: ExecutionEngine {
    private let gateway: any AIGateway
    private let logger: any Logging

    public init(gateway: any AIGateway, logger: any Logging = ConsoleLogger()) {
        self.gateway = gateway
        self.logger = logger
    }

    /// The previous step's output is appended whole but capped — an
    /// unbounded chain input would silently inflate token usage.
    private static let maxPreviousCharacters = 6000

    private func logToolRun(_ tool: any Tool, start: Date, succeeded: Bool) {
        logger.log(LogEvent(
            level: succeeded ? .info : .error,
            message: "tool.run",
            metadata: [
                "tool": tool.id.rawValue,
                "durationSeconds": String(format: "%.3f", Date().timeIntervalSince(start)),
                "succeeded": String(succeeded),
            ]
        ))
    }

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
        case .tool(let tool):
            // Deterministic execution: zero AI, zero tokens. Minimal metrics
            // (AD-37) — name, duration, outcome — through the platform
            // logger; no telemetry framework.
            let start = Date()
            do {
                let output = try await tool.run(ToolInput(parameters: ["goal": plan.goal.text]))
                logToolRun(tool, start: start, succeeded: true)
                return ExecutionResult(deliverable: Deliverable(content: output.content))
            } catch {
                logToolRun(tool, start: start, succeeded: false)
                throw error
            }
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
        case .direct, .hybrid:
            // M0 placeholder: only .direct is meaningfully used; the others
            // are wired in M1. Returning the goal echo keeps the pipeline
            // observable end-to-end without cost.
            return ExecutionResult(
                deliverable: Deliverable(content: "Completed directly: \(plan.goal.text)")
            )
        }
    }
}
