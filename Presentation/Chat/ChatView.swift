import SwiftUI

/// The application IS this screen. M0 placeholder shell; the working chat
/// with execution status events is task M0-5.
struct ChatView: View {
    @State private var input = ""

    var body: some View {
        VStack {
            Spacer()
            Text("OSIRIS")
                .font(.title2)
                .fontWeight(.semibold)
            Text("What do you want to accomplish?")
                .foregroundStyle(.secondary)
            Spacer()
            HStack {
                TextField("Describe a goal…", text: $input)
                    .textFieldStyle(.roundedBorder)
                Button("Go") {
                    // Wired to Kernel in M0-5.
                }
                .disabled(input.isEmpty)
            }
            .padding()
        }
    }
}

#Preview {
    ChatView()
}
