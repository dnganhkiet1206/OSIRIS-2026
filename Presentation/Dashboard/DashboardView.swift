import SwiftUI
import OsirisApplication

/// Operational awareness, exactly the BLUEPRINT list — never an analytics
/// page. No charts, no trends, no fake percentages.
struct DashboardView: View {
    @Bindable var model: ChatViewModel

    var body: some View {
        List {
            if let snapshot = model.dashboardSnapshot {
                Section("Now") {
                    LabeledContent("Project", value: snapshot.projectName)
                    LabeledContent("Current goal", value: snapshot.currentGoal ?? "Idle")
                    if let last = snapshot.lastCompletedTask {
                        LabeledContent("Last completed", value: last)
                            .lineLimit(2)
                    }
                    LabeledContent("Completed tasks", value: "\(snapshot.completedCount)")
                }

                Section("Today's usage") {
                    LabeledContent("AI requests", value: "\(snapshot.usage.requests)")
                    LabeledContent(
                        "Tokens",
                        value: "\(snapshot.usage.tokensIn) in · \(snapshot.usage.tokensOut) out"
                    )
                    LabeledContent("Cost", value: String(format: "$%.4f", snapshot.usage.costUSD))
                    LabeledContent("Cache hits", value: "\(snapshot.usage.cacheHits)")
                }

                Section("System") {
                    LabeledContent("AI provider", value: snapshot.providerConnected ? "Connected" : "Offline mode")
                }

                if !snapshot.recentActivity.isEmpty {
                    Section("Recent activity") {
                        ForEach(Array(snapshot.recentActivity.prefix(6).enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("Loading…")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Dashboard")
        .task { model.loadDashboard() }
        .refreshable { model.loadDashboard() }
    }
}
