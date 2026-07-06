import SwiftUI
import OsirisApplication

/// Saved-goal automation (M6-1/M6-2): save a goal, run it again on demand.
/// Scheduled (.daily) firing is iOS background — device-pending; the port
/// and data model are ready. Manual "Run now" reuses the Kernel (AD-47).
struct AutomationView: View {
    @State private var model: AutomationViewModel
    /// The app executes one task at a time (ChatService). When a chat goal is
    /// in flight, "Run now" would just fail — disable it instead.
    private let isAppBusy: Bool

    init(automation: Automation, isAppBusy: Bool) {
        _model = State(initialValue: AutomationViewModel(automation: automation))
        self.isAppBusy = isAppBusy
    }

    var body: some View {
        List {
            Section("New automation") {
                HStack(spacing: Spacing.md) {
                    TextField("Saved goal…", text: $model.draftGoal, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)
                        .onSubmit { model.create() }
                    Button {
                        model.create()
                    } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                    .accessibilityLabel("Save automation")
                    .disabled(model.draftGoal.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Saved") {
                if model.rules.isEmpty {
                    Text("No automations yet. Save a goal to run it again with one tap.")
                        .foregroundStyle(OsirisColor.textSecondary)
                }
                ForEach(model.rules) { rule in
                    AutomationRow(
                        rule: rule,
                        isRunning: model.runningRuleID == rule.id,
                        // One execution slot: a chat goal (isAppBusy) or any
                        // automation already running takes it. Disable Run now
                        // so the tap can't hit "a task is already running".
                        runDisabled: !rule.enabled || model.runningRuleID != nil || isAppBusy,
                        run: { model.run(rule.id) },
                        toggle: { model.toggle(rule) },
                        delete: { model.delete(rule.id) }
                    )
                }
            }

            if let result = model.lastResult {
                Section("Last run") {
                    Text(result).textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Automation")
        .task { model.load() }
    }
}

private struct AutomationRow: View {
    let rule: AutomationRuleSummary
    let isRunning: Bool
    let runDisabled: Bool
    let run: () -> Void
    let toggle: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(rule.goalText).lineLimit(2)
            HStack(spacing: Spacing.xl) {
                Button(action: run) {
                    Label(isRunning ? "Running…" : "Run now", systemImage: "play.fill")
                }
                .disabled(runDisabled)
                Button(action: toggle) {
                    Label(
                        rule.enabled ? "Enabled" : "Disabled",
                        systemImage: rule.enabled ? "checkmark.circle.fill" : "circle"
                    )
                }
                Button(role: .destructive, action: delete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(.vertical, Spacing.xs)
    }
}
