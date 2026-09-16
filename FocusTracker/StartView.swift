import ActivityKit
import SwiftUI

struct StartView: View {
    private let store = SessionStore.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Track Focus, Break and Off Track time during a tutoring session.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()

            if !ActivityAuthorizationInfo().areActivitiesEnabled {
                Text("Live Activities are off for this app. Enable them in Settings to get Lock Screen controls.")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task { await store.startSession() }
            } label: {
                Text("Start Session")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
