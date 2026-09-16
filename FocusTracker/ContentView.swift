import SwiftUI

struct ContentView: View {
    private let store = SessionStore.shared

    var body: some View {
        NavigationStack {
            Group {
                if let completed = store.lastCompleted {
                    SummaryView(session: completed) {
                        store.lastCompleted = nil
                    }
                } else if let active = store.active {
                    ActiveSessionView(session: active)
                } else {
                    StartView()
                }
            }
            .navigationTitle("Focus Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
