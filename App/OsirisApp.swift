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
            // Design Language V1 (M9-1): OSIRIS is dark only (an intentional
            // product decision) with a single near-white accent. Per-surface
            // backgrounds (OsirisColor.background/.elevated) roll out later as
            // one complete surface migration — NavigationSplitView still owns
            // several system surfaces, so a root background would only be
            // partial. This keeps the guarantee (dark) and the accent.
            .tint(OsirisColor.accent)
            .preferredColorScheme(.dark)
        }
    }
}
