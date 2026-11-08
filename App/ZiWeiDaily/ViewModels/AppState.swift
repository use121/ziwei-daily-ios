import Foundation
import SwiftUI
import UIKit
import ZiWeiCore

enum AppTab: Hashable {
    case today
    case chart
    case input
}

@MainActor
final class AppState: ObservableObject {
    @Published var input: BirthInput
    @Published private(set) var chart: Chart?
    @Published private(set) var report: DailyReport?
    @Published var issues: [InputIssue] = []
    @Published var selectedTab: AppTab

    private let storageKey = "ziwei.daily.birth-input.v1"

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let defaultDate = calendar.date(from: DateComponents(year: 1995, month: 1, day: 1, hour: 12)) ?? Date()
        var restored: BirthInput?
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            restored = try? decoder.decode(BirthInput.self, from: data)
        }
        let initial = restored ?? BirthInput(birthDate: defaultDate)
        input = initial
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["ZIWEI_SAMPLE"] == "1" {
            let sample = BirthInput(
                displayName: "林知夏",
                birthDate: calendar.date(from: DateComponents(year: 1990, month: 6, day: 15, hour: 9, minute: 30))!,
                gender: .female,
                birthplace: "上海",
                longitudeText: "121.4737"
            )
            input = sample
            let sampleChart = try? ChartEngine.makeChart(from: sample)
            chart = sampleChart
            report = sampleChart.map { FortuneEngine.report(for: $0) }
            selectedTab = environment["ZIWEI_TAB"] == "chart" ? .chart : .today
            return
        }
        #endif
        if restored != nil, let restoredChart = try? ChartEngine.makeChart(from: initial) {
            chart = restoredChart
            report = FortuneEngine.report(for: restoredChart)
            selectedTab = .today
        } else {
            selectedTab = .input
        }
    }

    func generateChart() {
        do {
            let generated = try ChartEngine.makeChart(from: input)
            chart = generated
            report = FortuneEngine.report(for: generated)
            issues = []
            persist()
            selectedTab = .today
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch let error as InputValidationError {
            issues = error.issues
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            issues = [InputIssue(field: "unknown", message: "暂时无法排盘，请检查输入后重试")]
        }
    }

    func refreshToday() {
        guard let chart else { return }
        report = FortuneEngine.report(for: chart, on: Date())
    }

    func clearLocalData() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let defaultDate = calendar.date(from: DateComponents(year: 1995, month: 1, day: 1, hour: 12)) ?? Date()
        input = BirthInput(birthDate: defaultDate)
        chart = nil
        report = nil
        issues = []
        selectedTab = .input
    }

    var shareText: String {
        guard let report, let chart else { return "" }
        let name = input.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        \(name.isEmpty ? "我的" : name + "的")紫微日常 · \(report.dateKey)
        今日 \(report.score)/100 · \(report.status)
        \(report.headline)
        \(report.summary)
        事业 \(report.dimensions[0].score)｜财务 \(report.dimensions[1].score)｜人际 \(report.dimensions[2].score)｜身心 \(report.dimensions[3].score)
        流日：\(report.dayGanzhi)，落于\(chart.palace(at: report.activeBranch).kind.rawValue)。
        传统文化参考，不构成专业决策建议。
        """
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(input) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
