import Foundation
import Observation
import OsirisApplication

/// UI state for the Automation screen (M6-2). A SEPARATE ViewModel per
/// surface on purpose: ChatViewModel already carries five roles and the
/// M2-6 trigger says the next UI task must split, not extend it — so
/// automation gets its own ViewModel instead of a sixth role.
///
/// Talks only to the Application layer (`Automation` port, AD-35); every
/// mutation happens on the main actor. Running a rule reuses the exact
/// Kernel path a typed goal uses (AD-47) — this screen adds no execution.
@MainActor
@Observable
final class AutomationViewModel {
    private(set) var rules: [AutomationRuleSummary] = []
    var draftGoal = ""
    private(set) var runningRuleID: String?
    private(set) var lastResult: String?

    private let automation: Automation

    init(automation: Automation) {
        self.automation = automation
    }

    func load() {
        Task { @MainActor in
            rules = (try? await automation.list()) ?? []
        }
    }

    func create() {
        let goal = draftGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !goal.isEmpty else { return }
        draftGoal = ""
        Task { @MainActor in
            // v1 rules run in the default project; per-project automation
            // waits for evidence of need (AD-28).
            _ = try? await automation.create(goal, "default")
            load()
        }
    }

    func toggle(_ rule: AutomationRuleSummary) {
        Task { @MainActor in
            try? await automation.setEnabled(rule.id, !rule.enabled)
            load()
        }
    }

    func delete(_ id: String) {
        Task { @MainActor in
            try? await automation.delete(id)
            load()
        }
    }

    func run(_ id: String) {
        guard runningRuleID == nil else { return }
        runningRuleID = id
        lastResult = nil
        Task {
            await automation.runNow(id) { update in
                Task { @MainActor [weak self] in
                    self?.apply(update)
                }
            }
        }
    }

    private func apply(_ update: TaskUpdate) {
        switch update.kind {
        case .activity:
            break
        case .needsClarification(let question):
            lastResult = question
            runningRuleID = nil
        case .completed(let result):
            lastResult = result
            runningRuleID = nil
        case .failed(let message):
            lastResult = message
            runningRuleID = nil
        }
    }
}
