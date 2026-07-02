import Foundation
import Observation
import OsirisApplication

/// UI state for the chat screen — nothing more (AD-35). Talks only to the
/// Application layer; every mutation happens on the main actor.
@MainActor
@Observable
final class ChatViewModel {
    enum Phase: Equatable {
        case idle
        case running(activity: String)
        case needsClarification
        case failed
    }

    struct Message: Identifiable, Equatable {
        enum Role { case user, osiris }
        let id = UUID()
        let role: Role
        let text: String
    }

    private(set) var phase: Phase = .idle
    private(set) var messages: [Message] = []
    var draft = ""

    var isWorking: Bool {
        if case .running = phase { return true }
        return false
    }

    private let service: ChatService

    init(service: ChatService) {
        self.service = service
    }

    func send() {
        let goal = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !goal.isEmpty, !isWorking else { return }
        draft = ""
        messages.append(Message(role: .user, text: goal))
        phase = .running(activity: "Starting…")

        Task {
            await service.submit(goal: goal) { update in
                Task { @MainActor [weak self] in
                    self?.apply(update)
                }
            }
        }
    }

    private func apply(_ update: TaskUpdate) {
        switch update.kind {
        case .activity(let text):
            phase = .running(activity: text)
        case .needsClarification(let question):
            messages.append(Message(role: .osiris, text: question))
            phase = .needsClarification
        case .completed(let result):
            messages.append(Message(role: .osiris, text: result))
            phase = .idle
        case .failed(let message):
            messages.append(Message(role: .osiris, text: message))
            phase = .failed
        }
    }
}
