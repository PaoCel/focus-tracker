import AppIntents
import SwiftUI

/// The three states a tutoring session can be in.
/// Shared by the app and the widget extension. Conforms to `AppEnum` so it can be
/// passed as a parameter to the Live Activity button intents.
enum SessionState: String, Codable, Hashable, CaseIterable, AppEnum {
    case focus
    case breakTime = "break"
    case offTrack

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Session State"

    static let caseDisplayRepresentations: [SessionState: DisplayRepresentation] = [
        .focus: "Focus",
        .breakTime: "Break",
        .offTrack: "Off Track",
    ]

    var title: String {
        switch self {
        case .focus: "Focus"
        case .breakTime: "Break"
        case .offTrack: "Off Track"
        }
    }

    var symbol: String {
        switch self {
        case .focus: "target"
        case .breakTime: "cup.and.saucer.fill"
        case .offTrack: "arrow.triangle.branch"
        }
    }

    var color: Color {
        switch self {
        case .focus: .green
        case .breakTime: .blue
        case .offTrack: .orange
        }
    }
}

extension TimeInterval {
    /// "m:ss" under one hour, "h:mm:ss" otherwise.
    var clockString: String {
        let total = Int(max(0, self).rounded(.down))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
