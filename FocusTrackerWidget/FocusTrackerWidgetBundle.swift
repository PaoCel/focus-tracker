import SwiftUI
import WidgetKit

@main
struct FocusTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusSessionLiveActivity()
    }
}
