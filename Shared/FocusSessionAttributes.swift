import ActivityKit
import Foundation

/// Data model of the Live Activity. Static part = session start; dynamic part = ContentState.
struct FocusSessionAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var state: SessionState
        var stateStart: Date
        var focus: TimeInterval
        var breakTime: TimeInterval
        var offTrack: TimeInterval

        func accumulated(_ s: SessionState) -> TimeInterval {
            switch s {
            case .focus: focus
            case .breakTime: breakTime
            case .offTrack: offTrack
            }
        }

        /// See `ActiveSession.counterStart(for:)`.
        func counterStart(for s: SessionState) -> Date {
            stateStart.addingTimeInterval(-accumulated(s))
        }
    }

    var sessionStart: Date
}
