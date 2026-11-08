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
                .tabItem { Label("命盘", systemImage: "square.grid.3x3.fill") }
                .tag(AppTab.chart)
            InsightView()
                .tabItem { Label("解读", systemImage: "text.book.closed") }
                .tag(AppTab.insight)
            BirthInputView()
                .tabItem { Label("资料", systemImage: "person.text.rectangle") }
                .tag(AppTab.input)
        }
        .background(Theme.paper)
        // nil 时跟随系统，非 nil 时强制覆盖整个窗口（含弹层与确认框）
        .preferredColorScheme(state.appearanceMode.colorScheme)
        .onAppear { state.refreshToday() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            state.refreshToday()
        }
    }
}
