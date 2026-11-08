import Foundation

/// 一个十年的整体气象。
public enum StageTone: String, Codable, CaseIterable, Sendable {
    case rising = "上升"
    case steady = "平稳"
    case turning = "转折"
    case straining = "承压"

    public var symbol: String {
        switch self {
        case .rising: "arrow.up.right"
        case .steady: "equal"
        case .turning: "arrow.triangle.2.circlepath"
        case .straining: "exclamationmark.triangle"
        }
    }

    public var advice: String {
        switch self {
        case .rising: "条件在往上走，适合把要紧的事往前推"
        case .steady: "节奏平稳，靠持续投入换结果"
        case .turning: "旧路走不通的地方会显形，宜主动换轨"
        case .straining: "外部条件偏紧，先保底线再谈扩张"
        }
    }
}

/// 一个大限（十年）的阶段综述。
public struct LifeStage: Identifiable, Codable, Equatable, Sendable {
    public let index: Int
    public let startAge: Int
    public let endAge: Int
    public let startYear: Int
    public let endYear: Int
    public let branch: Int
    /// 该大限命宫落在本命的哪一宫，决定这十年的主题。
    public let natalKind: PalaceKind
    public let ganzhi: String
    public let stars: [Star]
    public let title: String
    public let themeLine: String
    public let score: Int
    public let tone: StageTone
    public let career: String
    public let family: String
    public let parents: String
    public let health: String
    public let milestones: [String]
    public let isCurrent: Bool

    public var id: Int { index }
    public var rangeText: String { "\(startAge)–\(endAge) 岁" }
    public var yearText: String { "\(startYear)–\(endYear)" }
    public var starsText: String {
        stars.isEmpty ? "空宫" : stars.map(\.rawValue).joined(separator: "、")
    }
    /// 超出常规寿命的末段大限，界面上做弱化处理。
    public var isExtended: Bool { startAge >= 90 }
}

public enum KeyNodeKind: String, Codable, Sendable {
    case opening = "开运"
    case caution = "留意"
    case turning = "转折"
}

public enum KeyNodeScope: String, Codable, Sendable {
    case near = "近期"
    case life = "一生"
}

/// 一生里的关键年份。
public struct KeyNode: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let age: Int
    public let year: Int
    public let kind: KeyNodeKind
    public let scope: KeyNodeScope
    public let title: String
    public let detail: String

    public var ageText: String { "\(age) 岁" }
    public var yearText: String { "\(year) 年" }
}

/// 一生运程的总览。
public struct LifeOverview: Codable, Equatable, Sendable {
    public let headline: String
    public let arc: String
    public let stages: [LifeStage]
    public let currentStageIndex: Int
    /// 当前阶段要留意的几件事。
    public let currentFocus: [String]
    public let keyNodes: [KeyNode]

    public var current: LifeStage? {
        stages.first { $0.index == currentStageIndex }
    }

    public var bestStage: LifeStage? {
        stages.max { $0.score < $1.score }
    }

    public var hardestStage: LifeStage? {
        stages.min { $0.score < $1.score }
    }

    /// 近期关键年份（当前与未来两个大限）。
    public var nearNodes: [KeyNode] {
        keyNodes.filter { $0.scope == .near }
    }

    /// 一生的两个极端：最顺与最需预备的十年。
    public var lifeNodes: [KeyNode] {
        keyNodes.filter { $0.scope == .life }
    }
}

