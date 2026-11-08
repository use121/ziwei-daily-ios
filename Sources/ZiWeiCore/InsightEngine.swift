import Foundation

/// 星曜的性格化描述：一句定性、发挥时的长处、失衡时的影子。
public struct StarVoice: Sendable {
    public let essence: String
    public let strength: String
    public let shadow: String
}

public enum StarVoices {
    public static func voice(_ star: Star) -> StarVoice {
        switch star {
        case .ziWei:
            .init(essence: "重统筹、要体面，习惯站在全局看事情",
                  strength: "能定方向、扛得住场面",
                  shadow: "容易独断，不太愿意先低头")
        case .tianJi:
            .init(essence: "反应快、善谋划，脑子常比脚步先到",
                  strength: "能拆解复杂问题、找到替代路径",
                  shadow: "思虑过多，容易迟迟不落地")
        case .taiYang:
            .init(essence: "外放、肯担当，需要被看见也愿意照拂他人",
                  strength: "敢出面、能把事情推到明面上",
                  shadow: "耗损自己，话说得太满")
        case .wuQu:
            .init(essence: "务实、认结果，对数字与成本敏感",
                  strength: "执行力强、守得住资源",
                  shadow: "过于直接，少了转圜余地")
        case .tianTong:
            .init(essence: "求和气、重感受，不喜欢硬碰硬",
                  strength: "能缓冲冲突、让周围人放松",
                  shadow: "回避难题，容易拖到最后")
        case .lianZhen:
            .init(essence: "重原则、有边界感，爱恨分明",
                  strength: "关键时刻敢担责、守得住底线",
                  shadow: "情绪化较劲，易生是非")
        case .tianFu:
            .init(essence: "稳、能存，重视积累与安全感",
                  strength: "善经营长期事务、守成有余",
                  shadow: "求稳过头，错过该动的窗口")
        case .taiYin:
            .init(essence: "细腻、内敛，对氛围与细节敏感",
                  strength: "观察入微、能沉淀出成果",
                  shadow: "内耗，话不常说透")
        case .tanLang:
            .init(essence: "好奇、多才，喜欢热闹与新鲜",
                  strength: "开拓局面、连接资源",
                  shadow: "欲望分散，事情难收尾")
        case .juMen:
            .init(essence: "善辩、重查证，习惯先怀疑再相信",
                  strength: "能把复杂的事讲清楚",
                  shadow: "言语锋利，容易生口舌")
        case .tianXiang:
            .init(essence: "重秩序、善协调，愿意做那个把流程走顺的人",
                  strength: "能平衡各方、稳住局面",
                  shadow: "顾全太多，失了自己的立场")
        case .tianLiang:
            .init(essence: "重经验、有保护欲，天然带一点长辈气",
                  strength: "能兜底、扛责任",
                  shadow: "爱说教，习惯替别人做决定")
        case .qiSha:
            .init(essence: "决断、敢冲，遇事第一反应是处理掉",
                  strength: "能破局、扛得住压力",
                  shadow: "节奏太急，容易硬碰硬")
        case .poJun:
            .init(essence: "求变、敢推翻，不喜欢维持现状",
                  strength: "能重组局面、从废墟里重建",
                  shadow: "变动过频，损耗了原有积累")
        case .wenChang:
            .init(essence: "条理、文书、考试与规范",
                  strength: "整理与表达能力好",
                  shadow: "过于拘泥形式")
        case .wenQu:
            .init(essence: "才艺、口才、临场应变",
                  strength: "表达有感染力",
                  shadow: "心思浮动，专注度不足")
        case .zuoFu, .youBi:
            .init(essence: "助力与协作，代表身边可用的人",
                  strength: "能借到力、找到同伴",
                  shadow: "依赖他人，自己不动手")
        case .tianKui, .tianYue:
            .init(essence: "贵人，多指关键时刻的提携",
                  strength: "遇事有人递台阶",
                  shadow: "把机会当成理所当然")
        case .luCun:
            .init(essence: "资源与守成，代表可支配的存量",
                  strength: "守得住、盘得清",
                  shadow: "因小失大，过于计较")
        case .qingYang, .tuoLuo:
            .init(essence: "阻力与磨合，代表必须付出的代价",
                  strength: "逼出耐性与精细度",
                  shadow: "争执、拖延与损耗")
        case .diKong, .diJie:
            .init(essence: "落空与变动，代表预期与现实的落差",
                  strength: "促使人先验证再投入",
                  shadow: "凭想象决策")
        case .tianMa:
            .init(essence: "流动与变动，代表位移带来的机会",
                  strength: "行动快、适应力强",
                  shadow: "停不下来，根基不稳")
        case .hongLuan, .tianXi:
            .init(essence: "喜庆与联结，代表关系中的暖意",
                  strength: "容易拉近距离",
                  shadow: "把短暂情绪当长期承诺")
        case .huoXing, .lingXing:
            .init(essence: "爆发力，来得急、去得也快",
                  strength: "能在短时间集中火力",
                  shadow: "急躁、容易伤人伤己")
        case .tianYao:
            .init(essence: "感受力与吸引力，重氛围与情调",
                  strength: "懂分寸、会营造气氛",
                  shadow: "情绪牵动判断")
        case .tianXing:
            .init(essence: "纪律与自我要求，讲规矩",
                  strength: "能坚持、守得住标准",
                  shadow: "对自己过于苛刻")
        case .sanTai, .baZuo:
            .init(essence: "位阶与条理，讲究次序",
                  strength: "能把事情排布清楚",
                  shadow: "重形式轻实质")
        case .enGuang, .tianGui:
            .init(essence: "礼遇与荣显，代表被认可的场合",
                  strength: "适合对外争取与展示",
                  shadow: "在意评价，容易虚耗")
        case .longChi, .fengGe:
            .init(essence: "才艺与雅致，重手感和审美",
                  strength: "细致、有品味",
                  shadow: "在细节上过度打磨")
        case .tianKu, .tianXu:
            .init(essence: "情绪的低处，代表未被说出的疲惫",
                  strength: "对情绪敏感、共情力强",
                  shadow: "自怜与空转")
        case .tianShang, .tianShi:
            .init(essence: "劳损与提醒，代表身体的信号",
                  strength: "知道自己的限度",
                  shadow: "硬扛到出问题")
        }
    }
}

