import SwiftUI
import OsirisApplication

/// Minimal settings (M1-0): connect or disconnect the AI provider.
/// The stored key is never displayed back; only the status is shown.
struct SettingsView: View {
    let settings: ProviderSettings

    @State private var draftKey = ""
    @State private var status: ProviderStatus = .offline
    @State private var feedback: String?
    /// UI preference only (AD-40) — never platform data.
    @AppStorage("osiris.advancedMode") private var advancedMode = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Status", value: status == .connected ? "Connected" : "Offline mode")
                SecureField("Anthropic API key", text: $draftKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Save Key") { saveKey() }
                    .disabled(draftKey.trimmingCharacters(in: .whitespaces).isEmpty)
                if status == .connected {
                    Button("Remove Key", role: .destructive) { removeKey() }
                }
            } header: {
                Text("AI Provider")
            } footer: {
                Text("Changes apply after the app restarts. Without a key, OSIRIS runs in offline mode.")
            }

            Section {
                Toggle("Advanced Mode", isOn: $advancedMode)
            } footer: {
                Text("Shows read-only developer panels in the sidebar. Off by default — normal use never needs it.")
            }

            if let feedback {
                Section {
                    Text(feedback)
                        // M9-3: unified to .caption, the app's standard small-text
                        // font (was .footnote, used nowhere else).
                        .font(.caption)
                        .foregroundStyle(OsirisColor.textSecondary)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear { status = settings.currentStatus() }
    }

    private func saveKey() {
        do {
            try settings.setKey(draftKey.trimmingCharacters(in: .whitespacesAndNewlines))
            draftKey = ""
            status = settings.currentStatus()
            feedback = "Key saved securely. Restart the app to connect."
        } catch {
            feedback = "Couldn't save the key. Try again."
        }
    }

    private func removeKey() {
        do {
            try settings.removeKey()
            status = settings.currentStatus()
            feedback = "Key removed. The app runs in offline mode after restart."
        } catch {
            feedback = "Couldn't remove the key. Try again."
        }
    }
}
