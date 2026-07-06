import SwiftUI
import OsirisApplication

/// Advanced Mode (M2-5): read-only panels for power users, hidden by
/// default. Inventory and status only — no destructive actions, no
/// dev-tool platform. Fuller viewers arrive when real need appears.
struct AdvancedView: View {
    @Bindable var model: ChatViewModel

    var body: some View {
        List {
            Section("Skills") {
                if model.skillInfos.isEmpty {
                    Text("No skills registered")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.skillInfos) { skill in
                        // M9-2: unified with the reference metadata stack (was 2pt).
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text(skill.id)
                                    .font(.subheadline.monospaced())
                                if skill.isComposition {
                                    Text("composition")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.quaternary, in: Capsule())
                                }
                                Spacer()
                                Text("v\(skill.version)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(skill.purpose)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("System") {
                LabeledContent("Skills registered", value: "\(model.skillInfos.count)")
                LabeledContent(
                    "AI provider",
                    value: (model.dashboardSnapshot?.providerConnected ?? false) ? "Connected" : "Offline mode"
                )
                LabeledContent(
                    "App version",
                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
                )
            }
        }
        .navigationTitle("Advanced")
        .task {
            model.loadSkills()
            model.loadDashboard()
        }
    }
}