/// 按十二大限生成「一生运程」：每段给出事业、家庭、父母、身心四条线，
/// 再挑出当前阶段的注意事项与一生里的关键年份。全程规则生成，无随机成分。
public enum LifeTimelineEngine {
    public static func overview(for chart: Chart, referenceDate: Date = Date()) -> LifeOverview {
        let slots = chart.decades()
        let birthYear = chart.resolvedBirth.lunarDate.gregorianYear
        let age = chart.nominalAge(on: referenceDate)
        let currentIndex = chart.currentDecadeIndex(age: age)

        let stages = slots.map { slot in
            stage(
                slot: slot,
                chart: chart,
                birthYear: birthYear,
                isCurrent: slot.index == currentIndex
            )
        }

        let currentStage = stages.first { $0.index == currentIndex } ?? stages[0]
        let best = stages.max { $0.score < $1.score } ?? currentStage
        let worst = stages.min { $0.score < $1.score } ?? currentStage

        let headline = "\(starNames(effectiveStars(chart, chart.lifeBranch)))坐命，"
            + "此刻走「\(currentStage.title)」（\(currentStage.rangeText)）；"
            + "十二运程里「\(best.title)」（\(best.rangeText)）气最顺，"
            + "「\(worst.title)」最需要提前预备。"

        return LifeOverview(
            headline: headline,
            arc: arcText(stages: stages),
            stages: stages,
            currentStageIndex: currentIndex,
            currentFocus: focusText(chart: chart, stage: currentStage, referenceDate: referenceDate),
            keyNodes: keyNodes(chart: chart, stages: stages, currentIndex: currentIndex, birthYear: birthYear, referenceDate: referenceDate)
        )
    }

    // MARK: - 单个大限

    private static func stage(
        slot: DecadeSlot,
        chart: Chart,
        birthYear: Int,
        isCurrent: Bool
    ) -> LifeStage {
        let pivot = slot.branch
        let palace = chart.palace(at: pivot)
        let stars = effectiveStars(chart, pivot)
        let transforms = ChartEngine.transformations(for: palace.stemIndex, source: .decade)
        let startYear = birthYear + slot.startAge - 1

        let score = stageScore(chart: chart, pivot: pivot, stars: stars, transforms: transforms)
        let tone = stageTone(score: score, stars: stars)
        let keyword = stars.first.map { StarCatalog.profile($0).keyword } ?? "随势调整"

        // 落在本命命宫时换一种说法，避免「本命命宫」连读
        let placeText = palace.kind == .life ? "本命宫" : "本命\(kindName(palace.kind))"
        let moveText = palace.kind == .life ? "回到" : "命宫行至"
        let themeLine = "大限\(moveText)\(placeText)（\(palace.ganzhi)），"
            + "\(keyword)是这十年的主调。"

        return LifeStage(
            index: slot.index,
            startAge: slot.startAge,
            endAge: slot.endAge,
            startYear: startYear,
            endYear: startYear + (slot.endAge - slot.startAge),
            branch: pivot,
            natalKind: palace.kind,
            ganzhi: palace.ganzhi,
            stars: stars,
            title: stageTitle(palace.kind),
            themeLine: themeLine,
            score: score,
            tone: tone,
            career: careerText(chart: chart, pivot: pivot, transforms: transforms),
            family: familyText(chart: chart, pivot: pivot, transforms: transforms),
            parents: parentsText(chart: chart, pivot: pivot, transforms: transforms),
            health: healthText(chart: chart, pivot: pivot, transforms: transforms),
            milestones: milestones(
                chart: chart,
                pivot: pivot,
                startAge: slot.startAge,
                endAge: slot.endAge,
                birthYear: birthYear
            ),
            isCurrent: isCurrent
        )
    }

    private static func stageScore(
        chart: Chart,
        pivot: Int,
        stars: [Star],
        transforms: [Transformation]
    ) -> Int {
        var raw = 63.0
        raw += Double(stars.reduce(0) { $0 + StarCatalog.profile($1).weight }) * 1.8
        raw += BrightnessCatalog.averageWeight(of: stars, at: pivot) * 3.2

        let triad = chart.triad(of: pivot)
        for transformation in transforms {
            guard let branch = chart.branch(of: transformation.star), triad.contains(branch) else { continue }
            let direct = branch == pivot
            switch transformation.kind {
            case .lu: raw += direct ? 6 : 4
            case .quan: raw += direct ? 4.5 : 3
            case .ke: raw += direct ? 4 : 2.5
            case .ji: raw -= direct ? 7 : 4.5
            }
        }

        for star in chart.palace(at: pivot).auxiliaryStars {
            switch star {
            case .qingYang, .tuoLuo, .diKong, .diJie: raw -= 1.8
            case .luCun, .zuoFu, .youBi: raw += 1.2
            case .tianKui, .tianYue: raw += 1.5
            default: break
            }
        }

        return min(93, max(42, Int(raw.rounded())))
    }