/// 解读主题：核心六维 + 贵人分析 + 七宫细读，共十四维。
public enum InsightTopic: String, Codable, CaseIterable, Identifiable, Sendable {
    case overview = "命格"
    case personality = "性格"
    case love = "感情"
    case career = "事业"
    case wealth = "财运"
    case health = "健康"
    case siblings = "兄弟"
    case children = "子女"
    case travel = "迁移"
    case friends = "交友"
    case guiren = "贵人"
    case property = "田宅"
    case fortune = "福德"
    case parents = "父母"

    public var id: String { rawValue }

    /// 核心六维：默认展示，并用于雷达图。
    public static let core: [InsightTopic] = [.overview, .personality, .love, .career, .wealth, .health]

    public var isCore: Bool { Self.core.contains(self) }

    public var palace: PalaceKind {
        switch self {
        case .overview, .personality: .life
        case .love: .spouse
        case .career: .career
        case .wealth: .wealth
        case .health: .health
        case .siblings: .siblings
        case .children: .children
        case .travel: .travel
        case .friends: .friends
        case .guiren: .life
        case .property: .property
        case .fortune: .fortune
        case .parents: .parents
        }
    }

    public var symbol: String {
        switch self {
        case .overview: "circle.hexagongrid"
        case .personality: "person.crop.circle"
        case .love: "heart"
        case .career: "briefcase"
        case .wealth: "yensign.circle"
        case .health: "leaf"
        case .siblings: "person.2"
        case .children: "figure.child"
        case .travel: "airplane"
        case .friends: "person.3"
        case .guiren: "person.crop.circle.badge.checkmark"
        case .property: "house"
        case .fortune: "moon.stars"
        case .parents: "book.closed"
        }
    }

    public var subtitle: String {
        switch self {
        case .overview: "命宫格局与整体取向"
        case .personality: "命宫主星与三方性格"
        case .love: "夫妻宫与关系模式"
        case .career: "官禄宫与事业路径"
        case .wealth: "财帛宫与资源节奏"
        case .health: "疾厄宫与身心状态"
        case .siblings: "兄弟宫与同辈协作"
        case .children: "子女宫与创作成果"
        case .travel: "迁移宫与外部机会"
        case .friends: "交友宫与团队人际"
        case .guiren: "魁钺辅弼与贵人来源"
        case .property: "田宅宫与长期积累"
        case .fortune: "福德宫与精神弹性"
        case .parents: "父母宫与制度长辈"
        }
    }
}

public struct InsightBlock: Identifiable, Codable, Equatable, Sendable {
    public let heading: String
    public let body: String
    public var id: String { heading }
}

/// 解读里引用的格局摘要。
///
/// 只带「够说明结构长相」的信息：判定过程（必具 / 加分 / 破格逐条）留在命盘页，
/// 这里给主题页一段可读的引文，避免两处各说一套。
public struct PatternBrief: Identifiable, Codable, Equatable, Sendable {
    public let name: String
    public let kind: PatternKind
    public let category: PatternCategory
    public let summary: String
    /// 已触发的破格项；非空即已折力。
    public let breaking: [String]
    /// 古籍原句；现代整理出来的组合没有出处，为 nil。
    public let quote: ClassicQuote?

    public var id: String { name }

    public init(pattern: Pattern) {
        name = pattern.name
        kind = pattern.kind
        category = pattern.category
        summary = pattern.summary
        breaking = pattern.breaking
        quote = ClassicLibrary.quote(for: pattern.name)
    }

    /// 折力之后的实际档位：吉格一旦破格，按常格叙述，不改判为凶。
    public var displayedKind: PatternKind {
        breaking.isEmpty ? kind : (kind == .auspicious ? .neutral : kind)
    }

    public var isFolded: Bool { !breaking.isEmpty }
}

public struct Insight: Identifiable, Codable, Equatable, Sendable {
    public let topic: InsightTopic
    public let headline: String
    public var blocks: [InsightBlock]
    public let keyStars: [Star]
    public let palaceBranch: Int
    public let borrowsOpposite: Bool
    public let caution: String
    /// 本主题引用到的格局，供界面附上古籍原句。
    public var patterns: [PatternBrief] = []

    public var id: String { topic.rawValue }
}

