import Foundation

/// Declared reasons a memory candidate claims (the AD-20 categories —
/// raw values match Config/policies.json `storeWriteGate.requiresAnyOf`).
public enum WriteJustification: String, Codable, Sendable {
    case reusableLater
    case affectsArchitecture
    case reducesFutureTokens
}

/// What Reflection proposes. A candidate is a proposal, never a record —
/// only the Write Gate can turn it into something persistable, and only
/// the Store can persist it. Trustworthy memory over more memory.
public struct MemoryCandidate: Equatable, Sendable {
    public let projectID: ProjectID
    public let content: String
    public let justifications: Set<WriteJustification>

    public init(projectID: ProjectID, content: String, justifications: Set<WriteJustification>) {
        self.projectID = projectID
        self.content = content
        self.justifications = justifications
    }
}

/// Write policy — pure data decoded from Config/policies.json. Behavior
/// changes with the config, never with code (Configuration First).
public struct WritePolicy: Sendable {
    public let requiresAnyOf: [WriteJustification]
    public let workingContextTTLHours: Double

    public init(requiresAnyOf: [WriteJustification], workingContextTTLHours: Double) {
        self.requiresAnyOf = requiresAnyOf
        self.workingContextTTLHours = workingContextTTLHours
    }

    /// Admits nothing — the safe default wherever no policy was composed.
    public static let disabled = WritePolicy(requiresAnyOf: [], workingContextTTLHours: 0)
}

/// The ONLY decision point for memory writes (AD-20): write or not, and
/// where. Pure policy evaluation — persistence itself still happens only
/// through the Store. Nothing may bypass this gate; the architecture test
/// suite enforces that memory records are born here.
public struct WriteGate: Sendable {
    private let policy: WritePolicy

    public init(policy: WritePolicy) {
        self.policy = policy
    }

    /// nil = rejected. v1 destination: WorkingContext with the policy TTL —
    /// self-expiring, so an imperfect memory cleans itself up. Knowledge
    /// writes stay closed until their AD-20 justifications gain a consumer.
    public func admit(_ candidate: MemoryCandidate, now: Date = Date()) -> WorkingContextRecord? {
        guard !candidate.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        guard candidate.justifications.contains(where: policy.requiresAnyOf.contains) else {
            return nil
        }
        return WorkingContextRecord(
            id: "reflection-\(UUID().uuidString)",
            projectID: candidate.projectID,
            content: candidate.content,
            expiresAt: now.addingTimeInterval(policy.workingContextTTLHours * 3600)
        )
    }
}