    private static func stageTone(score: Int, stars: [Star]) -> StageTone {
        if score >= 80 { return .rising }
        if score < 56 { return .straining }
        if stars.contains(.poJun) || stars.contains(.qiSha) { return .turning }
        return .steady
    }

    private static func stageTitle(_ kind: PalaceKind) -> String {
        switch kind {
        case .life: "立身"
        case .siblings: "并肩"
        case .spouse: "结缘"
        case .children: "育成"
        case .wealth: "蓄势"
        case .health: "调养"
        case .travel: "远行"
        case .friends: "结众"
        case .career: "任事"
        case .property: "筑基"
        case .fortune: "养心"
        case .parents: "承教"
        }
    }

    /// 「命宫」本身已带宫字，其余补一个宫字，避免出现「本命命宫宫」。
    private static func kindName(_ kind: PalaceKind) -> String {
        kind == .life ? "命宫" : "\(kind.rawValue)宫"
    }

    // MARK: - 四条线

    private static func careerText(chart: Chart, pivot: Int, transforms: [Transformation]) -> String {
        let branch = Ganzhi.mod(pivot - 8, 12)
        let palace = chart.palace(at: branch)
        let stars = effectiveStars(chart, branch)
        var text = "官禄宫在\(palace.ganzhi)，"
        if let first = stars.first {
            text += "见\(starNames(stars))。\(StarCatalog.profile(first).keyword)是这十年的工作重心，\(StarCatalog.profile(first).action)。"
        } else {
            text += "不见主星，事业以借力与变动为主，跟对人比岗位本身更重要。"
        }
        text += hintSentence(lineHint(transforms, chart: chart, branch: branch), line: .career)
        return text
    }

    private static func familyText(chart: Chart, pivot: Int, transforms: [Transformation]) -> String {
        let spouseBranch = Ganzhi.mod(pivot - 2, 12)
        let childBranch = Ganzhi.mod(pivot - 3, 12)
        let spouse = chart.palace(at: spouseBranch)
        let spouseStars = effectiveStars(chart, spouseBranch)
        let childStars = effectiveStars(chart, childBranch)
        var text = "夫妻宫在\(spouse.ganzhi)，见\(starNames(spouseStars))；子女宫见\(starNames(childStars))。"
        if let first = spouseStars.first {
            text += familyAdvice(first)
        } else {
            text += "感情上重实际配合多于形式，遇事多商量，少用沉默表态。"
        }
        let festiveStars = chart.palace(at: spouseBranch).auxiliaryStars
            + chart.palace(at: childBranch).auxiliaryStars
        let festive = festiveStars.contains(.hongLuan) || festiveStars.contains(.tianXi)
        if festive {
            text += "鸾喜入夫妻或子女，婚育、添丁一类的事在这十年较容易成形。"
        }
        text += hintSentence(lineHint(transforms, chart: chart, branch: spouseBranch), line: .family)
        return text
    }

    private static func parentsText(chart: Chart, pivot: Int, transforms: [Transformation]) -> String {
        let branch = Ganzhi.mod(pivot - 11, 12)
        let palace = chart.palace(at: branch)
        let stars = effectiveStars(chart, branch)
        var text = "父母宫在\(palace.ganzhi)，见\(starNames(stars))。"
        if let first = stars.first {
            text += parentsAdvice(first) + StarCatalog.profile(first).caution + "。"
        } else {
            text += "长辈助力不显，很多事要自己拿主意，也少受牵制。"
        }
        text += hintSentence(lineHint(transforms, chart: chart, branch: branch), line: .parents)
        return text
    }

