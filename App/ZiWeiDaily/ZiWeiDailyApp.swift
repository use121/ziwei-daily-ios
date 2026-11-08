import SwiftUI

@main
struct ZiWeiDailyApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .tint(Theme.cinnabar)
        }
    }
}
