import SwiftUI

/// App entry point. The app opens directly into Chat — no dashboard first.
/// This layer is a thin shell; all intelligence lives behind the
/// Application layer (AD-35). Dependencies are wired exactly once.
@main
struct OsirisApp: App {
    private let dependencies = CompositionRoot.makeDependencies()

    var body: some Scene {
        WindowGroup {
            ChatView(
                model: ChatViewModel(service: dependencies.chat, projects: dependencies.projects),
                settings: dependencies.settings
            )
        }
    }
}