    private static func healthText(chart: Chart, pivot: Int, transforms: [Transformation]) -> String {
        let branch = Ganzhi.mod(pivot - 5, 12)
        let palace = chart.palace(at: branch)
        let stars = effectiveStars(chart, branch)
        let shaCount = palace.auxiliaryStars.filter {
            [.qingYang, .tuoLuo, .diKong, .diJie, .huoXing, .lingXing].contains($0)
        }.count
        var text = "疾厄宫在\(palace.ganzhi)，见\(starNames(stars))。"
        if shaCount >= 2 {
            text += "煞星聚在这里，属于「累积型」的消耗：熬夜、久坐、情绪憋着，都会在这十年一起结账。"
        } else if let first = stars.first {
            text += healthFlavor(first)
        } else {
            text += "无主星守，状态多随外境起伏，作息规律就是最好的保养。"
        }
        text += hintSentence(lineHint(transforms, chart: chart, branch: branch), line: .health)
        return text
    }

    private static func familyAdvice(_ star: Star) -> String {
        switch star {
        case .tanLang, .lianZhen, .taiYin, .tianTong, .tianYao:
            return "关系里更看重感受与氛围，把需求讲具体，比暗示有用。"
        case .wuQu, .qiSha, .poJun, .qingYang, .tuoLuo:
            return "关系里容易硬碰硬，先处理情绪，再谈事情。"
        case .juMen, .tianJi:
            return "关系里话说得多，听懂多少才是关键，重要的事复述一遍。"
        case .ziWei, .tianFu, .tianXiang, .tianLiang:
            return "关系里重视责任与秩序，别把「我做了」当成「你该知道」。"
        default:
            return "关系里的核心议题是\(StarCatalog.profile(star).keyword)，先把它说出口，比让对方猜有效。"
        }
    }

    private static func parentsAdvice(_ star: Star) -> String {
        switch star {
        case .ziWei, .tianFu, .tianLiang:
            return "长辈这边重分寸：尊重位置，但不必事事请示；"
        case .qiSha, .poJun, .wuQu:
            return "与长辈之间容易硬碰硬，态度可以软，底线要清；"
        case .juMen, .tianJi:
            return "与长辈的沟通容易落在道理上，先接住情绪再讲逻辑；"
        case .tianTong, .taiYin:
            return "长辈的关心会比较密，学会温和地划边界；"
        default:
            return "长辈与制度这一块，靠稳定往来而不是临时求助；"
        }
    }

    private static func healthFlavor(_ star: Star) -> String {
        switch star {
        case .ziWei: return "底子不差，但习惯什么都自己扛，累的时候不容易承认；把分派当成保养的一部分。"
        case .tianJi: return "脑力消耗大于体力，睡不好比累更伤；固定的收工时间比补品有用。"
        case .taiYang: return "精力外放，忙起来容易忘了吃、忘了睡；给自己留白比硬撑有效。"
        case .wuQu: return "能扛但不够灵活，容易带伤硬上；运动要渐进，别一次加太满。"
        case .tianTong: return "状态随情绪走，心情一松身体就轻；规律三餐比突击进补有用。"
        case .lianZhen: return "情绪与身体联动明显，火气上来时睡眠最先受影响；少熬夜、少硬碰。"
        case .tianFu: return "耐受力好，问题常被「还能撑」掩盖；定期检查比自我感觉可靠。"
        case .taiYin: return "体质偏敏感，气色与睡眠容易跟着作息走；把入睡时间固定下来最有效。"
        case .tanLang: return "应酬与新鲜感是主要消耗源，节制比进补重要；别把行程排满。"
        case .juMen: return "思虑与口舌耗气，咽喉与肠胃常先有反应；说话之间记得停顿、喝水。"
        case .tianXiang: return "外形撑得住，内里容易虚；别为了顾全别人压缩自己的休息。"
        case .tianLiang: return "总体底子偏厚，但容易把小毛病拖大；有不舒服早一点查。"
        case .qiSha: return "爆发力强、恢复慢，最忌带病硬撑；情绪上头时先离场再处理。"
        case .poJun: return "大起大落型，作息一乱就出问题；换季与赶工时额外留恢复时间。"
        default: return "状态随节奏起伏，规律作息比临时补救有效。"
        }
    }

    // MARK: - 四化提示

    private enum Line {
        case career, family, parents, health
    }

    private struct LineHint {
        let kind: TransformationKind
        let star: Star
        /// true 表示四化直接落在这条线的宫位上，false 表示在对宫冲照。
        let direct: Bool
        let place: PalaceKind
    }