extension InsightTopic {
    /// 该维度会引用哪几类格局。
    ///
    /// 格局判的是命宫三方四正的结构，所以只挂到语义相关的维度上。
    /// 感情、健康、田宅这些由本宫星曜决定的维度不硬套格局——
    /// 拿命宫格局去断六亲与身体，是常见但站不住的用法。
    public var citedPatternCategories: [PatternCategory] {
        switch self {
        case .overview: PatternCategory.allCases
        case .personality: [.structure, .dignity]
        case .career: [.wealth, .literary]
        case .wealth: [.wealth]
        case .friends: [.support]
        case .guiren: [.support, .literary]
        default: []
        }
    }

    /// 每个维度最多引用几条，避免解读变成格局清单。
    var patternQuota: Int {
        self == .overview ? 3 : 2
    }
}

/// 由命盘规则确定性生成六维解读。同一张盘、同一时间层，输出恒定。
public enum InsightEngine {
    public static func insights(for chart: Chart, layer: TimeLayer) -> [Insight] {
        let patterns = PatternEngine.patterns(for: chart, layer: layer)
        return InsightTopic.allCases.map { topic in
            var insight: Insight
            switch topic {
            case .overview: insight = overview(chart: chart, layer: layer)
            case .personality: insight = personality(chart: chart, layer: layer)
            case .love: insight = love(chart: chart, layer: layer)
            case .career: insight = career(chart: chart, layer: layer)
            case .wealth: insight = wealth(chart: chart, layer: layer)
            case .health: insight = health(chart: chart, layer: layer)
            case .guiren: insight = benefactor(chart: chart, layer: layer)
            default: insight = palaceInsight(topic: topic, chart: chart, layer: layer)
            }

            let briefs = citedBriefs(topic: topic, patterns: patterns)
            insight.patterns = briefs
            if let block = patternBlock(topic: topic, briefs: briefs) {
                insight.blocks.append(block)
            }
            if topic == .overview {
                insight.blocks.append(godBlock(chart: chart, layer: layer))
            }
            return insight
        }
    }

    // MARK: - 格局与十二神的接入

    private static func citedBriefs(topic: InsightTopic, patterns: [Pattern]) -> [PatternBrief] {
        let categories = topic.citedPatternCategories
        guard !categories.isEmpty else { return [] }
        return patterns
            .filter { categories.contains($0.category) }
            .prefix(topic.patternQuota)
            .map(PatternBrief.init(pattern:))
    }

    /// 把格局写成一段话：先点出是哪几条、属哪一类，再统一交代破格与否。
    private static func patternBlock(topic: InsightTopic, briefs: [PatternBrief]) -> InsightBlock? {
        guard !briefs.isEmpty else { return nil }

        let items = briefs
            .map { "「\($0.name)」属\($0.category.rawValue)，\($0.summary)" }
            .joined()

        let folded = briefs.filter(\.isFolded)
        let verdict: String
        if folded.isEmpty {
            verdict = briefs.contains { $0.kind == .auspicious }
                ? "这几条都未见破格，结构是站得住的。"
                : "这几条只说明结构长相，本身不分吉凶。"
        } else {
            let details = folded
                .map { "「\($0.name)」的\($0.breaking.joined(separator: "、"))已出现" }
                .joined(separator: "；")
            verdict = "\(details)，按本项目口径折为常格，力量要打折，不必按吉格去期待。"
        }

        let closing = topic == .overview
            ? "格局用来判断这张盘的结构类型，不作吉凶断定；落到具体事情上，仍要看宫位与四化。"
            : "这组结构在命宫三方四正上成立，所以放在这一维里说；它不改变本宫星曜的判断，只是补一个背景。"

        return InsightBlock(heading: "格局参照", body: items + verdict + closing)
    }

    /// 命宫上的岁前、将前十二神。只描述气象，不进入评分。
    private static func godBlock(chart: Chart, layer: TimeLayer) -> InsightBlock {
        let branch = layer.pivotBranch
        var parts: [String] = []
        if let sui = chart.suiQianGod(layer: layer, branch: branch) {
            parts.append("岁前见「\(sui.name)」，\(sui.gist)")
        }
        if let jiang = chart.jiangQianGod(layer: layer, branch: branch) {
            parts.append("将前见「\(jiang.name)」，\(jiang.gist)")
        }
        let body = parts.joined(separator: " ") + "两组神煞各按该层地支顺行布宫，这里只描述当下的气象，不参与打分。"
        return InsightBlock(heading: "十二神落宫", body: body)
    }


    // MARK: - 六维

    private static func overview(chart: Chart, layer: TimeLayer) -> Insight {
        let branch = layer.pivotBranch
        let stars = effectiveStars(chart: chart, branch: branch)
        let names = starNames(stars)
        let brightness = brightnessPhrase(stars: stars, branch: branch)
        let headline = "\(names)坐命，\(chart.bureau.bureauName)，\(primaryKeyword(stars))是这张盘的主旋律。"

        var blocks: [InsightBlock] = []
        blocks.append(.init(
            heading: "命格定性",
            body: "命宫在\(Ganzhi.branches[branch])，\(names)\(guardPhrase(stars))，\(brightness)。\(StarVoices.voice(stars.first ?? .ziWei).essence)。以\(chart.bureau.bureauName)起限，\(chart.isForwardDecade ? "大限顺行" : "大限逆行")，\(decadeHint(chart: chart, layer: layer))。"
        ))
        blocks.append(.init(heading: "主星组合", body: starParagraph(stars: stars, branch: branch)))
        blocks.append(.init(heading: "三方四正", body: triadParagraph(chart: chart, branch: branch, layer: layer)))
        blocks.append(.init(
            heading: "身宫取向",
            body: "身宫落\(chart.palace(at: chart.bodyBranch).kind.rawValue)，主管\(chart.palace(at: chart.bodyBranch).kind.focus)。身宫代表后天真正使力的地方，与命宫的先天气质常常不完全一致，这也是「想要」和「实际在做」之间落差的来源。"
        ))
        blocks.append(.init(
            heading: "优势与课题",
            body: "优势在于\(strengthSentence(stars))。需要留意的是\(shadowSentence(stars))。"
        ))
        return Insight(
            topic: .overview,
            headline: headline,
            blocks: blocks,
            keyStars: stars,
            palaceBranch: branch,
            borrowsOpposite: chart.palace(at: branch).mainStars.isEmpty,
            caution: shadowSentence(stars)
        )
    }

