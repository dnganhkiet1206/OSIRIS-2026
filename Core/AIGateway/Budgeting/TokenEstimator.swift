import Foundation

/// Pre-flight token estimation used for budget checks before any provider is
/// contacted. Heuristic (~4 characters/token); providers report actual counts
/// after the fact. One estimator for the whole platform — never duplicate.
public enum TokenEstimator {
    public static func estimate(_ text: String) -> Int {
        max(1, text.count / 4)
    }
}
