import Foundation
import SwiftUI
import UIKit
import ZiWeiCore

enum AppTab: Hashable {
    case today
    case chart
    case insight
    case input
}

@MainActor
final class AppState: ObservableObject {
    @Published var input: BirthInput
    @Published private(set) var chart: Chart?
    @Published private(set) var report: DailyReport?
    @Published var issues: [InputIssue] = []
    @Published var selectedTab: AppTab
    @Published var selectedLayer: TimeLayerKind = .natal
    @Published var layerYear: Int
    @Published var decadeIndex: Int?
    @Published var layerMonth: Int
    @Published var isProUnlocked: Bool

    private let storageKey = "ziwei.daily.birth-input.v1"
    private let proKey = "ziwei.daily.pro.v1"

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
        layerYear = Calendar.current.component(.year, from: Date())
        layerMonth = Calendar(identifier: .chinese).component(.month, from: Date())
        isProUnlocked = UserDefaults.standard.object(forKey: proKey) as? Bool ?? true
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
            switch environment["ZIWEI_LAYER"] {
            case "decade":
                selectedLayer = .decade
                if let sampleChart { decadeIndex = sampleChart.currentDecadeIndex(age: sampleChart.nominalAge()) }
            case "year":
                selectedLayer = .year
            case "month":
                selectedLayer = .month
            default:
                break
            }
            switch environment["ZIWEI_TAB"] {
            case "chart": selectedTab = .chart
            case "insight": selectedTab = .insight
            case "input": selectedTab = .input
            default: selectedTab = .today
            }
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
            decadeIndex = nil
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
        selectedLayer = .natal
        decadeIndex = nil
        chart = nil
        report = nil
        issues = []
        selectedTab = .input
    }

    // MARK: - 时间层

    var currentLayer: TimeLayer? {
        guard let chart else { return nil }
        return chart.timeLayer(
            kind: selectedLayer,
            decadeIndex: decadeIndex,
            year: layerYear,
            month: layerMonth
        )
    }

    var insights: [Insight] {
        guard let chart, let layer = currentLayer else { return [] }
        return InsightEngine.insights(for: chart, layer: layer)
    }

    /// 当前层的格局组合。
    var patterns: [Pattern] {
        guard let chart, let layer = currentLayer else { return [] }
        return PatternEngine.patterns(for: chart, layer: layer)
    }

    /// 当前层的四化落点。
    var transformEntries: [TransformEntry] {
        guard let chart, let layer = currentLayer else { return [] }
        return TransformationPathEngine.entries(chart: chart, layer: layer)
    }

    var transformSummary: String {
        guard let chart, let layer = currentLayer else { return "" }
        return TransformationPathEngine.summary(chart: chart, layer: layer)
    }

    /// 十三维强弱评分，供雷达图使用。
    var topicScores: [TopicScore] {
        guard let chart, let layer = currentLayer else { return [] }
        return TopicScoreEngine.scores(chart: chart, layer: layer)
    }

    var currentDecade: DecadeSlot? {
        guard let chart, let layer = currentLayer else { return nil }
        return layer.decade ?? chart.decades()[chart.currentDecadeIndex(age: chart.nominalAge())]
    }

    func selectLayer(_ kind: TimeLayerKind) {
        selectedLayer = kind
        if kind == .decade, decadeIndex == nil, let chart {
            decadeIndex = chart.currentDecadeIndex(age: chart.nominalAge())
        }
    }

    func stepLayer(by delta: Int) {
        guard let chart else { return }
        switch selectedLayer {
        case .natal:
            break
        case .decade:
            let slots = chart.decades()
            let current = decadeIndex ?? chart.currentDecadeIndex(age: chart.nominalAge())
            decadeIndex = min(max(current + delta, 0), slots.count - 1)
        case .year:
            layerYear += delta
        case .month:
            var month = layerMonth + delta
            if month < 1 { month = 12; layerYear -= 1 }
            if month > 12 { month = 1; layerYear += 1 }
            layerMonth = month
        }
    }

    func resetLayer() {
        selectedLayer = .natal
        decadeIndex = nil
        layerYear = Calendar.current.component(.year, from: Date())
        layerMonth = Calendar(identifier: .chinese).component(.month, from: Date())
    }

    func setProUnlocked(_ value: Bool) {
        isProUnlocked = value
        UserDefaults.standard.set(value, forKey: proKey)
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

    /// 全盘报告：命盘摘要 + 十三维 + 格局 + 四化。
    var fullReportText: String {
        guard let chart, let layer = currentLayer else { return "" }
        let name = input.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = name.isEmpty ? "我的紫微命盘" : "\(name)的紫微命盘"
        var lines: [String] = []
        lines.append(title)
        lines.append("\(layer.kind.rawValue)：\(layer.title)")
        lines.append("阳历 \(chart.resolvedBirth.lunarDate.gregorianYear) 年 · 农历 \(chart.resolvedBirth.lunarDate.displayText) · \(chart.bureau.bureauName)")
        lines.append("命宫在\(Ganzhi.branches[chart.lifeBranch])｜身宫在\(Ganzhi.branches[chart.bodyBranch])｜命主\(chart.soulMaster.rawValue)｜身主\(chart.bodyMaster.rawValue)")
        lines.append("")
        lines.append("【十三维】")
        for score in topicScores {
            lines.append("\(score.topic.rawValue) \(score.score)")
        }
        if !patterns.isEmpty {
            lines.append("")
            lines.append("【格局】")
            for pattern in patterns {
                lines.append("\(pattern.name)（\(pattern.kind.rawValue)）：\(pattern.summary)")
            }
        }
        lines.append("")
        lines.append("【四化】")
        lines.append(transformSummary)
        for entry in transformEntries {
            lines.append("· \(entry.text)")
        }
        lines.append("")
        lines.append("【今日】")
        if let report {
            lines.append("\(report.score)/100 · \(report.status)")
            lines.append(report.summary)
        }
        lines.append("")
        lines.append("传统文化参考，不构成任何决策依据。")
        return lines.joined(separator: "\n")
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(input) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
