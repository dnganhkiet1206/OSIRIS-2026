import SwiftUI
import OsirisApplication

/// Saved-goal automation (M6-1/M6-2): save a goal, run it again on demand.
/// Scheduled (.daily) firing is iOS background — device-pending; the port
/// and data model are ready. Manual "Run now" reuses the Kernel (AD-47).
struct AutomationView: View {
    @State private var model: AutomationViewModel

    init(automation: Automation) {
        _model = State(initialValue: AutomationViewModel(automation: automation))
    }

    var body: some View {
        List {
            Section("New automation") {
                HStack(spacing: 8) {
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
                        .foregroundStyle(.secondary)
                }
                ForEach(model.rules) { rule in
                    AutomationRow(
                        rule: rule,
                        isRunning: model.runningRuleID == rule.id,
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
    let run: () -> Void
    let toggle: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(rule.goalText).lineLimit(2)
            HStack(spacing: 16) {
                Button(action: run) {
                    Label(isRunning ? "Running…" : "Run now", systemImage: "play.fill")
                }
                .disabled(isRunning || !rule.enabled)
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
        .padding(.vertical, 4)
    }
}
