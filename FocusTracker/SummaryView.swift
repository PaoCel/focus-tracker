import SwiftUI

struct SummaryView: View {
    let session: CompletedSession
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            SessionBreakdown(session: session)
            Spacer()
            Button {
                onDone()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

/// Shared by the summary screen and the history detail screen.
struct SessionBreakdown: View {
    let session: CompletedSession

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                if let pct = session.focusPercentage, let quality = session.quality {
                    Text("\(pct)%")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                    Text("Focus")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(quality.label)
                        .font(.headline)
                } else {
                    Text("—")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                    Text("No Focus or Off Track time recorded")
                        .font(.headline)
                }
            }

            VStack(spacing: 0) {
                row("Total duration", session.duration, color: .primary)
                Divider()
                row("Focus", session.focus, color: SessionState.focus.color)
                Divider()
                row("Break", session.breakTime, color: SessionState.breakTime.color)
                Divider()
                row("Off Track", session.offTrack, color: SessionState.offTrack.color)
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

            Text("Focus % = Focus ÷ (Focus + Off Track). Breaks are not counted.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func row(_ title: String, _ value: TimeInterval, color: Color) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(color)
            Spacer()
            Text(value.clockString)
                .monospacedDigit()
        }
        .padding()
    }
}
