import SwiftUI

struct ActiveSessionView: View {
    let session: ActiveSession
    private let store = SessionStore.shared
    @State private var confirmEnd = false

    var body: some View {
        // TimelineView re-renders every second; all values are computed from timestamps.
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.elapsed(at: now).clockString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }

                Label(session.state.title, systemImage: session.state.symbol)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(session.state.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(session.state.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 12) {
                    ForEach(SessionState.allCases, id: \.self) { state in
                        StateButton(
                            state: state,
                            isActive: session.state == state,
                            time: session.total(state, at: now)
                        ) {
                            Task { await store.switchTo(state) }
                        }
                    }
                }

                Spacer()

                Button("End Session", role: .destructive) {
                    confirmEnd = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                // Sul bottone, non sulla TimelineView: su iOS 26 il dialogo e' un popover
                // e si ancora alla view che porta il modifier.
                .confirmationDialog("End this session?", isPresented: $confirmEnd, titleVisibility: .visible) {
                    Button("End Session", role: .destructive) {
                        Task { await store.endSession() }
                    }
                }
            }
            .padding()
        }
    }
}

private struct StateButton: View {
    let state: SessionState
    let isActive: Bool
    let time: TimeInterval
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: state.symbol)
                    .font(.title3)
                Text(state.title)
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(time.clockString)
                    .font(.title3.weight(.medium))
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundStyle(isActive ? .white : state.color)
            .background(isActive ? state.color : state.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}
