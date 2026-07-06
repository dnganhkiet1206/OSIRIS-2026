import SwiftUI
import OsirisApplication

/// "Resume work instantly": what this project was doing and what it has
/// produced — shown when a project opens with an empty transcript.
struct ProjectResumeView: View {
    let overview: ProjectOverview
    let onOpenDeliverable: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(overview.name)
                    .font(.headline)
                    .foregroundStyle(OsirisColor.textPrimary)
                if let lastGoal = overview.lastGoal {
                    Text("Last goal: \(lastGoal)")
                        .font(.subheadline)
                        .foregroundStyle(OsirisColor.textSecondary)
                        .lineLimit(2)
                }
                Text("\(overview.completedCount) completed task\(overview.completedCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(OsirisColor.textTertiary)
            }

            if !overview.deliverables.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent deliverables")
                        .font(.caption)
                        .foregroundStyle(OsirisColor.textSecondary)
                    ForEach(overview.deliverables) { deliverable in
                        Button {
                            onOpenDeliverable(deliverable.id)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text(deliverable.preview)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .osirisCard(OsirisColor.elevated, radius: Radius.small)
                        .accessibilityLabel("Open deliverable: \(deliverable.preview)")
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .osirisCard()
    }
}
