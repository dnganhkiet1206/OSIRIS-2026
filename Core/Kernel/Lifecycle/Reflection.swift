import Foundation

/// Deterministic reflection v1 (AD-41): looks ONLY at what already
/// happened and proposes at most one MemoryCandidate. No AI, no tokens,
/// no Store access, no persistence — the Write Gate decides, the Store
/// persists. Criteria are deliberately strict: trustworthy memory over
/// more memory; when in doubt, propose nothing.
enum Reflection {
    /// Minimum words before a goal carries a topic signal worth remembering.
    private static let minimumGoalWords = 4

    static func candidate(
        goal: Goal,
        strategy: ExecutionStrategy,
        deliverablePath: String?
    ) -> MemoryCandidate? {
        // Only freshly produced content is worth noting: reuse already
        // lives on disk, tool results are free to recompute (AD-37).
        switch strategy {
        case .ai, .composition:
            break
        case .reuse, .tool, .direct, .hybrid:
            return nil
        }
        guard let path = deliverablePath else { return nil }
        let words = goal.text.split(whereSeparator: { $0.isWhitespace })
        guard words.count >= minimumGoalWords else { return nil }

        return MemoryCandidate(
            projectID: goal.projectID,
            content: "Recently completed: \(goal.text) — deliverable at \(path)",
            justifications: [.reusableLater]
        )
    }
}
