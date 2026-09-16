import SwiftUI

struct SummaryView: View {
    let session: CompletedSession
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Session complete")
                        .font(.title2.weight(.bold))
                    Text(session.timeRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                SessionBreakdown(session: session)
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                onDone()
            } label: {
                Text("Done")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

/// Shared by the summary screen and the history detail screen.
struct SessionBreakdown: View {
    let session: CompletedSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            SessionRing(session: session, progress: progress, lineWidth: 22, gap: 0.035)
                .frame(width: 216, height: 216)
                .overlay { centerLabel }
                .shadow(color: (session.quality?.color ?? .secondary).opacity(0.18), radius: 28, y: 10)
                .padding(.vertical, 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilitySummary)

            if let quality = session.quality {
                Label(quality.label, systemImage: quality.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(quality.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(quality.color.opacity(0.14), in: Capsule())
            } else {
                Text("No Focus or Off Track time recorded")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach(SessionState.allCases, id: \.self) { state in
                    StatCard(state: state, time: session.time(for: state))
                }
            }

            Label("\(session.duration.clockString) total", systemImage: "clock")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Text("Focus % = Focus ÷ (Focus + Off Track). Breaks are not counted.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            if reduceMotion {
                progress = 1
            } else {
                withAnimation(.easeOut(duration: 1.0).delay(0.15)) { progress = 1 }
            }
        }
    }

    private var centerLabel: some View {
        VStack(spacing: 0) {
            Text(session.focusPercentage.map { "\($0)%" } ?? "—")
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text("Focus")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 40)
    }

    private var accessibilitySummary: String {
        let pct = session.focusPercentage.map { "\($0) percent focus" } ?? "No focus data"
        return "\(pct). Focus \(session.focus.clockString), break \(session.breakTime.clockString), off track \(session.offTrack.clockString)."
    }
}

/// Donut with one segment per state, proportional to time. `progress` (0...1) grows all
/// segments from the top clockwise, for the reveal animation.
struct SessionRing: View {
    let session: CompletedSession
    var progress: Double = 1
    var lineWidth: CGFloat
    /// Fraction of the circle left empty between segments (0 for tiny rings).
    var gap: Double = 0

    private struct Segment: Identifiable {
        let id: SessionState
        let start: Double
        let end: Double
    }

    private var segments: [Segment] {
        let tracked = SessionState.allCases
            .map { ($0, session.time(for: $0)) }
            .filter { $0.1 > 0 }
        let total = tracked.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return [] }
        let gap = tracked.count > 1 ? gap : 0
        var cursor = 0.0
        return tracked.map { state, time in
            let span = time / total
            let start = cursor + gap / 2
            // Round caps make even a zero-length trim visible as a dot, so a tiny
            // segment never vanishes.
            let end = max(start, cursor + span - gap / 2)
            cursor += span
            return Segment(id: state, start: start, end: end)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.quaternarySystemFill), lineWidth: lineWidth)
            ForEach(segments) { segment in
                Circle()
                    .trim(from: segment.start * progress, to: segment.end * progress)
                    .stroke(segment.id.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(lineWidth / 2)
    }
}

private struct StatCard: View {
    let state: SessionState
    let time: TimeInterval

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: state.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(state.color)
            Text(time.clockString)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(state.title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension CompletedSession {
    /// "16 Sep 2026, 22:34 – 22:37"
    var timeRange: String {
        "\(start.formatted(date: .abbreviated, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))"
    }
}

extension SessionQuality {
    var color: Color {
        switch self {
        case .veryFocused: .green
        case .good: .mint
        case .distracted: .orange
        case .lostTime: .red
        }
    }

    var symbol: String {
        switch self {
        case .veryFocused: "star.fill"
        case .good: "checkmark.circle.fill"
        case .distracted: "exclamationmark.circle.fill"
        case .lostTime: "xmark.circle.fill"
        }
    }
}