    private static func personality(chart: Chart, layer: TimeLayer) -> Insight {
        let branch = layer.pivotBranch
        let stars = effectiveStars(chart: chart, branch: branch)
        let headline = "做事风格由\(starNames(stars))决定：\(primaryKeyword(stars))。"

        var blocks: [InsightBlock] = []
        blocks.append(.init(heading: "命宫主星", body: starParagraph(stars: stars, branch: branch)))
        blocks.append(.init(heading: "三方性格", body: "命宫不只一颗星在说话。\(triadParagraph(chart: chart, branch: branch, layer: layer))"))
        blocks.append(.init(
            heading: "人际模式",
            body: "交友宫见\(starNames(effectiveStars(chart: chart, branch: chart.palace(.friends).branchIndex)))，\(relationHint(stars: effectiveStars(chart: chart, branch: chart.palace(.friends).branchIndex)))。迁移宫见\(starNames(effectiveStars(chart: chart, branch: chart.palace(.travel).branchIndex)))，决定了你在陌生场合的第一反应。"
        ))
        blocks.append(.init(
            heading: "成长课题",
            body: "命宫的强项往往也是它过度使用时的短板。\(shadowSentence(stars))；这一条在压力大、时间紧的时候最容易显形。"
        ))
        return Insight(
            topic: .personality,
            headline: headline,
            blocks: blocks,
            keyStars: stars,
            palaceBranch: branch,
            borrowsOpposite: chart.palace(at: branch).mainStars.isEmpty,
            caution: shadowSentence(stars)
        )
    }

    private static func love(chart: Chart, layer: TimeLayer) -> Insight {
        let palace = chart.palace(.spouse)
        let stars = effectiveStars(chart: chart, branch: palace.branchIndex)
        let headline = "夫妻宫\(starNames(stars))，感情里的核心议题是\(primaryKeyword(stars))。"

        var blocks: [InsightBlock] = []
        blocks.append(.init(
            heading: "夫妻宫",
            body: "夫妻宫在\(palace.ganzhi)，\(starNames(stars))\(guardPhrase(stars))，\(brightnessPhrase(stars: stars, branch: palace.branchIndex))。\(StarVoices.voice(stars.first ?? .tianFu).essence)。在亲密关系里，这意味着你更看重「\(primaryKeyword(stars))」这一层。"
        ))
        blocks.append(.init(heading: "三方联动", body: triadParagraph(chart: chart, branch: palace.branchIndex, layer: layer)))
        blocks.append(.init(
            heading: "相处模式",
            body: "夫妻宫的对宫是官禄，感情与事业在这张盘上是互相牵动的：工作节奏一乱，关系里的耐心通常先被消耗。\(transformationHint(chart: chart, branch: palace.branchIndex))"
        ))
        blocks.append(.init(
            heading: "实际建议",
            body: "把\(primaryKeyword(stars))这件事说出口，比让对方猜要有效。\(StarCatalog.profile(stars.first ?? .tianFu).caution)。"
        ))
        return Insight(
            topic: .love,
            headline: headline,
            blocks: blocks,
            keyStars: stars,
            palaceBranch: palace.branchIndex,
            borrowsOpposite: palace.mainStars.isEmpty,
            caution: "六亲类判断在传统紫微斗数中本就有局限，感情部分仅作参考。"
        )
    }

    private static func career(chart: Chart, layer: TimeLayer) -> Insight {
        let palace = chart.palace(.career)
        let stars = effectiveStars(chart: chart, branch: palace.branchIndex)
        let wealthStars = effectiveStars(chart: chart, branch: chart.palace(.wealth).branchIndex)
        let headline = "官禄宫\(starNames(stars))，事业上适合走「\(primaryKeyword(stars))」的路子。"

        var blocks: [InsightBlock] = []
        blocks.append(.init(
            heading: "官禄宫",
            body: "官禄宫在\(palace.ganzhi)，\(starNames(stars))\(guardPhrase(stars))，\(brightnessPhrase(stars: stars, branch: palace.branchIndex))。\(StarCatalog.profile(stars.first ?? .ziWei).action)。"
        ))
        blocks.append(.init(
            heading: "财帛联动",
            body: "财帛宫见\(starNames(wealthStars))，与官禄形成「\(primaryKeyword(stars))—\(primaryKeyword(wealthStars))」的组合。这决定了你是靠职位与责任换收入，还是靠项目与资源换收入。"
        ))
        blocks.append(.init(heading: "三方四正", body: triadParagraph(chart: chart, branch: palace.branchIndex, layer: layer)))
        blocks.append(.init(
            heading: "阶段提示",
            body: "\(layerHint(layer))在这个阶段，\(StarCatalog.profile(stars.first ?? .ziWei).caution)。"
        ))
        return Insight(
            topic: .career,
            headline: headline,
            blocks: blocks,
            keyStars: stars,
            palaceBranch: palace.branchIndex,
            borrowsOpposite: palace.mainStars.isEmpty,
            caution: StarCatalog.profile(stars.first ?? .ziWei).caution
        )
    }

