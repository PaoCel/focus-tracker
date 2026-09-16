import AppIntents

// These intents power the buttons in the Live Activity.
// `LiveActivityIntent` is executed by the system *inside the app's process* (launching the
// app in the background if needed), so they can use `SessionStore` directly.
// The file must be a member of BOTH targets: the widget references the intent types,
// the app executes them.

struct SetSessionStateIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Set Session State"
    static let isDiscoverable = false

    @Parameter(title: "State")
    var state: SessionState

    init() {}

    init(state: SessionState) {
        self.state = state
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        await SessionStore.shared.switchTo(state)
        return .result()
    }
}

struct EndSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "End Session"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        await SessionStore.shared.endSession()
        return .result()
    }
}
