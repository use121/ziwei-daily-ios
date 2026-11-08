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
        }
    }
}

/// 解读主题：普通版六维。
public enum InsightTopic: String, Codable, CaseIterable, Identifiable, Sendable {
    case overview = "命格"
    case personality = "性格"
    case love = "感情"
    case career = "事业"
    case wealth = "财运"
    case health = "健康"

    public var id: String { rawValue }

    public var palace: PalaceKind {
        switch self {
        case .overview, .personality: .life
        case .love: .spouse
        case .career: .career
        case .wealth: .wealth
        case .health: .health
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
        }
    }
}

public struct InsightBlock: Identifiable, Codable, Equatable, Sendable {
    public let heading: String
    public let body: String
    public var id: String { heading }
}

public struct Insight: Identifiable, Codable, Equatable, Sendable {
    public let topic: InsightTopic
    public let headline: String
    public let blocks: [InsightBlock]
    public let keyStars: [Star]
    public let palaceBranch: Int
    public let borrowsOpposite: Bool
    public let caution: String

    public var id: String { topic.rawValue }
}

/// 由命盘规则确定性生成六维解读。同一张盘、同一时间层，输出恒定。
public enum InsightEngine {
    public static func insights(for chart: Chart, layer: TimeLayer) -> [Insight] {
        InsightTopic.allCases.map { topic in
            switch topic {
            case .overview: overview(chart: chart, layer: layer)
            case .personality: personality(chart: chart, layer: layer)
            case .love: love(chart: chart, layer: layer)
            case .career: career(chart: chart, layer: layer)
            case .wealth: wealth(chart: chart, layer: layer)
            case .health: health(chart: chart, layer: layer)
            }
        }
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
        }
    }
}
