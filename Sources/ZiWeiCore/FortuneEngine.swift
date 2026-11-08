import Foundation

public enum FortuneEngine {
    public static func report(for chart: Chart, on date: Date = Date()) -> DailyReport {
        let timeZone = ChineseCalendarConverter.timeZone(for: chart.input.timeZoneIdentifier)
        let components = ChineseCalendarConverter.gregorianComponents(date, timeZone: timeZone)
        let year = components.year ?? 2000
        let month = components.month ?? 1
        let day = components.day ?? 1
        let localNoon = ChineseCalendarConverter.localNoon(year: year, month: month, day: day, timeZone: timeZone)
        let lunar = ChineseCalendarConverter.lunarDate(from: localNoon, timeZone: timeZone)
        let dayIndex = Ganzhi.dayIndex(year: year, month: month, day: day)
        let dayStem = dayIndex % 10
        let activeBranch = Ganzhi.mod(lunar.yearBranch + lunar.month - 1 + lunar.day - 1, 12)
        let activePalace = chart.palace(at: activeBranch)
        let triad = [activeBranch, Ganzhi.mod(activeBranch + 4, 12), Ganzhi.mod(activeBranch + 8, 12), Ganzhi.mod(activeBranch + 6, 12)]
        let dayTransformations = ChartEngine.transformations(for: dayStem, source: .day)
        var notes: [String] = []

        let activeMainNames = activePalace.mainStars.map(\.rawValue).joined(separator: "、")
        let borrowedStars = chart.palace(at: activeBranch + 6).mainStars
        let displayMainNames = activeMainNames.isEmpty ? borrowedStars.map(\.rawValue).joined(separator: "、") : activeMainNames
        notes.append("流日命宫在\(activePalace.branchName)·\(activePalace.kind.rawValue)，\(displayMainNames.isEmpty ? "以宫位节奏为主" : "见\(displayMainNames)")")

        // 当日整体变量：流日四化落三方四正、日干与本命局的五行关系，四项分数共用同一份偏移
        var dayBias = 0
        for transformation in dayTransformations {
            guard let branch = chart.branch(of: transformation.star), triad.contains(branch) else { continue }
            let palace = chart.palace(at: branch)
            notes.append("流日\(transformation.star.rawValue)\(transformation.kind.rawValue)落入\(palace.kind.rawValue)三方四正")
            switch transformation.kind {
            case .lu: dayBias += 5
            case .quan, .ke: dayBias += 3
            case .ji: dayBias -= 6
            }
        }
        if let ji = chart.birthTransformations.first(where: { $0.kind == .ji }),
           let branch = chart.branch(of: ji.star), triad.contains(branch) {
            notes.append("本命\(ji.star.rawValue)化忌被流日引动，重要安排宜留缓冲")
            dayBias -= 2
        }

        let relation = Ganzhi.element(ofStem: dayStem).relation(to: chart.bureau)
        switch relation {
        case .same: dayBias += 2
        case .generatedBy: dayBias += 3
        case .generates: dayBias += 1
        case .controls: dayBias -= 2
        case .controlledBy: dayBias -= 3
        }
        notes.append("日干五行与\(chart.bureau.bureauName)为\(relation.rawValue)关系")

        let seed = chartSeed(chart) + "|" + ChineseCalendarConverter.localDateKey(date, timeZone: timeZone)
        dayBias += stableOffset(seed, range: 3)

        let dimensions = [
            dimension("事业", palace: chart.palace(.career), chart: chart, dayTransformations: dayTransformations, dayBias: dayBias, seed: seed + "career"),
            dimension("财务", palace: chart.palace(.wealth), chart: chart, dayTransformations: dayTransformations, dayBias: dayBias, seed: seed + "wealth"),
            dimension("人际", palace: chart.palace(.spouse), secondary: chart.palace(.friends), chart: chart, dayTransformations: dayTransformations, dayBias: dayBias, seed: seed + "relationship"),
            dimension("身心", palace: chart.palace(.health), secondary: chart.palace(.fortune), chart: chart, dayTransformations: dayTransformations, dayBias: dayBias, seed: seed + "wellbeing")
        ]
        // 综合分 = 四项算术平均，保证总分永远落在四个分项之间，不会出现「总分 75、四项最高 77」这类矛盾
        let average = Double(dimensions.reduce(0) { $0 + $1.score }) / Double(dimensions.count)
        let score = clamp(Int(average.rounded()))
        let status = status(for: score)
        let averageText = dimensions.map { "\($0.title) \($0.score)" }.joined(separator: " · ")
        notes.insert("综合分为四项平均：\(averageText) → \(score) 分", at: min(1, notes.count))

        let strongest = dimensions.max { $0.score < $1.score }!
        let weakest = dimensions.min { $0.score < $1.score }!
        let primaryStar = activePalace.mainStars.first ?? borrowedStars.first
        let profile = primaryStar.map { StarCatalog.profile($0) }
        let headline: String
        switch score {
        case 85...: headline = "状态明亮，适合主动推进"
        case 75..<85: headline = "节奏向好，把握重点事项"
        case 65..<75: headline = "整体平稳，按节奏完成即可"
        case 55..<65: headline = "宜稳宜缓，减少多线消耗"
        default: headline = "收敛蓄力，先照顾好自己"
        }
        let summary = "今日流日落入\(activePalace.kind.rawValue)，四项里\(strongest.title)最高（\(strongest.score) 分），\(weakest.title)最低（\(weakest.score) 分），综合 \(score) 分。\(profile?.keyword ?? "保持弹性")是今天可借力的主题。"
        var highlights = ["\(strongest.title) \(strongest.score) 分，四项中最高"]
        if let primaryStar {
            highlights.append("流日命宫\(primaryStar.rawValue)：\(StarCatalog.profile(primaryStar).keyword)")
        } else {
            highlights.append("流日命宫无主星，借对宫节奏")
        }
        highlights.append("流日\(Ganzhi.string(dayIndex)) · \(activePalace.kind.rawValue)当值")
        let actions = [profile?.action ?? "先完成一件确定性较高的小事", "把\(strongest.title)方面的优势用在最重要的一件事上"]
        var cautions = [profile?.caution ?? "避免临时增加过多安排"]
        cautions.append("\(weakest.title) \(weakest.score) 分，四项里最需留意：\(weakest.note)，宜降低负荷并核对细节")

        let yearTransformations = ChartEngine.transformations(for: lunar.yearStem, source: .year)
        let yearLu = yearTransformations.first { $0.kind == .lu }
        let yearTheme: String
        if let yearLu, let branch = chart.branch(of: yearLu.star) {
            yearTheme = "\(lunar.yearGanzhi)流年命宫在\(Ganzhi.branches[lunar.yearBranch])，\(yearLu.star.rawValue)化禄引动\(chart.palace(at: branch).kind.rawValue)，全年更适合围绕该领域积累机会。"
        } else {
            yearTheme = "\(lunar.yearGanzhi)流年以稳态推进为主。"
        }
        let nominalAge = max(1, lunar.gregorianYear - chart.resolvedBirth.lunarDate.gregorianYear + 1)
        let decadePalace = chart.palaces.first { $0.decadeStart...$0.decadeEnd ~= nominalAge } ?? chart.palace(.life)
        let decadeTheme = "当前虚岁 \(nominalAge)，处于\(decadePalace.ganzhi)·\(decadePalace.kind.rawValue)大限（\(decadePalace.decadeText)），阶段主题是\(decadePalace.kind.focus)。"

        return DailyReport(
            date: date,
            dateKey: ChineseCalendarConverter.localDateKey(date, timeZone: timeZone),
            lunarText: lunar.displayText,
            dayGanzhi: Ganzhi.string(dayIndex),
            yearGanzhi: lunar.yearGanzhi,
            score: score,
            status: status,
            headline: headline,
            summary: summary,
            activePalace: activePalace.kind,
            activeBranch: activeBranch,
            dimensions: dimensions,
            highlights: Array(highlights.prefix(3)),
            scoringNotes: Array(notes.prefix(6)),
            recommendedActions: actions,
            cautions: cautions,
            yearTheme: yearTheme,
            decadeTheme: decadeTheme,
            dayTransformations: dayTransformations
        )
    }

