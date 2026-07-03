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

    struct OpenedDeliverable: Identifiable, Equatable {
        let id: String
        let content: String
    }

    private(set) var phase: Phase = .idle
    private(set) var messages: [Message] = []
    private(set) var projects: [ProjectSummary] = []
    /// Resume data for the current project — read-through from the
    /// Application layer, never cached beyond view state.
    private(set) var overview: ProjectOverview?
    var openedDeliverable: OpenedDeliverable?
    /// The selected project (Project Isolation). "default" until the user
    /// picks or creates one; every goal runs inside the current project.
    private(set) var currentProjectID = "default"
    var draft = ""

    var isWorking: Bool {
        if case .running = phase { return true }
        return false
    }

    private let service: ChatService
    private let projectDirectory: ProjectDirectory
    private let dashboard: DashboardModel

    private(set) var dashboardSnapshot: DashboardSnapshot?

    init(service: ChatService, projects: ProjectDirectory, dashboard: DashboardModel) {
        self.service = service
        self.projectDirectory = projects
        self.dashboard = dashboard
    }

    func loadDashboard() {
        let projectID = currentProjectID
        Task { @MainActor in
            dashboardSnapshot = await dashboard.snapshot(projectID: projectID)
        }
    }

    func loadProjects() {
        Task { @MainActor in
            projects = (try? await projectDirectory.list()) ?? []
        }
        loadOverview()
    }

    func selectProject(id: String) {
        guard id != currentProjectID else { return }
        currentProjectID = id
        messages = []
        phase = .idle
        overview = nil
        loadOverview()
    }

    var searchQuery = ""
    private(set) var searchResults: [SearchHit] = []

    func runSearch() {
        let query = searchQuery
        Task { @MainActor in
            searchResults = (try? await projectDirectory.search(query)) ?? []
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }

    func openDeliverable(path: String) {
        Task { @MainActor in
            if let content = try? await projectDirectory.deliverableContent(path), let content {
                openedDeliverable = OpenedDeliverable(id: path, content: content)
            }
        }
    }

    private func loadOverview() {
        let projectID = currentProjectID
        Task { @MainActor in
            let loaded = (try? await projectDirectory.overview(projectID)) ?? nil
            if projectID == currentProjectID {
                overview = loaded
            }
        }
    }

    func createProject(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task { @MainActor in
            if let created = try? await projectDirectory.create(trimmed) {
                projects = (try? await projectDirectory.list()) ?? projects
                selectProject(id: created.id)
            }
        }
    }

    func send() {
        let goal = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !goal.isEmpty, !isWorking else { return }
        draft = ""
        messages.append(Message(role: .user, text: goal))
        phase = .running(activity: "Starting…")
        let projectID = currentProjectID

        Task {
            await service.submit(goal: goal, projectID: projectID) { update in
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
            loadOverview()
        case .failed(let message):
            messages.append(Message(role: .osiris, text: message))
            phase = .failed
        }
    }
}
