import SwiftUI

/// Calm, unobtrusive activity line (UI contract: activities, never
/// reasoning; no fake percentages).
struct ExecutionStatusView: View {
    let activity: String

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(activity)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExecutionStatusView(activity: "Planning…")
}
