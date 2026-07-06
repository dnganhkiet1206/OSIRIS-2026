import SwiftUI
import OsirisApplication

/// "Resume work instantly": what this project was doing and what it has
/// produced — shown when a project opens with an empty transcript.
struct ProjectResumeView: View {
    let overview: ProjectOverview
    let onOpenDeliverable: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(overview.name)
                    .font(.osirisTitle)
                if let lastGoal = overview.lastGoal {
                    Text("Last goal: \(lastGoal)")
                        .font(.osirisSecondary)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text("\(overview.completedCount) completed task\(overview.completedCount == 1 ? "" : "s")")
                    .font(.osirisCaption)
                    .foregroundStyle(.tertiary)
            }

            if !overview.deliverables.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Recent deliverables")
                        .font(.osirisCaption)
                        .foregroundStyle(.secondary)
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
                        .padding(Spacing.md)
                        .osirisCard(OsirisColor.elevated, radius: Radius.small)
                        .accessibilityLabel("Open deliverable: \(deliverable.preview)")
                    }
                }
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .osirisCard()
    }
}
