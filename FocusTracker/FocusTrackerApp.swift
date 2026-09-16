import SwiftUI

@main
struct FocusTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await SessionStore.shared.refresh() }
            }
        }
    }
}