    private static func wealth(chart: Chart, layer: TimeLayer) -> Insight {
        let palace = chart.palace(.wealth)
        let stars = effectiveStars(chart: chart, branch: palace.branchIndex)
        let property = chart.palace(.property)
        let propertyStars = effectiveStars(chart: chart, branch: property.branchIndex)
        let hasLuCun = chart.stars(at: palace.branchIndex).contains(.luCun)
        let headline = "财帛宫\(starNames(stars))，钱财的进出方式是\(primaryKeyword(stars))。"

        var blocks: [InsightBlock] = []
        blocks.append(.init(
            heading: "财帛宫",
            body: "财帛宫在\(palace.ganzhi)，\(starNames(stars))\(guardPhrase(stars))，\(brightnessPhrase(stars: stars, branch: palace.branchIndex))。\(StarVoices.voice(stars.first ?? .wuQu).essence)，所以你的收入结构更贴近「\(primaryKeyword(stars))」这一类。"
        ))
        blocks.append(.init(
            heading: "田宅（财库）",
            body: "田宅宫在\(property.ganzhi)，见\(starNames(propertyStars))，主管\(PalaceKind.property.focus)。财帛看进项，田宅看留得住多少，两宫合看才是一张完整的财务图。"
        ))
        blocks.append(.init(
            heading: "资源标记",
            body: hasLuCun
                ? "财帛宫坐禄存，属于「有存量」的配置，钱容易留得住，但也要小心因为太想守住而错过配置机会。"
                : "财帛宫未见禄存，进项更依赖主动经营；\(transformationHint(chart: chart, branch: palace.branchIndex))"
        ))
        blocks.append(.init(
            heading: "理财建议",
            body: "先区分「一次性收入」和「可持续收入」，再决定要不要加杠杆。\(StarCatalog.profile(stars.first ?? .wuQu).action)。"
        ))
        return Insight(
            topic: .wealth,
            headline: headline,
            blocks: blocks,
            keyStars: stars,
            palaceBranch: palace.branchIndex,
            borrowsOpposite: palace.mainStars.isEmpty,
            caution: "财运解读不构成投资建议。"
        )
    }

    private static func health(chart: Chart, layer: TimeLayer) -> Insight {
        let palace = chart.palace(.health)
        let stars = effectiveStars(chart: chart, branch: palace.branchIndex)
        let borrowed = chart.borrowedStars(at: palace.branchIndex)
        let headline = "疾厄宫\(starNames(stars))，身心的着力点在\(primaryKeyword(stars))。"

        var blocks: [InsightBlock] = []
        if let borrowed {
            blocks.append(.init(
                heading: "空宫借对宫",
                body: "疾厄宫本身没有十四主星，按传统取象借对宫\(Ganzhi.branches[borrowed.oppositeBranch])（\(chart.palace(at: borrowed.oppositeBranch).kind.rawValue)）的\(starNames(borrowed.stars))来看。借星只是权宜，仍需结合全盘，不能单宫定论。"
            ))
        } else {
            blocks.append(.init(
                heading: "疾厄宫",
                body: "疾厄宫在\(palace.ganzhi)，\(starNames(stars))\(guardPhrase(stars))，\(brightnessPhrase(stars: stars, branch: palace.branchIndex))。传统取象上，这一宫谈的是精力分配与恢复节奏，不是疾病诊断。"
            ))
        }
        blocks.append(.init(
            heading: "五行与作息",
            body: "五行局属\(chart.bureau.rawValue)，\(chart.bureau.bureauName)的人更适合有节律的作息，而不是靠爆发式补课。\(StarCatalog.profile(stars.first ?? .tianTong).action)。"
        ))
        blocks.append(.init(heading: "三方四正", body: triadParagraph(chart: chart, branch: palace.branchIndex, layer: layer)))
        blocks.append(.init(
            heading: "提醒",
            body: "\(layerHint(layer))压力大的阶段，先减安排再谈效率。身体上的具体问题请就医，命盘不能替代检查。"
        ))
        return Insight(
            topic: .health,
            headline: headline,
            blocks: blocks,
            keyStars: stars,
            palaceBranch: palace.branchIndex,
            borrowsOpposite: palace.mainStars.isEmpty,
            caution: "健康内容属传统取象，不能替代医疗诊断。"
        )
    }

    // MARK: - 贵人

