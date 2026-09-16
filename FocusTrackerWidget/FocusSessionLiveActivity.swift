import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct FocusSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionAttributes.self) { context in
            // Lock Screen / banner
            LockScreenView(context: context)
                .padding(12)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    StateBadge(state: context.state.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    SessionTimer(start: context.attributes.sessionStart)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        TimeRow(state: context.state)
                        ControlRow(current: context.state.state)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.state.symbol)
                    .foregroundStyle(context.state.state.color)
            } compactTrailing: {
                SessionTimer(start: context.attributes.sessionStart)
                    .font(.caption.monospacedDigit())
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: context.state.state.symbol)
                    .foregroundStyle(context.state.state.color)
            }
            .keylineTint(context.state.state.color)
        }
    }
}

// MARK: - Lock Screen

private struct LockScreenView: View {
    let context: ActivityViewContext<FocusSessionAttributes>

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                StateBadge(state: context.state.state)
                Spacer()
                SessionTimer(start: context.attributes.sessionStart)
                    .font(.title3.weight(.semibold))
            }
            TimeRow(state: context.state)
            ControlRow(current: context.state.state)
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Pieces

/// Elapsed session time, rendered by the system as a live counter.
private struct SessionTimer: View {
    let start: Date

    var body: some View {
        Text(timerInterval: start...start.addingTimeInterval(12 * 3600), countsDown: false)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}

private struct StateBadge: View {
    let state: SessionState

    var body: some View {
        Label(state.title, systemImage: state.symbol)
            .font(.headline)
            .foregroundStyle(state.color)
    }
}

/// Accumulated Focus / Break / Off Track. The current state shows a live counter,
/// the other two show static values.
private struct TimeRow: View {
    let state: FocusSessionAttributes.ContentState

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SessionState.allCases, id: \.self) { s in
                VStack(spacing: 2) {
                    Text(s.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if s == state.state {
                        let start = state.counterStart(for: s)
                        Text(timerInterval: start...start.addingTimeInterval(12 * 3600), countsDown: false)
                            .font(.callout.weight(.semibold))
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(s.color)
                    } else {
                        Text(state.accumulated(s).clockString)
                            .font(.callout.weight(.semibold))
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

/// The interactive buttons. Each one runs a LiveActivityIntent inside the app's process.
private struct ControlRow: View {
    let current: SessionState

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SessionState.allCases, id: \.self) { s in
                Button(intent: SetSessionStateIntent(state: s)) {
                    Text(s.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(s == current ? .white : s.color)
                        .background(s == current ? s.color : s.color.opacity(0.25),
                                    in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            Button(intent: EndSessionIntent()) {
                Image(systemName: "stop.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .foregroundStyle(.white)
                    .background(Color.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }
}
