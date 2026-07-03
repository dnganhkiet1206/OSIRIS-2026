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
                if let lastGoal = overview.lastGoal {
                    Text("Last goal: \(lastGoal)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text("\(overview.completedCount) completed task\(overview.completedCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if !overview.deliverables.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent deliverables")
                        .font(.caption)
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
                        .padding(8)
                        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("Open deliverable: \(deliverable.preview)")
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
    }
}
