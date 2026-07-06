/// Context budget priority (AD-13). When assembly exceeds budget, discard
/// from the bottom up: optional first, critical never.
public enum ContextPriority: Int, Codable, Sendable, Comparable {
    case critical = 0
    case important = 1
    case helpful = 2
    case optional = 3

    public static func < (lhs: ContextPriority, rhs: ContextPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