    /// 优先取本宫的忌，其次本宫其他四化，再退到对宫的忌与其他四化。
    private static func lineHint(
        _ transforms: [Transformation],
        chart: Chart,
        branch: Int
    ) -> LineHint? {
        let opposite = Ganzhi.mod(branch + 6, 12)
        let mapped = transforms.compactMap { transformation -> (Transformation, Int)? in
            guard let place = chart.branch(of: transformation.star) else { return nil }
            guard place == branch || place == opposite else { return nil }
            return (transformation, place)
        }
        let direct = mapped.filter { $0.1 == branch }
        let mirrored = mapped.filter { $0.1 == opposite }
        let candidates = direct.filter { $0.0.kind == .ji }
            + direct
            + mirrored.filter { $0.0.kind == .ji }
            + mirrored
        guard let picked = candidates.first else { return nil }
        return LineHint(
            kind: picked.0.kind,
            star: picked.0.star,
            direct: picked.1 == branch,
            place: chart.palace(at: picked.1).kind
        )
    }

    private static func hintSentence(_ hint: LineHint?, line: Line) -> String {
        guard let hint else { return "" }
        let star = hint.star.rawValue
        switch (line, hint.kind, hint.direct) {
        case (.career, .ji, true): return "\n\(star)化忌就压在官禄位，事业上易有反复，重要决定留一级退路。"
        case (.career, .lu, true): return "\n\(star)化禄入官禄，这十年事业有现成资源可用，别自己去硬凿。"
        case (.career, .quan, true): return "\n\(star)化权入官禄，容易拿到主导权，也容易被推着担更多。"
        case (.career, .ke, true): return "\n\(star)化科入官禄，名声与评价会先一步到位。"
        case (.career, .ji, false): return "\n对宫\(kindName(hint.place))的\(star)化忌冲官禄，事业容易被外部牵着走，节奏留缓冲。"
        case (.career, _, false): return "\n对宫\(kindName(hint.place))的\(star)化\(hint.kind.rawValue.replacingOccurrences(of: "化", with: ""))照过来，事业上多一条可借的路。"

        case (.family, .ji, true): return "\n\(star)化忌落在夫妻位，关系上易有反复，别用沉默表态。"
        case (.family, .lu, true): return "\n\(star)化禄入夫妻，这十年关系里有现成的暖意，主动一点就接得住。"
        case (.family, .quan, true): return "\n\(star)化权入夫妻，容易争主导，商量比说服有效。"
        case (.family, .ke, true): return "\n\(star)化科入夫妻，体面与评价先到位，别只看表面。"
        case (.family, .ji, false): return "\n对宫\(kindName(hint.place))的\(star)化忌冲夫妻位，外力容易挤占相处时间。"
        case (.family, _, false): return "\n对宫\(kindName(hint.place))的\(star)化\(hint.kind.rawValue.replacingOccurrences(of: "化", with: ""))照夫妻位，关系里多一层缓冲。"

        case (.parents, .ji, true): return "\n\(star)化忌落父母位，与长辈或制度之间易有拉扯，重要的事提前沟通。"
        case (.parents, .lu, true): return "\n\(star)化禄入父母，长辈这边有现成助力，开口就行。"
        case (.parents, .quan, true): return "\n\(star)化权入父母，容易拿到长辈或制度的支持，也容易被要求担更多。"
        case (.parents, .ke, true): return "\n\(star)化科入父母，长辈的认可会先到位。"
        case (.parents, .ji, false): return "\n对宫\(kindName(hint.place))的\(star)化忌冲父母位，长辈的事要提前留出时间。"
        case (.parents, _, false): return "\n对宫\(kindName(hint.place))的\(star)化\(hint.kind.rawValue.replacingOccurrences(of: "化", with: ""))照父母位，与长辈的往来有转圜。"

        case (.health, .ji, _): return "\n\(star)化忌冲疾厄，身体是最先报警的地方，别硬扛。"
        case (.health, .lu, _): return "\n\(star)化禄照疾厄，恢复条件不差，别把好底子当成可以透支。"
        case (.health, .quan, _): return "\n\(star)化权照疾厄，容易靠体力硬撑，别把透支当能力。"
        case (.health, .ke, _): return "\n\(star)化科照疾厄，身体信号容易被及时察觉，定期检查有用。"
        }
    }

