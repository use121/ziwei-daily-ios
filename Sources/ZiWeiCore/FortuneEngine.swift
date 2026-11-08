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
        var rawScore = 64

        let activeMainNames = activePalace.mainStars.map(\.rawValue).joined(separator: "、")
        let borrowedStars = chart.palace(at: activeBranch + 6).mainStars
        let displayMainNames = activeMainNames.isEmpty ? borrowedStars.map(\.rawValue).joined(separator: "、") : activeMainNames
        notes.append("流日命宫在\(activePalace.branchName)·\(activePalace.kind.rawValue)，\(displayMainNames.isEmpty ? "以宫位节奏为主" : "见\(displayMainNames)")")

        for transformation in dayTransformations {
            guard let branch = chart.branch(of: transformation.star), triad.contains(branch) else { continue }
            let palace = chart.palace(at: branch)
            notes.append("流日\(transformation.star.rawValue)\(transformation.kind.rawValue)落入\(palace.kind.rawValue)三方四正")
            switch transformation.kind {
            case .lu: rawScore += 7
            case .quan: rawScore += 4
            case .ke: rawScore += 4
            case .ji: rawScore -= 9
            }
        }
        for transformation in chart.birthTransformations {
            guard let branch = chart.branch(of: transformation.star), triad.contains(branch) else { continue }
            switch transformation.kind {
            case .lu: rawScore += 3
            case .quan: rawScore += 2
            case .ke: rawScore += 2
            case .ji: rawScore -= 4
            }
        }
        if let ji = chart.birthTransformations.first(where: { $0.kind == .ji }),
           let branch = chart.branch(of: ji.star), triad.contains(branch) {
            notes.append("本命\(ji.star.rawValue)化忌被流日引动，重要安排宜留缓冲")
        }

        for branch in triad {
            let palace = chart.palace(at: branch)
            let multiplier = branch == activeBranch ? 2 : 1
            rawScore += palace.mainStars.reduce(0) { $0 + StarCatalog.profile($1).weight } * multiplier / 2
            for star in palace.auxiliaryStars {
                switch star {
                case .wenChang, .wenQu, .zuoFu, .youBi, .tianKui, .tianYue, .luCun, .hongLuan, .tianXi:
                    rawScore += branch == activeBranch ? 1 : 0
                case .qingYang, .tuoLuo, .diKong, .diJie:
                    rawScore -= branch == activeBranch ? 2 : 1
                default: break
                }
            }
        }

        let relation = Ganzhi.element(ofStem: dayStem).relation(to: chart.bureau)
        switch relation {
        case .same: rawScore += 2
        case .generatedBy: rawScore += 3
        case .generates: rawScore += 1
        case .controls: rawScore -= 2
        case .controlledBy: rawScore -= 4
        }
        notes.append("日干五行与\(chart.bureau.bureauName)为\(relation.rawValue)关系")

        let seed = chartSeed(chart) + "|" + ChineseCalendarConverter.localDateKey(date, timeZone: timeZone)
        rawScore += stableOffset(seed, range: 4)
        let score = clamp(rawScore)
        let status = status(for: score)

        let dimensions = [
            dimension("事业", palace: chart.palace(.career), overall: score, chart: chart, dayTransformations: dayTransformations, seed: seed + "career"),
            dimension("财务", palace: chart.palace(.wealth), overall: score, chart: chart, dayTransformations: dayTransformations, seed: seed + "wealth"),
            dimension("人际", palace: chart.palace(.spouse), secondary: chart.palace(.friends), overall: score, chart: chart, dayTransformations: dayTransformations, seed: seed + "relationship"),
            dimension("身心", palace: chart.palace(.health), secondary: chart.palace(.fortune), overall: score, chart: chart, dayTransformations: dayTransformations, seed: seed + "wellbeing")
        ]
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
        let summary = "今日流日落入\(activePalace.kind.rawValue)，\(strongest.title)相对占优，\(weakest.title)需要多留余地。\(profile?.keyword ?? "保持弹性")是今天可借力的主题。"
        var highlights = ["\(strongest.title) \(strongest.score) 分，是今天较顺的一项"]
        if let primaryStar { highlights.append("\(primaryStar.rawValue)主调：\(StarCatalog.profile(primaryStar).keyword)") }
        highlights.append("流日为\(Ganzhi.string(dayIndex))，重点关注\(activePalace.kind.focus)")
        let actions = [profile?.action ?? "先完成一件确定性较高的小事", "把\(strongest.title)方面的优势用在最重要的一件事上"]
        var cautions = [profile?.caution ?? "避免临时增加过多安排"]
        cautions.append("\(weakest.title)分数较低：\(weakest.note)，宜降低负荷并核对细节")

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
        overall: Int,
        chart: Chart,
        dayTransformations: [Transformation],
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
        let score = clamp(overall + quality * 2 + stableOffset(seed, range: 4))
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
