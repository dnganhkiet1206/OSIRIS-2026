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
                model: ChatViewModel(
                    service: dependencies.chat,
                    projects: dependencies.projects,
                    dashboard: dependencies.dashboard,
                    skillList: dependencies.skillList
                ),
                settings: dependencies.settings,
                automation: dependencies.automation
            )
            // Design Language V1 (M9-1): OSIRIS is dark only; the accent is the
            // single near-white tint. Per-surface backgrounds roll out in later
            // M9 Consistency steps — this sets the base and the guarantee.
            .tint(OsirisColor.accent)
            .background(OsirisColor.background)
            .preferredColorScheme(.dark)
        }
    }
}