    private static func dimension(
        _ title: String,
        palace: Palace,
        secondary: Palace? = nil,
        chart: Chart,
        dayTransformations: [Transformation],
        dayBias: Int,
        seed: String
    ) -> DimensionScore {
        var quality = palace.mainStars.reduce(0) { $0 + StarCatalog.profile($1).weight }
        if let secondary { quality += secondary.mainStars.reduce(0) { $0 + StarCatalog.profile($1).weight } / 2 }
        for star in palace.auxiliaryStars {
            quality += StarCatalog.profile(star).weight
        }
        for transformation in chart.birthTransformations + dayTransformations {
            if chart.branch(of: transformation.star) == palace.branchIndex {
                switch transformation.kind {
                case .lu: quality += 3
                case .quan, .ke: quality += 2
                case .ji: quality -= 4
                }
            }
        }
        // 星曜与四化折算成有限幅度的加减，避免单宫星曜过多把分数顶到 100 或压到 0
        let contribution = max(-20, min(20, quality * 2))
        let score = clamp(68 + contribution + dayBias + stableOffset(seed, range: 3))
        let starNames = palace.mainStars.map(\.rawValue).joined(separator: "、")
        let note = starNames.isEmpty ? "空宫借对宫星曜，重在灵活应对" : "\(starNames)主调，\(StarCatalog.profile(palace.mainStars[0]).keyword)"
        return DimensionScore(title: title, score: score, note: note)
    }

    private static func status(for score: Int) -> String {
        switch score {
        case 85...: "顺势进取"
        case 75..<85: "稳中有升"
        case 65..<75: "平稳可行"
        case 55..<65: "以稳为主"
        default: "收敛蓄力"
        }
    }

    private static func chartSeed(_ chart: Chart) -> String {
        let lunar = chart.resolvedBirth.lunarDate
        return "\(lunar.sexagenaryYear)-\(lunar.month)-\(lunar.day)-\(chart.resolvedBirth.hourBranch)-\(chart.lifeBranch)-\(chart.input.gender?.rawValue ?? "")"
    }

    private static func stableOffset(_ text: String, range: Int) -> Int {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in Array(text.utf8) {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return Int(hash % UInt64(range * 2 + 1)) - range
    }

    private static func clamp(_ value: Int) -> Int { max(0, min(100, value)) }
}
