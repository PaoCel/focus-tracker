import Foundation

/// A session in progress. Timing is derived from timestamps, never from a ticking counter,
/// so it stays correct while the app is suspended or killed.
struct ActiveSession: Codable, Equatable {
    var start: Date
    var state: SessionState
    /// When the current state began.
    var stateStart: Date
    /// Time accumulated in each state *before* `stateStart`.
    var focus: TimeInterval = 0
    var breakTime: TimeInterval = 0
    var offTrack: TimeInterval = 0

    init(start: Date = .now) {
        self.start = start
        self.state = .focus
        self.stateStart = start
    }

    /// Close the current state, then open the new one.
    mutating func switchTo(_ newState: SessionState, at now: Date = .now) {
        guard newState != state else { return }
        accumulateCurrentState(until: now)
        state = newState
        stateStart = now
    }

    func elapsed(at now: Date = .now) -> TimeInterval {
        max(0, now.timeIntervalSince(start))
    }

    /// Accumulated time for a state, including the running portion if it is the current state.
    func total(_ s: SessionState, at now: Date = .now) -> TimeInterval {
        accumulated(s) + (s == state ? max(0, now.timeIntervalSince(stateStart)) : 0)
    }

    /// A start date such that `now - counterStart == total(s)`. Used by `Text(timerInterval:)`
    /// in the Live Activity so the system renders a live counter without any app code running.
    func counterStart(for s: SessionState) -> Date {
        stateStart.addingTimeInterval(-accumulated(s))
    }

    func finish(at now: Date = .now) -> CompletedSession {
        var closed = self
        closed.accumulateCurrentState(until: now)
        return CompletedSession(
            id: UUID(),
            start: start,
            end: now,
            focus: closed.focus,
            breakTime: closed.breakTime,
            offTrack: closed.offTrack
        )
    }

    var contentState: FocusSessionAttributes.ContentState {
        .init(state: state, stateStart: stateStart, focus: focus, breakTime: breakTime, offTrack: offTrack)
    }

    // MARK: - Private

    func accumulated(_ s: SessionState) -> TimeInterval {
        switch s {
        case .focus: focus
        case .breakTime: breakTime
        case .offTrack: offTrack
        }
    }

    private mutating func accumulateCurrentState(until now: Date) {
        let duration = max(0, now.timeIntervalSince(stateStart))
        switch state {
        case .focus: focus += duration
        case .breakTime: breakTime += duration
        case .offTrack: offTrack += duration
        }
        stateStart = now
    }
}

/// A finished session, stored in history.
struct CompletedSession: Codable, Identifiable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    let focus: TimeInterval
    let breakTime: TimeInterval
    let offTrack: TimeInterval

    var duration: TimeInterval { end.timeIntervalSince(start) }

    /// Focus / (Focus + Off Track), rounded to whole percent. Breaks are excluded.
    /// `nil` when nothing was tracked as Focus or Off Track (e.g. a break-only session).
    var focusPercentage: Int? {
        let tracked = focus + offTrack
        guard tracked > 0 else { return nil }
        return Int((focus / tracked * 100).rounded())
    }

    var quality: SessionQuality? {
        focusPercentage.map(SessionQuality.init(percentage:))
    }
}

enum SessionQuality {
    case veryFocused, good, distracted, lostTime

    init(percentage: Int) {
        switch percentage {
        case 85...: self = .veryFocused
        case 70...84: self = .good
        case 55...69: self = .distracted
        default: self = .lostTime
        }
    }

    var label: String {
        switch self {
        case .veryFocused: "Very focused session"
        case .good: "Good session"
        case .distracted: "Distracted session"
        case .lostTime: "A lot of time was lost"
        }
    }
}