    /// 贵人分析：天魁（明贵人）、天钺（暗贵人）、左辅右弼（同辈助力）、禄存（衣食之助）、恩光天贵（声誉提携）。
    /// 不按单宫看，而是看这些「贵人星」各自坐在哪一宫，判断助力从哪个领域来。
    private static func benefactor(chart: Chart, layer: TimeLayer) -> Insight {
        struct BenefactorEntry {
            let star: Star
            let role: String
            let flavor: String
            let branch: Int
            let kind: PalaceKind
        }
        let catalog: [(star: Star, role: String, flavor: String)] = [
            (.tianKui, "明贵人", "长辈、上司与公开的提携"),
            (.tianYue, "暗贵人", "私下相助、意外出现的援手"),
            (.zuoFu, "同辈助力", "身边能一起扛事的实干派"),
            (.youBi, "牵线助力", "善于引荐、搭桥、补位的人"),
            (.luCun, "衣食之助", "带来资源、供养与保障的人"),
            (.enGuang, "声誉之助", "因资历与名声而来的机会"),
            (.tianGui, "礼遇之助", "正式场合里的引荐与抬举")
        ]
        var entries: [BenefactorEntry] = []
        for item in catalog {
            guard let branch = chart.branch(of: item.star) else { continue }
            entries.append(BenefactorEntry(
                star: item.star,
                role: item.role,
                flavor: item.flavor,
                branch: branch,
                kind: chart.palaceKind(at: branch, pivot: layer.pivotBranch)
            ))
        }

        let kui = entries.first { $0.star == .tianKui }
        let yue = entries.first { $0.star == .tianYue }
        let kuiText = kui.map { "天魁坐\($0.kind.rawValue)宫" } ?? "天魁未上盘"
        let yueText = yue.map { "天钺坐\($0.kind.rawValue)宫" } ?? "天钺未上盘"
        let headline = "\(kuiText)、\(yueText)：贵人多来自\(benefactorDomain(kui?.kind ?? .life))，以及\(benefactorDomain(yue?.kind ?? .friends))。"

        var blocks: [InsightBlock] = []
        let layoutText = entries.map { "\($0.star.rawValue)（\($0.role)）坐\($0.kind.rawValue)宫（\(Ganzhi.branches[$0.branch])）" }.joined(separator: "、")
        blocks.append(.init(
            heading: "贵人格局",
            body: "本命盘贵人星共 \(entries.count) 颗：\(layoutText)。天魁主明、天钺主暗，一明一暗相互配合——明面上有人提携，暗地里也有人递梯子。魁钺若分居两宫，说明助力不止来自一个方向。"
        ))

        let grouped = Dictionary(grouping: entries, by: \.kind)
        let sourceLines = PalaceKind.allCases.compactMap { kind -> String? in
            guard let group = grouped[kind], !group.isEmpty else { return nil }
            let stars = group.map(\.star.rawValue).joined(separator: "、")
            let detail = group.map { "\($0.star.rawValue)偏\($0.flavor)" }.joined(separator: "，")
            return "· \(kind.rawValue)宫（\(stars)）：来自\(benefactorDomain(kind))；\(detail)。"
        }
        blocks.append(.init(
            heading: "贵人来源",
            body: "助力分落在 \(sourceLines.count) 个宫位：\n" + sourceLines.joined(separator: "\n")
        ))

        blocks.append(.init(
            heading: "借力方式",
            body: "魁钺的用法在「主动」：把目标和进度讲清楚，长辈与上司才知道怎么帮你；辅弼的用法在「互助」：先替别人补位，轮到自己时别客气。贵人星落宫只说明接应的方向，不开口、不露面，助力就不会自己发生。"
        ))

        // 本层四化对贵人宫位的引动
        let branchSet = Set(entries.map(\.branch))
        var lifted: [String] = []
        var blocked: [String] = []
        for transformation in layer.transformations {
            guard let branch = chart.branch(of: transformation.star), branchSet.contains(branch) else { continue }
            let kind = chart.palaceKind(at: branch, pivot: layer.pivotBranch)
            let hosts = entries.filter { $0.branch == branch }.map(\.star.rawValue).joined(separator: "、")
            switch transformation.kind {
            case .lu, .ke:
                lifted.append("\(transformation.star.rawValue)\(transformation.kind.rawValue)入\(kind.rawValue)宫，引动\(hosts)")
            case .quan:
                lifted.append("\(transformation.star.rawValue)化权入\(kind.rawValue)宫，\(hosts)所在领域权责上移")
            case .ji:
                blocked.append("\(transformation.star.rawValue)化忌入\(kind.rawValue)宫，\(hosts)受阻")
            }
        }
        let phaseLabel = layer.kind == .natal ? "生年四化" : "\(layer.kind.rawValue)四化"
        var timing = lifted.isEmpty
            ? "\(phaseLabel)没有直接点亮贵人宫位，助力以常态存在，需要多走一步主动联系。"
            : "\(phaseLabel)中，\(lifted.joined(separator: "；"))——此时开口求助、托人引荐，接应最快。"
        if !blocked.isEmpty {
            timing += "同时要留意：\(blocked.joined(separator: "；"))，托付的事容易被耽搁，重要安排留一个备选方案。"
        }
        blocks.append(.init(heading: "\(layer.kind.rawValue)引动", body: timing))

        let sha: Set<Star> = [.qingYang, .tuoLuo, .huoXing, .lingXing, .diKong, .diJie]
        let shaHits = [kui, yue].compactMap { $0 }.filter { entry in
            chart.palace(at: entry.branch).auxiliaryStars.contains { sha.contains($0) }
        }
        let caution = shaHits.isEmpty
            ? "贵人星齐全不等于事事有人帮：把需求说具体、把进度做出来，接应才会出现。"
            : "\(shaHits.map(\.star.rawValue).joined(separator: "、"))宫位同见煞星，帮助容易附带条件或迟到；接受援手前先把权责讲清。"

        return Insight(
            topic: .guiren,
            headline: headline,
            blocks: blocks,
            keyStars: entries.map(\.star),
            palaceBranch: kui?.branch ?? chart.lifeBranch,
            borrowsOpposite: false,
            caution: caution
        )
    }

