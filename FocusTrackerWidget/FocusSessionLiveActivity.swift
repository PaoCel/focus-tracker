import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The whole activity takes the colour of the current state: the Lock Screen banner is
/// tinted edge to edge, the Dynamic Island (whose black shell is system-drawn) gets a
/// tinted keyline and a full-width tinted card in the expanded view.
struct FocusSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionAttributes.self) { context in
            // Lock Screen / banner
            LockScreenView(context: context)
                .padding(14)
                .activityBackgroundTint(context.state.state.color)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    StateBadge(state: context.state.state, tint: context.state.state.color)
                        .invalidatableContent()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    SessionTimer(start: context.attributes.sessionStart)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        TimeRow(state: context.state)
                        ControlRow(current: context.state.state)
                    }
                    .padding(12)
                    .foregroundStyle(.white)
                    .background(context.state.state.color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.state.symbol)
                    .foregroundStyle(context.state.state.color)
                    .invalidatableContent()
            } compactTrailing: {
                SessionTimer(start: context.attributes.sessionStart)
                    .font(.caption.monospacedDigit())
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: context.state.state.symbol)
                    .foregroundStyle(context.state.state.color)
                    .invalidatableContent()
            }
            .keylineTint(context.state.state.color)
        }
    }
}

// MARK: - Lock Screen

private struct LockScreenView: View {
    let context: ActivityViewContext<FocusSessionAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StateBadge(state: context.state.state, tint: .white)
                    .invalidatableContent()
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
    let tint: Color

    var body: some View {
        Label(state.title, systemImage: state.symbol)
            .font(.headline)
            .foregroundStyle(tint)
    }
}

/// Accumulated Focus / Break / Off Track on the tinted background. The current state
/// shows a live counter, the other two show static values. Marked invalidatable so the
/// system shimmers it as soon as a button is pressed, before the update lands.
private struct TimeRow: View {
    let state: FocusSessionAttributes.ContentState

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SessionState.allCases, id: \.self) { s in
                VStack(spacing: 2) {
                    Text(s.title)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                    if s == state.state {
                        let start = state.counterStart(for: s)
                        Text(timerInterval: start...start.addingTimeInterval(12 * 3600), countsDown: false)
                            .font(.callout.weight(.bold))
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                    } else {
                        Text(state.accumulated(s).clockString)
                            .font(.callout.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .invalidatableContent()
    }
}

/// The interactive buttons on the tinted background: the current state is a solid white
/// pill, the others are translucent. Each one runs a LiveActivityIntent in the app's process.
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
                        .foregroundStyle(s == current ? s.color : .white)
                        .background(s == current ? Color.white : Color.white.opacity(0.22),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            Button(intent: EndSessionIntent()) {
                Image(systemName: "stop.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .foregroundStyle(.white)
                    .background(Color.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .invalidatableContent()
    }
}
