import Foundation

/// 时间层：本命 / 大限 / 流年。
///
/// 紫微斗数的「活盘」做法：星曜位置不动，改变的是以哪一宫为命宫，
/// 十二宫名随命宫位置整体旋转（命宫起，逆时针依次为兄弟、夫妻……）。
public enum TimeLayerKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case natal = "本命"
    case decade = "大限"
    case year = "流年"
    case month = "流月"

    public var id: String { rawValue }
}

/// 一个大限区间。
public struct DecadeSlot: Codable, Identifiable, Equatable, Sendable {
    public let index: Int
    public let branch: Int
    public let startAge: Int
    public let endAge: Int

    public var id: Int { index }
    public var rangeText: String { "\(startAge)–\(endAge) 岁" }

    public func contains(age: Int) -> Bool {
        (startAge...endAge).contains(age)
    }
}

/// 某一时间层展开后的盘面语境。
public struct TimeLayer: Equatable, Sendable {
    public let kind: TimeLayerKind
    /// 该层命宫所在的地支。
    public let pivotBranch: Int
    /// 该层用于起四化的天干。
    public let stemIndex: Int
    public let year: Int?
    public let transformations: [Transformation]
    public let title: String
    public let subtitle: String
    public let decade: DecadeSlot?
    /// 流月层的农历月份，其余层为 nil。
    public let lunarMonth: Int?

    public var stemName: String { Ganzhi.stems[Ganzhi.mod(stemIndex, 10)] }
    public var pivotBranchName: String { Ganzhi.branches[Ganzhi.mod(pivotBranch, 12)] }
    public var hasTransformations: Bool { !transformations.isEmpty }
}

public extension Chart {
    /// 以出生农历年为基准的虚岁。
    func nominalAge(on date: Date = Date()) -> Int {
        let timeZone = ChineseCalendarConverter.timeZone(for: input.timeZoneIdentifier)
        let currentLunar = ChineseCalendarConverter.lunarDate(from: date, timeZone: timeZone)
        return max(1, currentLunar.gregorianYear - resolvedBirth.lunarDate.gregorianYear + 1)
    }

    /// 指定年份对应的虚岁。
    func nominalAge(inYear year: Int) -> Int {
        max(1, year - resolvedBirth.lunarDate.gregorianYear + 1)
    }

    /// 按起限年龄排序的十二个大限。
    func decades() -> [DecadeSlot] {
        palaces
            .sorted { $0.decadeStart < $1.decadeStart }
            .enumerated()
            .map { offset, palace in
                DecadeSlot(
                    index: offset,
                    branch: palace.branchIndex,
                    startAge: palace.decadeStart,
                    endAge: palace.decadeEnd
                )
            }
    }

    /// 当前虚岁所在的大限序号；超出所有区间时取最近的一个。
    func currentDecadeIndex(age: Int) -> Int {
        let slots = decades()
        if let matched = slots.first(where: { $0.contains(age: age) }) {
            return matched.index
        }
        if age < (slots.first?.startAge ?? 0) { return slots.first?.index ?? 0 }
        return slots.last?.index ?? 0
    }

    /// 命宫落在 pivot 时，某个地支对应的宫名。
    func palaceKind(at branch: Int, pivot: Int) -> PalaceKind {
        PalaceKind.allCases[Ganzhi.mod(pivot - branch, 12)]
    }

    /// 三方四正：本宫、两个三合宫、对宫。
    func triad(of branch: Int) -> [Int] {
        [Ganzhi.mod(branch, 12),
         Ganzhi.mod(branch + 4, 12),
         Ganzhi.mod(branch + 8, 12),
         Ganzhi.mod(branch + 6, 12)]
    }

    /// 借对宫：本宫无主星时取对宫主星。
    func borrowedStars(at branch: Int) -> (stars: [Star], oppositeBranch: Int)? {
        guard palace(at: branch).mainStars.isEmpty else { return nil }
        let opposite = Ganzhi.mod(branch + 6, 12)
        return (palace(at: opposite).mainStars, opposite)
    }

    /// 某一时间层的完整语境。
    func timeLayer(
        kind: TimeLayerKind,
        decadeIndex: Int? = nil,
        year: Int? = nil,
        month: Int? = nil,
        on date: Date = Date()
    ) -> TimeLayer {
        switch kind {
        case .natal:
            return TimeLayer(
                kind: .natal,
                pivotBranch: lifeBranch,
                stemIndex: resolvedBirth.lunarDate.yearStem,
                year: nil,
                transformations: birthTransformations,
                title: "本命十二宫",
                subtitle: "\(bureau.bureauName) · 命在\(Ganzhi.branches[lifeBranch])",
                decade: nil,
                lunarMonth: nil
            )

        case .decade:
            let slots = decades()
            let age = nominalAge(on: date)
            let index = decadeIndex ?? currentDecadeIndex(age: age)
            let slot = slots.first(where: { $0.index == index }) ?? slots[0]
            let palace = palace(at: slot.branch)
            return TimeLayer(
                kind: .decade,
                pivotBranch: slot.branch,
                stemIndex: palace.stemIndex,
                year: nil,
                transformations: ChartEngine.transformations(for: palace.stemIndex, source: .decade),
                title: "大限 \(slot.rangeText)",
                subtitle: "\(palace.ganzhi)宫 · \(Ganzhi.stems[palace.stemIndex])干起四化",
                decade: slot,
                lunarMonth: nil
            )

        case .year:
            let timeZone = ChineseCalendarConverter.timeZone(for: input.timeZoneIdentifier)
            let currentLunar = ChineseCalendarConverter.lunarDate(from: date, timeZone: timeZone)
            let target = year ?? currentLunar.gregorianYear
            let index = Ganzhi.mod(target - 4, 60)
            let stem = index % 10
            let branch = index % 12
            return TimeLayer(
                kind: .year,
                pivotBranch: branch,
                stemIndex: stem,
                year: target,
                transformations: ChartEngine.transformations(for: stem, source: .year),
                title: "\(target) \(Ganzhi.string(index))年",
                subtitle: "流年命宫在\(Ganzhi.branches[branch]) · \(Ganzhi.animals[branch])年",
                decade: nil,
                lunarMonth: nil
            )

        case .month:
            let timeZone = ChineseCalendarConverter.timeZone(for: input.timeZoneIdentifier)
            let currentLunar = ChineseCalendarConverter.lunarDate(from: date, timeZone: timeZone)
            let targetYear = year ?? currentLunar.gregorianYear
            let yearIndex = Ganzhi.mod(targetYear - 4, 60)
            let yearStem = yearIndex % 10
            let yearBranchIndex = yearIndex % 12
            let monthNumber = min(max(month ?? currentLunar.month, 1), 12)
            // 流月命宫：流年命宫起正月，顺数至该月
            let pivot = Ganzhi.mod(yearBranchIndex + monthNumber - 1, 12)
            // 月干用五虎遁从流年干推出
            let yinStem = Ganzhi.mod((yearStem % 5) * 2 + 2, 10)
            let monthStem = Ganzhi.mod(yinStem + monthNumber - 1, 10)
            return TimeLayer(
                kind: .month,
                pivotBranch: pivot,
                stemIndex: monthStem,
                year: targetYear,
                transformations: ChartEngine.transformations(for: monthStem, source: .month),
                title: "\(targetYear)年 农历\(monthNumber)月",
                subtitle: "月建\(Ganzhi.branches[Ganzhi.mod(2 + monthNumber - 1, 12)]) · 流月命宫在\(Ganzhi.branches[pivot])",
                decade: nil,
                lunarMonth: monthNumber
            )
        }
    }
}
