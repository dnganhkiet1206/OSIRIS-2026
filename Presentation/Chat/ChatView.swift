import SwiftUI

/// The application IS this screen: a simple sidebar, the conversation in
/// the center, the composer at the bottom. Minimal by design — Dashboard
/// and Settings attach to the sidebar in M2.
struct ChatView: View {
    @State private var model: ChatViewModel

    init(model: ChatViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationSplitView {
            List {
                Label("Chat", systemImage: "bubble.left.and.text.bubble.right")
            }
            .navigationTitle("OSIRIS")
        } detail: {
            VStack(spacing: 0) {
                transcript
                statusBar
                composer
            }
        }
    }

    private var transcript: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if model.messages.isEmpty {
                    emptyState
                }
                ForEach(model.messages) { message in
                    MessageRow(message: message)
                }
            }
            .padding()
        }
        .defaultScrollAnchor(.bottom)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("What do you want to accomplish?")
                .font(.title3)
                .fontWeight(.medium)
            Text("Describe a goal. OSIRIS handles the rest.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    @ViewBuilder
    private var statusBar: some View {
        if case .running(let activity) = model.phase {
            ExecutionStatusView(activity: activity)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Describe a goal…", text: $model.draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .onSubmit { model.send() }
            Button {
                model.send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(model.draft.trimmingCharacters(in: .whitespaces).isEmpty || model.isWorking)
        }
        .padding()
    }
}

private struct MessageRow: View {
    let message: ChatViewModel.Message

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == .user
                        ? AnyShapeStyle(Color.accentColor.opacity(0.15))
                        : AnyShapeStyle(.quaternary.opacity(0.5)),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            if message.role == .osiris { Spacer(minLength: 40) }
        }
    }
}