    // MARK: - 关键年份

    private static func milestones(
        chart: Chart,
        pivot: Int,
        startAge: Int,
        endAge: Int,
        birthYear: Int
    ) -> [String] {
        var lines: [String] = []
        let opposite = Ganzhi.mod(pivot + 6, 12)
        for age in startAge...endAge {
            let year = birthYear + age - 1
            let index = Ganzhi.mod(year - 4, 60)
            let stem = index % 10
            let branch = index % 12
            if branch == pivot {
                lines.append("\(year) 年（\(age) 岁）流年与大限同宫，适合重新布局")
            }
            let yearTransforms = ChartEngine.transformations(for: stem, source: .year)
            if let ji = yearTransforms.first(where: { $0.kind == .ji }),
               let place = chart.branch(of: ji.star),
               place == pivot || place == opposite {
                lines.append("\(year) 年（\(age) 岁）流年\(ji.star.rawValue)化忌冲本限，安排留缓冲")
            }
            if lines.count >= 3 { break }
        }
        return lines
    }

    private static func keyNodes(
        chart: Chart,
        stages: [LifeStage],
        currentIndex: Int,
        birthYear: Int,
        referenceDate: Date
    ) -> [KeyNode] {
        let currentYear = ChineseCalendarConverter.lunarDate(
            from: referenceDate,
            timeZone: ChineseCalendarConverter.timeZone(for: chart.input.timeZoneIdentifier)
        ).gregorianYear

        var nodes: [KeyNode] = []
        let window = stages.filter { $0.index >= currentIndex }.prefix(3)
        for stage in window {
            for age in stage.startAge...stage.endAge {
                let year = birthYear + age - 1
                guard year >= currentYear else { continue }
                let index = Ganzhi.mod(year - 4, 60)
                let stem = index % 10
                let transforms = ChartEngine.transformations(for: stem, source: .year)
                if let lu = transforms.first(where: { $0.kind == .lu }),
                   let place = chart.branch(of: lu.star),
                   place == stage.branch {
                    nodes.append(KeyNode(
                        id: "lu-\(year)",
                        age: age,
                        year: year,
                        kind: .opening,
                        scope: .near,
                        title: "流年\(lu.star.rawValue)化禄入本限",
                        detail: "「\(stage.title)」这十年里气最顺的一年，适合把要紧的事往前推：\(StarCatalog.profile(lu.star).action)。"
                    ))
                }
                if let ji = transforms.first(where: { $0.kind == .ji }),
                   let place = chart.branch(of: ji.star),
                   place == stage.branch || place == Ganzhi.mod(stage.branch + 6, 12) {
                    nodes.append(KeyNode(
                        id: "ji-\(year)",
                        age: age,
                        year: year,
                        kind: .caution,
                        scope: .near,
                        title: "流年\(ji.star.rawValue)化忌冲本限",
                        detail: "「\(stage.title)」阶段里最容易返工的一段：\(StarCatalog.profile(ji.star).caution)。"
                    ))
                }
            }
        }

        nodes.sort { $0.age < $1.age }
        var picked = Array(nodes.prefix(5))

        if let best = stages.max(by: { $0.score < $1.score }) {
            picked.append(KeyNode(
                id: "best",
                age: best.startAge,
                year: best.startYear,
                kind: .opening,
                scope: .life,
                title: "气最顺的十年 · \(best.title)",
                detail: "\(best.rangeText)（\(best.yearText)）是十二运程里条件最好的一段，适合完成需要长期积累的事：换赛道、置产、定下长期关系。"
            ))
        }
        if let hardest = stages.min(by: { $0.score < $1.score }) {
            picked.append(KeyNode(
                id: "hardest",
                age: hardest.startAge,
                year: hardest.startYear,
                kind: .caution,
                scope: .life,
                title: "最需要预备的十年 · \(hardest.title)",
                detail: "\(hardest.rangeText)（\(hardest.yearText)）条件偏紧，提前两三年把现金流、体力与退路备好，这十年就不难过。"
            ))
        }
        return picked
    }

