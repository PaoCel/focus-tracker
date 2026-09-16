import ActivityKit
import Foundation

/// Starts, updates and ends the single Live Activity that mirrors the active session.
enum LiveActivityManager {
    private static var activities: [Activity<FocusSessionAttributes>] {
        Activity<FocusSessionAttributes>.activities
    }

    static func start(_ session: ActiveSession) async {
        await end() // never run two at once
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            _ = try Activity.request(
                attributes: FocusSessionAttributes(sessionStart: session.start),
                content: ActivityContent(state: session.contentState, staleDate: nil)
            )
        } catch {
            print("Live Activity request failed: \(error)")
        }
    }

    static func update(_ session: ActiveSession) async {
        let content = ActivityContent(state: session.contentState, staleDate: nil)
        for activity in activities {
            await activity.update(content)
        }
    }

    static func end() async {
        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// Make the Live Activity match the stored session (e.g. after a reboot or if the
    /// system dismissed it).
    static func reconcile(with session: ActiveSession?) async {
        guard let session else {
            await end()
            return
        }
        if activities.isEmpty {
            await start(session)
        } else {
            await update(session)
        }
    }
}
