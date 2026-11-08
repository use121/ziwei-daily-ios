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

/// 一份排盘档案。
struct Profile: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var input: BirthInput
}

/// 档案列表持久化结构。
private struct ProfileStore: Codable {
    var profiles: [Profile]
    var currentID: UUID?
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
    /// 流日/流时层所用的日期，默认为今天。
    @Published var layerDate: Date = Date()
    /// 流时层选中的时支（nil 表示跟随当前时间）。
    @Published var layerHourBranch: Int?
    @Published var isProUnlocked: Bool
    @Published private(set) var profiles: [Profile] = []
    @Published private(set) var currentProfileID: UUID?

    private let storageKey = "ziwei.daily.birth-input.v1"
    private let profilesKey = "ziwei.daily.profiles.v1"
    private let proKey = "ziwei.daily.pro.v1"
    /// 一生运程计算较重，按「盘 + 当天」缓存，避免每次重绘都重算。
    private var lifeCache: (key: String, overview: LifeOverview)?

    private static func defaultDate() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar.date(from: DateComponents(year: 1995, month: 1, day: 1, hour: 12)) ?? Date()
    }

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let defaultDate = Self.defaultDate()

        // 读取档案库；为空时从旧版单档案数据迁移
        let hadSavedData = UserDefaults.standard.data(forKey: profilesKey) != nil
            || UserDefaults.standard.data(forKey: storageKey) != nil
        var loaded: ProfileStore?
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            loaded = try? decoder.decode(ProfileStore.self, from: data)
        }
        if loaded?.profiles.isEmpty != false {
            var migrated: BirthInput?
            if let data = UserDefaults.standard.data(forKey: storageKey) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                migrated = try? decoder.decode(BirthInput.self, from: data)
            }
            let seedInput = migrated ?? BirthInput(birthDate: defaultDate)
            let seedName = seedInput.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let profile = Profile(
                id: UUID(),
                name: seedName.isEmpty ? "档案一" : seedName,
                input: seedInput
            )
            loaded = ProfileStore(profiles: [profile], currentID: profile.id)
        }

        let store = loaded!
        profiles = store.profiles
        let current = store.profiles.first(where: { $0.id == store.currentID }) ?? store.profiles[0]
        currentProfileID = current.id
        let initial = current.input

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
            case "day":
                selectedLayer = .day
            case "hour":
                selectedLayer = .hour
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
        if hadSavedData, let restoredChart = try? ChartEngine.makeChart(from: initial) {
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
            syncCurrentProfile()
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
        UserDefaults.standard.removeObject(forKey: profilesKey)
        let profile = Profile(id: UUID(), name: "档案一", input: BirthInput(birthDate: Self.defaultDate()))
        profiles = [profile]
        currentProfileID = profile.id
        input = profile.input
        selectedLayer = .natal
        decadeIndex = nil
        chart = nil
        report = nil
        issues = []
        selectedTab = .input
    }

    // MARK: - 档案管理

    var currentProfileName: String {
        profiles.first(where: { $0.id == currentProfileID })?.name ?? "档案"
    }

    /// 新建一份空白档案并切换过去。
    func addProfile() {
        syncCurrentProfile()
        let profile = Profile(
            id: UUID(),
            name: "档案 \(profiles.count + 1)",
            input: BirthInput(birthDate: Self.defaultDate())
        )
        profiles.append(profile)
        switchTo(profile.id, regenerate: false)
    }

    /// 删除当前档案（至少保留一份）。
    func deleteCurrentProfile() {
        guard let currentProfileID, profiles.count > 1,
              let index = profiles.firstIndex(where: { $0.id == currentProfileID }) else { return }
        profiles.remove(at: index)
        switchTo(profiles[min(index, profiles.count - 1)].id, regenerate: true)
    }

    /// 切换档案：先保存当前编辑内容，再载入目标档案并重新排盘。
    func selectProfile(_ id: UUID) {
        guard id != currentProfileID else { return }
        syncCurrentProfile()
        switchTo(id, regenerate: true)
    }

    private func switchTo(_ id: UUID, regenerate: Bool) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        currentProfileID = profile.id
        input = profile.input
        issues = []
        decadeIndex = nil
        resetLayer()
        if regenerate, let generated = try? ChartEngine.makeChart(from: input) {
            chart = generated
            report = FortuneEngine.report(for: generated)
            selectedTab = .today
        } else {
            chart = nil
            report = nil
            selectedTab = .input
        }
        persist()
    }

    /// 把当前编辑中的 input 写回当前档案；称呼非空时同步档案名。
    private func syncCurrentProfile() {
        guard let currentProfileID,
              let index = profiles.firstIndex(where: { $0.id == currentProfileID }) else { return }
        profiles[index].input = input
        let name = input.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            profiles[index].name = name
        }
    }

    // MARK: - 时间层

    var currentLayer: TimeLayer? {
        guard let chart else { return nil }
        return chart.timeLayer(
            kind: selectedLayer,
            decadeIndex: decadeIndex,
            year: layerYear,
            month: layerMonth,
            hour: selectedLayer == .hour ? layerHourBranch : nil,
            on: selectedLayer == .day || selectedLayer == .hour ? layerDate : Date()
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

    /// 十四维强弱评分，供雷达图使用。
    var topicScores: [TopicScore] {
        guard let chart, let layer = currentLayer else { return [] }
        return TopicScoreEngine.scores(chart: chart, layer: layer)
    }

    // MARK: - 一生运程

    /// 十二大限逐段综述。计算量比单层解读大，按「盘 + 当天」缓存一份。
    var lifeOverview: LifeOverview? {
        guard let chart else { return nil }
        let key = lifeCacheKey(chart)
        if let cached = lifeCache, cached.key == key {
            return cached.overview
        }
        let overview = LifeTimelineEngine.overview(for: chart)
        lifeCache = (key, overview)
        return overview
    }

    /// 命宫主星组合对应的同盘古人。
    var figureMatches: [FigureMatch] {
        guard let chart else { return [] }
        return HistoricalFigures.matches(for: chart)
    }

    private func lifeCacheKey(_ chart: Chart) -> String {
        let day = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        return [
            "\(chart.lifeBranch)",
            "\(chart.bodyBranch)",
            chart.bureau.rawValue,
            "\(chart.resolvedBirth.adjustedDate.timeIntervalSince1970)",
            "\(day)"
        ].joined(separator: "|")
    }

    /// 一生运程的文字版，供分享。
    var lifeReportText: String {
        guard let chart, let overview = lifeOverview else { return "" }
        let name = input.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        var lines: [String] = []
        lines.append(name.isEmpty ? "我的紫微·一生运程" : "\(name)的紫微·一生运程")
        lines.append("命宫在\(Ganzhi.branches[chart.lifeBranch]) · \(chart.bureau.bureauName) · \(chart.isForwardDecade ? "大限顺行" : "大限逆行")")
        lines.append("")
        lines.append(overview.headline)
        lines.append(overview.arc)
        lines.append("")
        for stage in overview.stages {
            let mark = stage.isCurrent ? "【当前】" : ""
            lines.append("\(mark)\(stage.title) · \(stage.rangeText)（\(stage.yearText)）\(stage.tone.rawValue) \(stage.score) 分")
            lines.append("  事业：\(stage.career.replacingOccurrences(of: "\n", with: " "))")
            lines.append("  家庭：\(stage.family.replacingOccurrences(of: "\n", with: " "))")
            lines.append("  父母：\(stage.parents.replacingOccurrences(of: "\n", with: " "))")
            lines.append("  身心：\(stage.health.replacingOccurrences(of: "\n", with: " "))")
            if !stage.milestones.isEmpty {
                lines.append("  节点：\(stage.milestones.joined(separator: "；"))")
            }
        }
        lines.append("")
        lines.append("【眼下要留意】")
        lines.append(contentsOf: overview.currentFocus)
        lines.append("")
        lines.append("【关键节点】")
        for node in overview.nearNodes + overview.lifeNodes {
            lines.append("\(node.yearText) \(node.ageText) \(node.kind.rawValue)：\(node.title)")
            lines.append("  \(node.detail)")
        }
        if !figureMatches.isEmpty {
            lines.append("")
            lines.append("【同盘意象】")
            for match in figureMatches {
                lines.append("\(match.figure.name)（\(match.figure.era)·\(match.figure.title)）·\(match.kind.rawValue)")
                lines.append("  \(match.figure.resonance)")
                lines.append("  可借鉴：\(match.figure.lesson)")
            }
            lines.append(HistoricalFigures.disclaimer)
        }
        lines.append("")
        lines.append("传统文化参考，不构成任何决策依据。")
        return lines.joined(separator: "\n")
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
        case .day:
            layerDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: delta, to: layerDate) ?? layerDate
        case .hour:
            let current = layerHourBranch ?? ChineseCalendarConverter.hourBranch(
                hour: Calendar.current.component(.hour, from: Date())
            )
            layerHourBranch = Ganzhi.mod(current + delta, 12)
        }
    }

    func resetLayer() {
        selectedLayer = .natal
        decadeIndex = nil
        layerYear = Calendar.current.component(.year, from: Date())
        layerMonth = Calendar(identifier: .chinese).component(.month, from: Date())
        layerDate = Date()
        layerHourBranch = nil
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

    /// 全盘报告：命盘摘要 + 十四维 + 格局 + 四化。
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
        lines.append("【十四维】")
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
        let store = ProfileStore(profiles: profiles, currentID: currentProfileID)
        if let data = try? encoder.encode(store) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }
}