    private static func focusText(chart: Chart, stage: LifeStage, referenceDate: Date) -> [String] {
        var focus: [String] = []
        focus.append("这十年的主线是「\(stage.title)」：\(stage.themeLine)\(stage.tone.advice)。")

        let palace = chart.palace(at: stage.branch)
        let transforms = ChartEngine.transformations(for: palace.stemIndex, source: .decade)
        if let ji = transforms.first(where: { $0.kind == .ji }), let place = chart.branch(of: ji.star) {
            let kind = chart.palace(at: place).kind
            focus.append("\(ji.star.rawValue)化忌落本命\(kindName(kind))：\(kind.focus)这一块要主动减负，别等它自己出问题才处理。")
        } else if let lu = transforms.first(where: { $0.kind == .lu }), let place = chart.branch(of: lu.star) {
            let kind = chart.palace(at: place).kind
            focus.append("\(lu.star.rawValue)化禄落本命\(kindName(kind))：\(kind.focus)这一块有现成助力，值得优先加码。")
        }

        let currentYear = ChineseCalendarConverter.lunarDate(
            from: referenceDate,
            timeZone: ChineseCalendarConverter.timeZone(for: chart.input.timeZoneIdentifier)
        ).gregorianYear
        var upcoming: [String] = []
        var cautionYear: Int?
        var settleYear: Int?
        for offset in 0..<3 {
            let year = currentYear + offset
            let index = Ganzhi.mod(year - 4, 60)
            var mark = ""
            let branch = index % 12
            if branch == Ganzhi.mod(stage.branch + 6, 12) {
                mark = "（冲本限）"
                cautionYear = year
            } else if branch == stage.branch {
                mark = "（合本限）"
                settleYear = year
            }
            upcoming.append("\(year) \(Ganzhi.stems[index % 10])\(Ganzhi.branches[branch])\(mark)")
        }
        var yearLine = "未来三年：\(upcoming.joined(separator: "、"))。"
        if let settleYear {
            yearLine += "\(settleYear) 年与本限同气，适合把事定下来；"
        }
        if let cautionYear {
            yearLine += "\(cautionYear) 年冲本限，节奏放慢，别在这年做不可逆的决定。"
        } else {
            yearLine += "这三年没有直接冲本限的年份，可按原节奏推进。"
        }
        focus.append(yearLine)
        return focus
    }

    private static func arcText(stages: [LifeStage]) -> String {
        let buckets: [(Int, Int)] = [(1, 30), (31, 50), (51, 70), (71, 200)]
        var parts: [String] = []
        for (low, high) in buckets {
            let slice = stages.filter { $0.startAge >= low && $0.startAge <= high }
            guard let first = slice.first, let last = slice.last else { continue }
            let average = slice.reduce(0) { $0 + $1.score } / slice.count
            let range = high >= 200 ? "\(first.startAge) 岁以后" : "\(first.startAge)–\(last.endAge) 岁"
            parts.append("\(range) \(average) 分")
        }
        let overall = stages.reduce(0) { $0 + $1.score } / stages.count
        let best = stages.max { $0.score < $1.score }
        let worst = stages.min { $0.score < $1.score }
        var text = "十二运程平均 \(overall) 分，四段依次是 " + parts.joined(separator: "、") + "。"
        if let best { text += "最高的一段是「\(best.title)」，最低的是「\(worst?.title ?? "")」。读完这段再看下面逐年细项，会更容易对上自己的经历。" }
        return text
    }

    // MARK: - 小工具

    private static func effectiveStars(_ chart: Chart, _ branch: Int) -> [Star] {
        let palace = chart.palace(at: branch)
        if !palace.mainStars.isEmpty { return palace.mainStars }
        return chart.palace(at: Ganzhi.mod(branch + 6, 12)).mainStars
    }

    private static func starNames(_ stars: [Star]) -> String {
        stars.isEmpty ? "空宫借星" : stars.map(\.rawValue).joined(separator: "、")
    }
}
