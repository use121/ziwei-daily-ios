import SwiftUI
import WidgetKit
import ZiWeiCore

// MARK: - 时间线

struct TodayEntry: TimelineEntry {
    let date: Date
    let profileName: String
    /// nil 表示还读不到共享档案（用户没在 App 里排过盘，或重签后 keychain 分组变了）
    let chart: Chart?
    let report: DailyReport?

    static func sample(date: Date = Date()) -> TodayEntry {
        TodayEntry(date: date, profileName: "示例", chart: nil, report: nil)
    }
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), profileName: "紫微日常", chart: nil, report: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(at: now)
        // 跨过零点就要重算；否则一天内保持，避免无谓刷新
        let calendar = Calendar.current
        let nextMidnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func makeEntry(at date: Date) -> TodayEntry {
        guard let payload = SharedStore.load(),
              let chart = try? ChartEngine.makeChart(from: payload.input) else {
            return TodayEntry(date: date, profileName: "", chart: nil, report: nil)
        }
        return TodayEntry(
            date: date,
            profileName: payload.name,
            chart: chart,
            report: FortuneEngine.report(for: chart, on: date)
        )
    }
}

// MARK: - 组件

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ZiWeiTodayWidget", provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetTheme.background }
        }
        .configurationDisplayName("今日状态")
        .description("看今天的分数、四项状态与流日。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
