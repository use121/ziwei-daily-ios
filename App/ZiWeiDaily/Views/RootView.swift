import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        TabView(selection: $state.selectedTab) {
            TodayView()
                .tabItem { Label("今日", systemImage: "sun.max") }
                .tag(AppTab.today)
            ChartView()
                .tabItem { Label("命盘", systemImage: "square.grid.4x4.fill") }
                .tag(AppTab.chart)
            BirthInputView()
                .tabItem { Label("资料", systemImage: "person.text.rectangle") }
                .tag(AppTab.input)
        }
        .background(Theme.paper)
        .onAppear { state.refreshToday() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            state.refreshToday()
        }
    }
}
