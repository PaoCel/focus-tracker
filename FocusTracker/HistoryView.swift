import SwiftUI

struct HistoryView: View {
    private let store = SessionStore.shared

    var body: some View {
        Group {
            if store.history.isEmpty {
                ContentUnavailableView("No sessions yet", systemImage: "clock.arrow.circlepath")
            } else {
                List {
                    ForEach(store.history) { session in
                        NavigationLink(value: session) {
                            HistoryRow(session: session)
                        }
                    }
                    .onDelete { store.deleteHistory(at: $0) }
                }
            }
        }
        .navigationTitle("History")
        .navigationDestination(for: CompletedSession.self) { session in
            ScrollView {
                SessionBreakdown(session: session)
                    .padding()
            }
            .navigationTitle(session.start.formatted(date: .abbreviated, time: .shortened))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct HistoryRow: View {
    let session: CompletedSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.start.formatted(date: .abbreviated, time: .shortened))
                Text(session.duration.clockString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            Text(session.focusPercentage.map { "\($0)%" } ?? "—")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
    }
}
