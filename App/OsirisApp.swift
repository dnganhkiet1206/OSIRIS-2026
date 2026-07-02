import SwiftUI

/// App entry point. The app opens directly into Chat — no dashboard first.
/// This layer is a thin shell; all intelligence lives in OsirisCore.
@main
struct OsirisApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
    }
}
