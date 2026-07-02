import SwiftUI

/// App entry point. The app opens directly into Chat — no dashboard first.
/// This layer is a thin shell; all intelligence lives behind the
/// Application layer (AD-35). Dependencies are wired exactly once.
@main
struct OsirisApp: App {
    private let chatService = CompositionRoot.makeChatService()
    private let providerSettings = CompositionRoot.makeProviderSettings()

    var body: some Scene {
        WindowGroup {
            ChatView(
                model: ChatViewModel(service: chatService),
                settings: providerSettings
            )
        }
    }
}