    /// 贵人星的落宫对应到现实中的助力来源。
    private static func benefactorDomain(_ kind: PalaceKind) -> String {
        switch kind {
        case .life: "与自己性情相投的人"
        case .siblings: "兄弟姐妹与同辈"
        case .spouse: "伴侣及伴侣的家庭"
        case .children: "晚辈、学生与创作伙伴"
        case .wealth: "带来商机与资源的人"
        case .health: "医生、照料者与专业人士"
        case .travel: "出门在外遇到的人、外地与远方的资源"
        case .friends: "朋友、团队与下属"
        case .career: "职场中的领导、合作方与客户"
        case .property: "家族、邻里与不动产相关的人脉"
        case .fortune: "兴趣圈层、师承与精神引路人"
        case .parents: "长辈、上司与制度内的提携者"
        }
    }

    // MARK: - 单宫解读

    /// 任意宫位的四段式解读，供宫位详情页使用。
    public static func palaceInsight(for chart: Chart, layer: TimeLayer, branch: Int) -> Insight {
        let palace = chart.palace(at: branch)
        let kind = chart.palaceKind(at: branch, pivot: layer.pivotBranch)
        let stars = effectiveStars(chart: chart, branch: branch)
        let isLife = kind == .life
        let topic: InsightTopic
        switch kind {
        case .life: topic = .overview
        case .spouse: topic = .love
        case .career: topic = .career
        case .wealth: topic = .wealth
        case .health: topic = .health
        default: topic = .overview
        }

        let headline = "\(kind.rawValue)在\(Ganzhi.branches[branch])，\(starNames(stars))\(guardPhrase(stars))，主题是\(kind.focus)。"
        var blocks: [InsightBlock] = []

        if isLife {
            blocks.append(.init(
                heading: "宫位定性",
                body: "这是\(layer.kind.rawValue)层的命宫。\(StarVoices.voice(stars.first ?? .ziWei).essence)。\(kind.focus)是这一宫的核心议题。"
            ))
        } else {
            blocks.append(.init(
                heading: "宫位定性",
                body: "\(kind.rawValue)主管\(kind.focus)。在\(layer.kind.rawValue)层，它落在\(Ganzhi.branches[branch])，\(starNames(stars))\(guardPhrase(stars))，\(brightnessPhrase(stars: stars, branch: branch))。"
            ))
        }

        blocks.append(.init(heading: "主星解读", body: starParagraph(stars: stars, branch: branch)))
        blocks.append(.init(heading: "三方四正联动", body: triadParagraph(chart: chart, branch: branch, layer: layer)))

        let transformationText = transformationHint(chart: chart, branch: branch)
        blocks.append(.init(
            heading: "四化与实际建议",
            body: (transformationText.isEmpty ? "" : transformationText + " ") + StarCatalog.profile(stars.first ?? .ziWei).action + "。" + StarCatalog.profile(stars.first ?? .ziWei).caution + "。"
        ))

        return Insight(
            topic: topic,
            headline: headline,
            blocks: blocks,
            keyStars: stars,
            palaceBranch: branch,
            borrowsOpposite: palace.mainStars.isEmpty,
            caution: StarCatalog.profile(stars.first ?? .ziWei).caution
        )
    }

    // MARK: - 文本零件

    // MARK: - 七宫细读

    /// 兄弟、子女、迁移、交友、田宅、福德、父母七宫的通用解读。
    /// 与核心六维共用同一套措辞零件，保证同一张盘的风格一致。
    private static func palaceInsight(topic: InsightTopic, chart: Chart, layer: TimeLayer) -> Insight {
        let kind = topic.palace
        let branch = branchOf(kind, layer: layer)
        let palace = chart.palace(at: branch)
        let stars = effectiveStars(chart: chart, branch: branch)
        let names = starNames(stars)
        let brightness = brightnessPhrase(stars: stars, branch: branch)
        let borrowed = palace.mainStars.isEmpty
        let headline = "\(kind.rawValue)在\(Ganzhi.branches[branch])，\(names)\(guardPhrase(stars))，主题是\(kind.focus)。"

        var blocks: [InsightBlock] = []
        blocks.append(.init(
            heading: "\(kind.rawValue)定性",
            body: "在「\(kind.rawValue)」这一宫，看的是\(kind.focus)。本层它落在\(Ganzhi.branches[branch])宫，宫干\(Ganzhi.stems[palace.stemIndex])，\(names)\(guardPhrase(stars))，\(brightness)。\(barely(borrowed: borrowed))"
        ))
        blocks.append(.init(heading: "主星解析", body: starParagraph(stars: stars, branch: branch)))
        blocks.append(.init(heading: "三方四正", body: triadParagraph(chart: chart, branch: branch, layer: layer)))
        blocks.append(.init(
            heading: "四化与本层提醒",
            body: "\(transformationHint(chart: chart, branch: branch))\(layerHint(layer))"
        ))
        if let first = stars.first {
            let profile = StarCatalog.profile(first)
            blocks.append(.init(
                heading: "行动建议",
                body: "围绕\(kind.focus)，可以这样用：\(profile.action)。\(profile.caution)。"
            ))
        }

        return Insight(
            topic: topic,
            headline: headline,
            blocks: blocks,
            keyStars: stars,
            palaceBranch: branch,
            borrowsOpposite: borrowed,
            caution: shadowSentence(stars)
        )
    }

