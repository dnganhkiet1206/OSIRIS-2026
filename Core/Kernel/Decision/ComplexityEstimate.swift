import Foundation

/// Deterministic complexity estimate (M3-2, AD-42). Same input, same
/// answer — always explainable, never learned. No AI, no ML, no
/// statistics, no history-driven adjustment.
public enum ComplexityEstimate: String, Sendable {
    case simple
    case standard
    case complex

    /// Breadth-of-work signals the user states explicitly.
    private static let breadthSignals = [
        "detailed", "comprehensive", "complete", "full", "in-depth",
        "chi tiết", "toàn diện", "đầy đủ", "chuyên sâu",
    ]

    /// Heuristic over data already in the goal: length, stated breadth,
    /// and clause count. A planner that can always explain itself beats
    /// a clever one.
    public static func estimate(for objective: String) -> ComplexityEstimate {
        let lowered = objective.lowercased()
        let wordCount = lowered.split(whereSeparator: { $0.isWhitespace }).count
        // Match whole words, not substrings: a single-word signal like "full"
        // must not fire inside "carefully" or "complete" inside "autocomplete".
        // Multi-word / hyphenated signals ("chi tiết", "in-depth") are safe as
        // substrings — phrases don't appear inside unrelated words.
        let words = Set(lowered.split { !$0.isLetter }.map(String.init))
        let hasBreadthSignal = breadthSignals.contains { signal in
            signal.allSatisfy(\.isLetter) ? words.contains(signal) : lowered.contains(signal)
        }
        let clauseCount = 1
            + lowered.filter { $0 == "," || $0 == ";" }.count
            + (lowered.components(separatedBy: " and ").count - 1)
            + (lowered.components(separatedBy: " và ").count - 1)
            + (lowered.components(separatedBy: " then ").count - 1)
            + (lowered.components(separatedBy: " rồi ").count - 1)

        if hasBreadthSignal || wordCount > 25 || clauseCount >= 3 {
            return .complex
        }
        if wordCount <= 8 && clauseCount == 1 {
            return .simple
        }
        return .standard
    }

    /// The tier this estimate earns. The Kernel decides; the Gateway only
    /// consumes (tier routing activates once the catalog has ≥2 real
    /// models). A skill's own declared tier still outranks the estimate —
    /// the skill knows its work best.
    public var preferredTier: ModelTier {
        switch self {
        case .simple, .standard:
            return .light
        case .complex:
            return .standard
        }
    }
}