    private static func branchOf(_ kind: PalaceKind, layer: TimeLayer) -> Int {
        let index = PalaceKind.allCases.firstIndex(of: kind) ?? 0
        return Ganzhi.mod(layer.pivotBranch - index, 12)
    }

    private static func barely(borrowed: Bool) -> String {
        borrowed ? "本宫无主星，需借对宫星曜一并看。" : ""
    }

    private static func effectiveStars(chart: Chart, branch: Int) -> [Star] {
        let palace = chart.palace(at: branch)
        if !palace.mainStars.isEmpty { return palace.mainStars }
        return chart.palace(at: Ganzhi.mod(branch + 6, 12)).mainStars
    }

    private static func starNames(_ stars: [Star]) -> String {
        stars.isEmpty ? "空宫" : stars.map(\.rawValue).joined(separator: "、")
    }

    private static func primaryKeyword(_ stars: [Star]) -> String {
        stars.first.map { StarCatalog.profile($0).keyword } ?? "弹性与等待"
    }

    private static func brightnessPhrase(stars: [Star], branch: Int) -> String {
        let items = stars.compactMap { star -> String? in
            guard let value = BrightnessCatalog.brightness(of: star, at: branch) else { return nil }
            return "\(star.rawValue)（\(value.label)）"
        }
        guard !items.isEmpty else { return "亮度按《斗数全书》口径未标注" }
        return items.joined(separator: "、")
    }

    private static func starParagraph(stars: [Star], branch: Int) -> String {
        guard !stars.isEmpty else { return "本宫无十四主星，需借对宫之星观察，力量偏间接。" }
        return stars.map { star in
            let voice = StarVoices.voice(star)
            let brightness = BrightnessCatalog.brightness(of: star, at: branch)
            let tail = brightness.map { "亮度为\($0.label)，\($0.phrase)。" } ?? ""
            return "\(star.rawValue)：\(voice.essence)。\(tail)发挥得好时\(voice.strength)；失衡时\(voice.shadow)。"
        }.joined(separator: "\n")
    }

    private static func triadParagraph(chart: Chart, branch: Int, layer: TimeLayer) -> String {
        let branches = chart.triad(of: branch)
        let parts = branches.enumerated().compactMap { offset, item -> String? in
            let kind = offset == 0 ? "本宫" : offset == 3 ? "对宫" : "三合"
            let palace = chart.palace(at: item)
            let stars = effectiveStars(chart: chart, branch: item)
            return "\(kind)\(Ganzhi.branches[item])（\(palace.kind.rawValue)）见\(starNames(stars))"
        }
        return parts.joined(separator: "，") + "。" + transformationHint(chart: chart, branch: branch)
    }

    private static func transformationHint(chart: Chart, branch: Int) -> String {
        let hits = chart.palace(at: branch).transformations
        guard !hits.isEmpty else { return "" }
        let text = hits.map { "\($0.star.rawValue)\($0.kind.rawValue)" }.joined(separator: "、")
        let ji = hits.contains { $0.kind == .ji }
        return "本宫带\(text)，\(ji ? "其中化忌是需要多留一分耐心的地方。" : "整体偏向加分项。")"
    }

    private static func strengthSentence(_ stars: [Star]) -> String {
        guard let first = stars.first else { return "弹性与适应力" }
        return stars.count > 1
            ? "\(StarVoices.voice(first).strength)，再加上\(stars[1].rawValue)的\(StarCatalog.profile(stars[1]).keyword)"
            : StarVoices.voice(first).strength
    }

    private static func shadowSentence(_ stars: [Star]) -> String {
        guard let first = stars.first else { return "缺少主星时容易跟着环境走，方向感要靠外部锚点" }
        return StarVoices.voice(first).shadow
    }

    private static func relationHint(stars: [Star]) -> String {
        guard let first = stars.first else { return "人际上更依赖具体场合，而不是固定圈子" }
        return "相处时\(StarVoices.voice(first).shadow)"
    }

    private static func decadeHint(chart: Chart, layer: TimeLayer) -> String {
        if let decade = layer.decade {
            return "当前行至 \(decade.rangeText) 的\(Ganzhi.branches[decade.branch])宫大限"
        }
        let age = chart.nominalAge()
        let slot = chart.decades()[chart.currentDecadeIndex(age: age)]
        return "当前虚岁 \(age)，行至 \(slot.rangeText) 的\(Ganzhi.branches[slot.branch])宫大限"
    }

    private static func guardPhrase(_ stars: [Star]) -> String {
        stars.count > 1 ? "同守" : "坐守"
    }

    private static func layerHint(_ layer: TimeLayer) -> String {
        switch layer.kind {
        case .natal:
            return "本命层看的是长期结构。"
        case .decade:
            return "大限层看的是这十年的主基调。"
        case .year:
            return "流年层看的是当年被引动的部分。"
        case .month:
            return "流月层看的是这个月具体落在哪件事上。"
        case .day:
            return "流日层看的是当天的节奏与具体事项。"
        case .hour:
            return "流时层只看这两个小时的即时气口，不宜外推整天。"
        }
    }
}
