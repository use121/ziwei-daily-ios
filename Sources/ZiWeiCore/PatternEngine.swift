import Foundation

public enum PatternKind: String, Codable, Sendable {
    case auspicious = "吉格"
    case neutral = "常格"
    case caution = "留意"

    public var symbol: String {
        switch self {
        case .auspicious: "sparkles"
        case .neutral: "circle.dashed"
        case .caution: "exclamationmark.triangle"
        }
    }

    /// 排序权重：先看吉格，再看常格，最后看留意。
    var rank: Int {
        switch self {
        case .auspicious: 0
        case .neutral: 1
        case .caution: 2
        }
    }
}

/// 格局分类。用于界面上分组，也便于按主题查。
public enum PatternCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    /// 主星得位、气局尊贵。
    case dignity = "尊格"
    /// 财禄与事业的组合。
    case wealth = "财官"
    /// 昌曲魁钺一类的文名与贵人。
    case literary = "文名"
    /// 夹拱、同会形成的助力。
    case support = "助力"
    /// 煞忌相侵，重点在提醒。
    case pressure = "煞忌"
    /// 宫位与四化的结构性特征。
    case structure = "结构"

    public var id: String { rawValue }

    public var note: String {
        switch self {
        case .dignity: "主星落位得地，气局偏尊"
        case .wealth: "财禄、事业与行动力相关"
        case .literary: "文书、名声与贵人相关"
        case .support: "靠夹拱与同会形成的助力"
        case .pressure: "煞星与化忌的组合，重在提醒"
        case .structure: "宫位与四化的结构特征"
        }
    }

    var rank: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

/// 经典格局：由当前时间层的命宫三方四正与四化组合判定。
public struct Pattern: Identifiable, Codable, Equatable, Sendable {
    public let name: String
    public let kind: PatternKind
    public let category: PatternCategory
    public let branches: [Int]
    public let summary: String
    public let detail: String
    /// 成立所必须满足的条件，逐条列出。
    public let required: [String]
    /// 已触发的加分项。
    public let bonus: [String]
    /// 已触发的破格项，出现即折力。
    public let breaking: [String]
    /// 古籍出处；现代整理出来的组合留空。
    public let source: String

    public var id: String { name }

    public init(
        name: String,
        kind: PatternKind,
        category: PatternCategory,
        branches: [Int],
        summary: String,
        detail: String,
        required: [String] = [],
        bonus: [String] = [],
        breaking: [String] = [],
        source: String = ""
    ) {
        self.name = name
        self.kind = kind
        self.category = category
        self.branches = branches
        self.summary = summary
        self.detail = detail
        self.required = required
        self.bonus = bonus
        self.breaking = breaking
        self.source = source
    }

    public var branchText: String {
        branches.map { Ganzhi.branches[Ganzhi.mod($0, 12)] }.joined(separator: "、")
    }

    /// 破格项出现时降一档，但不改成「凶」。
    var hasBreaking: Bool { !breaking.isEmpty }
}

/// 格局判定。规则全部基于星曜落宫与四化，不引入随机与外部数据。
///
/// 判定口径：
/// - 「三方四正」指当前时间层的命宫、财帛、官禄、迁移四宫（按层命宫整体旋转）。
/// - 「夹」指命宫前后两宫。
/// - 庙旺利陷取 BrightnessCatalog 的七档表，庙旺得算得力，不陷算受制。
/// - 每条格局分「必具 / 加分 / 破格」三层，破格触发时降档说明，不直接判凶。
public enum PatternEngine {

    public static func patterns(for chart: Chart, layer: TimeLayer) -> [Pattern] {
        let scene = Scene(chart: chart, layer: layer)
        var result: [Pattern] = []
        result += dignityPatterns(scene)
        result += wealthPatterns(scene)
        result += literaryPatterns(scene)
        result += supportPatterns(scene)
        result += pressurePatterns(scene)
        result += structurePatterns(scene)
        return result.sorted {
            if $0.kind.rank != $1.kind.rank { return $0.kind.rank < $1.kind.rank }
            if $0.category.rank != $1.category.rank { return $0.category.rank < $1.category.rank }
            return $0.name < $1.name
        }
    }

    /// 命宫所在宫位（当前层）。
    public static func lifePalace(_ chart: Chart, layer: TimeLayer) -> Palace {
        chart.palace(at: layer.pivotBranch)
    }
}

// MARK: - 判定上下文

private struct Scene {
    let chart: Chart
    let layer: TimeLayer
    let pivot: Int
    let trine: [Int]
    let lifeStars: Set<Star>
    let trineStars: Set<Star>
    let transformations: [Transformation]

    init(chart: Chart, layer: TimeLayer) {
        self.chart = chart
        self.layer = layer
        self.pivot = Ganzhi.mod(layer.pivotBranch, 12)
        self.trine = chart.triad(of: layer.pivotBranch)
        self.lifeStars = Set(chart.stars(at: layer.pivotBranch))
        self.trineStars = Set(chart.triad(of: layer.pivotBranch).flatMap { chart.stars(at: $0) })
        self.transformations = layer.transformations
    }

    func branch(of star: Star) -> Int? { chart.branch(of: star) }

    /// 星是否落在三方四正。
    func has(_ star: Star) -> Bool { trineStars.contains(star) }

    func inTrine(_ branch: Int?) -> Bool {
        guard let branch else { return false }
        return trine.contains(Ganzhi.mod(branch, 12))
    }

    func stars(at branch: Int) -> [Star] { chart.stars(at: branch) }

    var prevBranch: Int { Ganzhi.mod(pivot - 1, 12) }
    var nextBranch: Int { Ganzhi.mod(pivot + 1, 12) }

    /// 命宫某一类宫位的地支。
    func branch(of kind: PalaceKind) -> Int {
        let offset = PalaceKind.allCases.firstIndex(of: kind) ?? 0
        return Ganzhi.mod(pivot - offset, 12)
    }

    /// 是否有某一类四化落在三方四正。
    func hasTransformation(_ kind: TransformationKind) -> Bool {
        transformations.contains { $0.kind == kind && inTrine(branch(of: $0.star)) }
    }

    /// 三方四正内的化忌星。
    func jiStar() -> Star? {
        transformations.first { $0.kind == .ji && inTrine(branch(of: $0.star)) }?.star
    }

    /// 三方四正内某一颗星的四化类型。
    func transformation(of star: Star) -> TransformationKind? {
        transformations.first { $0.star == star }?.kind
    }

    /// 指定煞星在三方四正出现的次数。
    func shaCount(_ list: [Star]) -> Int {
        trine.reduce(0) { total, branch in
            total + chart.stars(at: branch).filter { list.contains($0) }.count
        }
    }

    func brightness(_ star: Star) -> Brightness? {
        guard let branch = branch(of: star) else { return nil }
        return BrightnessCatalog.brightness(of: star, at: branch)
    }

    func isBright(_ star: Star) -> Bool { brightness(star)?.isStrong == true }
    func isDim(_ star: Star) -> Bool { brightness(star)?.isWeak == true }

    /// 若干星在三方四正内的落宫（去重、按地支升序）。
    func branches(of stars: [Star]) -> [Int] {
        Array(Set(stars.compactMap { branch(of: $0) }.filter { inTrine($0) })).sorted()
    }

    var lifeHasMainStar: Bool { !chart.palace(at: pivot).mainStars.isEmpty }

    func lifeHas(_ star: Star) -> Bool { lifeStars.contains(star) }

    /// 命宫两侧是否分别坐有这两颗星（顺序不限）。
    func flanked(by first: Star, and second: Star) -> Bool {
        let prev = Set(stars(at: prevBranch))
        let next = Set(stars(at: nextBranch))
        return (prev.contains(first) && next.contains(second)) || (prev.contains(second) && next.contains(first))
    }
}

private let fourSha: [Star] = [.qingYang, .tuoLuo, .huoXing, .lingXing]
private let twoSha: [Star] = [.diKong, .diJie]

// MARK: - 尊格

private extension PatternEngine {

    static func dignityPatterns(_ s: Scene) -> [Pattern] {
        var out: [Pattern] = []

        // 紫府同宫
        if let zi = s.branch(of: .ziWei), let fu = s.branch(of: .tianFu), zi == fu, s.inTrine(zi) {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.has(.zuoFu) && s.has(.youBi) { bonus.append("左辅右弼同会") }
            if s.has(.wenChang) || s.has(.wenQu) { bonus.append("再会昌曲") }
            if s.trine.contains(zi), s.stars(at: zi).contains(where: { twoSha.contains($0) }) {
                breaking.append("同宫坐空劫，折紫府之贵")
            }
            out.append(Pattern(
                name: "紫府同宫",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .dignity,
                branches: [zi],
                summary: "紫微天府同落一宫，主稳重与统筹兼具。",
                detail: "紫微主决断，天府主积累，两者同宫时既想掌舵也重守成。适合承担需要长期经营的角色，但要留意过于求稳而错过窗口。\(breaking.isEmpty ? "再得辅弼昌曲相会，格局更完整。" : "本盘同宫见空劫，贵气打折，靠具体成果说话更实在。")",
                required: ["紫微与天府同宫", "该宫在命宫三方四正"],
                bonus: bonus,
                breaking: breaking,
                source: "《骨髓赋》"
            ))
        }

        // 紫府朝垣：紫微、天府分守三方
        if let zi = s.branch(of: .ziWei), let fu = s.branch(of: .tianFu),
           zi != fu, s.inTrine(zi), s.inTrine(fu) {
            out.append(Pattern(
                name: "紫府朝垣",
                kind: .auspicious,
                category: .dignity,
                branches: [zi, fu],
                summary: "紫微天府分守三方，尊贵之气拱命。",
                detail: "两帝星分处三方，形成一主决断、一主积累的配合。做事容易两头都有依托：上面有人定调，下面有人守成。课题是把两套节奏接上，别让决策与执行脱节。",
                required: ["紫微与天府分处两宫", "两宫同在三方四正"],
                source: "《骨髓赋》"
            ))
        }

        // 极向离明：紫微坐午
        if s.lifeHas(.ziWei), s.pivot == 6 {
            var bonus: [String] = []
            if s.has(.zuoFu) || s.has(.youBi) { bonus.append("得辅弼相助") }
            if s.has(.wenChang) || s.has(.wenQu) { bonus.append("会昌曲") }
            out.append(Pattern(
                name: "极向离明",
                kind: .auspicious,
                category: .dignity,
                branches: [6],
                summary: "紫微坐午，如帝星当空，气局最正。",
                detail: "午为离位，紫微在此为得地之尊。通常表现为目标感强、愿意担责、在群体里自然被推到台前。要留意的是「位置越高越要有人帮」，别把独立做成孤军。",
                required: ["紫微坐命于午宫"],
                bonus: bonus,
                source: "《骨髓赋》"
            ))
        }

        // 紫微入命（独坐，无天府同宫）
        if s.lifeHas(.ziWei), !s.lifeHas(.tianFu) {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.has(.zuoFu) && s.has(.youBi) { bonus.append("左右同会") }
            if s.has(.tianKui) || s.has(.tianYue) { bonus.append("魁钺加照") }
            if !s.has(.zuoFu) && !s.has(.youBi) { breaking.append("无辅弼相会，古称「在野孤君」") }
            if s.lifeStars.contains(where: { twoSha.contains($0) }) { breaking.append("命宫坐空劫") }
            out.append(Pattern(
                name: "紫微入命",
                kind: breaking.isEmpty ? (bonus.isEmpty ? .neutral : .auspicious) : .neutral,
                category: .dignity,
                branches: [s.pivot],
                summary: "紫微独坐命宫，主自尊与主导欲强。",
                detail: "紫微独坐的人多半在意「这件事该由谁定」，格局的高低常取决于身边有没有可用的人。得辅弼魁钺，是能拢人的领袖；无辅弼则容易变成一个人扛，学会分工比加倍努力更有效。",
                required: ["紫微坐命", "天府不同宫"],
                bonus: bonus,
                breaking: breaking,
                source: "《紫微斗数全书》"
            ))
        }

        // 天府临戌
        if s.lifeHas(.tianFu), s.pivot == 10 {
            out.append(Pattern(
                name: "天府临戌",
                kind: .auspicious,
                category: .dignity,
                branches: [10],
                summary: "天府坐戌，库藏得位，主稳厚能守。",
                detail: "戌为火库，天府在此善于把资源收拢成形。表现是耐得住、守得稳、对长期资产有感觉；课题是不轻易冒险，遇到需要快速转身的场合要提前准备。",
                required: ["天府坐命于戌宫"],
                source: "《骨髓赋》"
            ))
        }

        // 君臣庆会
        if s.has(.ziWei), (s.has(.zuoFu) || s.has(.youBi)), (s.has(.tianKui) || s.has(.tianYue)) {
            var bonus: [String] = []
            let breaking: [String] = []
            if s.has(.zuoFu) && s.has(.youBi) { bonus.append("辅弼双会") }
            if s.has(.wenChang) || s.has(.wenQu) { bonus.append("昌曲同会") }
            if s.transformation(of: .ziWei) == .quan { bonus.append("紫微化权") }
            out.append(Pattern(
                name: "君臣庆会",
                kind: .auspicious,
                category: .dignity,
                branches: s.branches(of: [.ziWei, .zuoFu, .youBi, .tianKui, .tianYue]),
                summary: "紫微得辅弼魁钺相会，主有助力、易得提携。",
                detail: "紫微为君，辅弼魁钺为臣。三方四正会齐，代表关键时刻容易遇到愿意帮忙的人，也意味着要主动把资源整合起来，别独自硬扛。",
                required: ["紫微在三方四正", "左辅或右弼相会", "天魁或天钺相会"],
                bonus: bonus,
                breaking: breaking,
                source: "《太微赋》"
            ))
        }

        // 府相朝垣
        if let fu = s.branch(of: .tianFu), let xiang = s.branch(of: .tianXiang),
           fu != xiang, s.inTrine(fu), s.inTrine(xiang) {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.has(.luCun) || s.hasTransformation(.lu) { bonus.append("三方见禄") }
            if s.has(.zuoFu) { bonus.append("再会左辅") }
            if s.shaCount(fourSha) >= 2 { breaking.append("三方煞星偏多") }
            out.append(Pattern(
                name: "府相朝垣",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .dignity,
                branches: [fu, xiang],
                summary: "天府天相会照，主有靠、事务易成。",
                detail: "府相为「衣食之星」，会照命宫三方时，做事容易得到制度或上位者的支持。适合在有规则的场域里积累，忌讳反复变卦。",
                required: ["天府与天相分处两宫", "两宫同在三方四正"],
                bonus: bonus,
                breaking: breaking,
                source: "《骨髓赋》"
            ))
        }

        // 月朗天门
        if s.lifeHas(.taiYin), s.pivot == 11 {
            out.append(Pattern(
                name: "月朗天门",
                kind: .auspicious,
                category: .dignity,
                branches: [11],
                summary: "太阴坐亥，主清明细腻、后劲绵长。",
                detail: "亥为天门，太阴在此得地。思维细、感受准，适合需要长期沉淀的领域；情绪起伏时容易内耗，需要固定的恢复方式。",
                required: ["太阴坐命于亥宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 日照雷门
        if s.lifeHas(.taiYang), s.pivot == 3 {
            out.append(Pattern(
                name: "日照雷门",
                kind: .auspicious,
                category: .dignity,
                branches: [3],
                summary: "太阳坐卯，主光明外显、行动力强。",
                detail: "卯为雷门，太阳东升。表达与担当是优势，容易被看见也容易被期待绑住；学会分批释放精力，比一次燃尽更长久。",
                required: ["太阳坐命于卯宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 石中隐玉
        if s.lifeHas(.juMen), s.pivot == 0 || s.pivot == 6 {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.transformation(of: .juMen) == .lu || s.transformation(of: .juMen) == .quan {
                bonus.append("巨门化禄或化权")
            }
            if s.has(.wenChang) { bonus.append("文昌会照") }
            if s.transformation(of: .juMen) == .ji { breaking.append("巨门化忌，玉藏深泥") }
            if s.lifeStars.contains(where: { fourSha.contains($0) }) { breaking.append("命宫坐四煞") }
            out.append(Pattern(
                name: "石中隐玉",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .dignity,
                branches: [s.pivot],
                summary: "巨门坐子午，主口才与钻研，需时间显价值。",
                detail: "巨门在子午为得地，锋芒内藏。适合研究、教学、谈判这类靠表达与辨析取胜的事。早期容易被误解，越往后越吃香。",
                required: ["巨门坐命于子或午宫"],
                bonus: bonus,
                breaking: breaking,
                source: "《骨髓赋》"
            ))
        }

        // 七杀朝斗
        if s.lifeHas(.qiSha), s.pivot == 2 || s.pivot == 8 {
            out.append(Pattern(
                name: "七杀朝斗",
                kind: .auspicious,
                category: .dignity,
                branches: [s.pivot],
                summary: "七杀坐寅申，主魄力与开拓。",
                detail: "七杀朝斗是能扛事的结构，适合从零到一的场景。注意节奏：推进要快，收尾要稳，别把「敢冲」当成唯一手段。",
                required: ["七杀坐命于寅或申宫"],
                source: "《骨髓赋》"
            ))
        }

        // 雄宿朝垣
        if s.lifeHas(.tanLang), [2, 6, 10].contains(s.pivot) {
            out.append(Pattern(
                name: "雄宿朝垣",
                kind: .auspicious,
                category: .dignity,
                branches: [s.pivot],
                summary: "贪狼坐寅午戌，主活力与资源整合。",
                detail: "贪狼得火局之地，社交与机会感强。擅长把人和事串起来，课题是取舍——机会太多时，选择比努力更关键。",
                required: ["贪狼坐命于寅、午或戌宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 日月同宫
        if let sun = s.branch(of: .taiYang), let moon = s.branch(of: .taiYin),
           sun == moon, s.inTrine(sun), sun == 1 || sun == 7 {
            var bonus: [String] = []
            if sun == 7 { bonus.append("未宫日月同辉，力量较足") }
            if s.has(.wenChang) && s.has(.wenQu) { bonus.append("昌曲会照") }
            out.append(Pattern(
                name: "日月同宫",
                kind: .auspicious,
                category: .dignity,
                branches: [sun],
                summary: "太阳太阴同宫于丑未，主刚柔并存。",
                detail: "日月同宫的人常在两种性格间切换：一面要出头，一面要退守。好处是视角完整，难处是自我对话多。把两面的需要都排进日程，比强行选一边更顺。",
                required: ["太阳太阴同宫", "落于丑宫或未宫"],
                bonus: bonus,
                source: "《紫微斗数全书》"
            ))
        }

        // 日月夹命
        if s.flanked(by: .taiYang, and: .taiYin) {
            var breaking: [String] = []
            if s.isDim(.taiYang) || s.isDim(.taiYin) { breaking.append("日月落陷，夹而无光") }
            out.append(Pattern(
                name: "日月夹命",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .dignity,
                branches: [s.prevBranch, s.pivot, s.nextBranch],
                summary: "日月分居命宫两侧，主环境照拂。",
                detail: "前后两宫得日月相夹，常见于成长环境给过明确支持的人。优势是资源与视野来得早，课题是别把这份照拂当成理所当然，要自己接得住。",
                required: ["太阳与太阴分居命宫前后两宫"],
                breaking: breaking,
                source: "《紫微斗数全书》"
            ))
        }

        // 巨日同宫
        if let ju = s.branch(of: .juMen), let sun = s.branch(of: .taiYang),
           ju == sun, s.inTrine(ju), ju == 2 || ju == 8 {
            var bonus: [String] = []
            var breaking: [String] = []
            if ju == 2 { bonus.append("寅宫太阳得位，可化巨门之暗") }
            if s.transformation(of: .juMen) == .lu || s.transformation(of: .juMen) == .quan {
                bonus.append("巨门化禄或化权，口才生财")
            }
            if s.transformation(of: .juMen) == .ji { breaking.append("巨门化忌，易生口舌") }
            if ju == 8 { breaking.append("申宫太阳偏西，光弱一些") }
            out.append(Pattern(
                name: "巨日同宫",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .dignity,
                branches: [ju],
                summary: "巨门太阳同宫于寅申，以口才与专业立业。",
                detail: "太阳化解巨门的暗曜，表现是以说话、写作、外语、专业解释取胜。寅宫光足，越讲越清楚；申宫光弱，容易话没说透就被误解，宜多留文字。",
                required: ["巨门与太阳同宫", "落于寅宫或申宫"],
                bonus: bonus,
                breaking: breaking,
                source: "《紫微斗数全书》"
            ))
        }

        // 明珠出海
        if s.pivot == 7, !s.lifeHasMainStar {
            let opposite = Ganzhi.mod(7 + 6, 12)
            let oppositeStars = Set(s.stars(at: opposite))
            if oppositeStars.contains(.taiYang), oppositeStars.contains(.taiYin) {
                var breaking: [String] = []
                if s.shaCount(fourSha) >= 2 { breaking.append("三方煞星会照，珠光打折") }
                out.append(Pattern(
                    name: "明珠出海",
                    kind: breaking.isEmpty ? .auspicious : .neutral,
                    category: .dignity,
                    branches: [7, opposite],
                    summary: "命宫在未无正曜，对宫日月拱照。",
                    detail: "空宫借光，通常代表早期不显、靠后天环境与自身积累出头。适合离家、跨区域或进入大平台发展，越往外走越容易被看见。",
                    required: ["命宫在未且无主星", "对宫丑宫太阳太阴同度"],
                    breaking: breaking,
                    source: "《紫微斗数全书》"
                ))
            }
        }

        // 廉贞天相
        if let lian = s.branch(of: .lianZhen), let xiang = s.branch(of: .tianXiang),
           lian == xiang, s.inTrine(lian) {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.has(.luCun) || s.transformation(of: .lianZhen) == .lu { bonus.append("见禄") }
            if s.transformation(of: .lianZhen) == .ji { breaking.append("廉贞化忌，易起争执") }
            if s.stars(at: lian).contains(.qingYang) { breaking.append("同宫坐擎羊") }
            out.append(Pattern(
                name: "廉贞天相",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .dignity,
                branches: [lian],
                summary: "廉贞天相同宫，主守规矩、办事有条理。",
                detail: "廉贞主原则，天相主印信，两者同宫适合做需要公信力的事：法务、行政、审核、项目管理。怕的是原则变成较劲，遇分歧先对齐标准再谈对错。",
                required: ["廉贞与天相同宫", "该宫在三方四正"],
                bonus: bonus,
                breaking: breaking,
                source: "《紫微斗数全书》"
            ))
        }

        // 武曲七杀
        if let wu = s.branch(of: .wuQu), let qi = s.branch(of: .qiSha),
           wu == qi, s.inTrine(wu) {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.transformation(of: .wuQu) == .quan { bonus.append("武曲化权") }
            if s.transformation(of: .wuQu) == .lu { bonus.append("武曲化禄") }
            if s.transformation(of: .wuQu) == .ji { breaking.append("武曲化忌，财务上宜保守") }
            if s.shaCount(fourSha) >= 2 { breaking.append("三方煞重") }
            out.append(Pattern(
                name: "武曲七杀",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .dignity,
                branches: [wu],
                summary: "武曲七杀同宫，果决务实，执行力强。",
                detail: "财星配将星，做事偏向「先动手再修正」。适合目标明确、需要扛指标的场景；风险在于快而不细，重要决定建议留一次复核。",
                required: ["武曲与七杀同宫", "该宫在三方四正"],
                bonus: bonus,
                breaking: breaking,
                source: "《紫微斗数全书》"
            ))
        }

        // 天同天梁
        if let tong = s.branch(of: .tianTong), let liang = s.branch(of: .tianLiang),
           tong == liang, s.inTrine(tong) {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.has(.wenChang) { bonus.append("文昌会照") }
            if s.transformation(of: .tianTong) == .lu { bonus.append("天同化禄") }
            if s.stars(at: tong).contains(where: { fourSha.contains($0) }) { breaking.append("同宫坐煞") }
            out.append(Pattern(
                name: "天同天梁",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .dignity,
                branches: [tong],
                summary: "天同天梁同宫，温和厚道，宜助人立业。",
                detail: "福星与荫星同宫，常见于照顾者角色：医疗、教育、公益、服务。优势是让人信任，课题是别把所有责任都接下来，也要给自己的需要留位置。",
                required: ["天同与天梁同宫", "该宫在三方四正"],
                bonus: bonus,
                breaking: breaking,
                source: "《紫微斗数全书》"
            ))
        }

        // 马头带箭
        if s.pivot == 6, s.lifeStars.contains(.qingYang) {
            var bonus: [String] = []
            if s.has(.qiSha) || s.has(.poJun) { bonus.append("再会七杀或破军") }
            if s.has(.tianKui) || s.has(.tianYue) { bonus.append("魁钺加照") }
            out.append(Pattern(
                name: "马头带箭",
                kind: bonus.isEmpty ? .neutral : .auspicious,
                category: .dignity,
                branches: [6],
                summary: "擎羊坐命于午，主锐气与执行力。",
                detail: "午为马头，擎羊在此锐气最盛。表现是遇事敢下手、竞争心强，适合需要冲锋的岗位；课题是别把锋芒对着身边人，把力气用在事情上。",
                required: ["擎羊坐命于午宫"],
                bonus: bonus,
                source: "《骨髓赋》"
            ))
        }

        return out
    }
}

// MARK: - 财官

private extension PatternEngine {

    static func wealthPatterns(_ s: Scene) -> [Pattern] {
        var out: [Pattern] = []

        // 禄马交驰
        if let lu = s.branch(of: .luCun), let ma = s.branch(of: .tianMa),
           s.inTrine(lu), s.inTrine(ma) {
            out.append(Pattern(
                name: "禄马交驰",
                kind: .auspicious,
                category: .wealth,
                branches: Array(Set([lu, ma].filter { s.inTrine($0) })).sorted(),
                summary: "禄存与天马同会三方，主动中生财。",
                detail: "禄马主「走出去才有资源」。适合跨区域、跨团队、需要跑动的机会；静止不动时，这个格局的优势发挥不出来。",
                required: ["禄存与天马同在三方四正"],
                source: "《紫微斗数全书》"
            ))
        }

        // 双禄朝垣
        if s.has(.luCun), s.hasTransformation(.lu) {
            var breaking: [String] = []
            if s.lifeStars.contains(where: { twoSha.contains($0) }) { breaking.append("命宫坐空劫，禄易散") }
            out.append(Pattern(
                name: "双禄朝垣",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .wealth,
                branches: s.branches(of: [.luCun]),
                summary: "化禄与禄存同会三方，主财源有两条路。",
                detail: "禄存是守得住的存量，化禄是流得动的增量。两者同会，代表既有稳定收入，也有额外进项。要留意的是「多一条路就多一份管理成本」，账要算清。",
                required: ["禄存在三方四正", "化禄落在三方四正"],
                breaking: breaking,
                source: "《紫微斗数全书》"
            ))
        }

        // 武贪格
        if let wu = s.branch(of: .wuQu), let tan = s.branch(of: .tanLang),
           wu == tan || Ganzhi.mod(wu + 6, 12) == tan || Ganzhi.mod(tan + 6, 12) == wu,
           s.inTrine(wu) || s.inTrine(tan) {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.has(.huoXing) || s.has(.lingXing) { bonus.append("再遇火铃，叠加爆发力") }
            if s.transformation(of: .wuQu) == .lu { bonus.append("武曲化禄") }
            if s.stars(at: wu).contains(.qingYang) || s.stars(at: wu).contains(.tuoLuo) {
                breaking.append("武贪宫见羊陀")
            }
            if s.trine.contains(wu), s.stars(at: wu).contains(where: { twoSha.contains($0) }) {
                breaking.append("遇空劫，财来财去")
            }
            out.append(Pattern(
                name: "武贪格",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .wealth,
                branches: [wu, tan],
                summary: "武曲贪狼同宫或对照，主中晚年发力。",
                detail: "财星与欲望星交会，早期常觉得资源不够、机会不对，三十岁后才逐渐把人和钱串起来。适合金融、销售、资源整合类的事；忌讳的是急，越急越容易翻车。",
                required: ["武曲贪狼同宫或对宫", "其中一宫在三方四正"],
                bonus: bonus,
                breaking: breaking,
                source: "《骨髓赋》"
            ))
        }

        // 火贪成格
        if let tan = s.branch(of: .tanLang), s.inTrine(tan), let huo = s.branch(of: .huoXing) {
            if huo == tan || s.inTrine(huo) {
                var breaking: [String] = []
                if s.stars(at: tan).contains(.qingYang) || s.stars(at: tan).contains(.tuoLuo) {
                    breaking.append("贪狼宫见羊陀，破横发之力")
                }
                if s.trine.contains(tan), s.stars(at: tan).contains(where: { twoSha.contains($0) }) {
                    breaking.append("贪狼遇空劫，来得快去得也快")
                }
                out.append(Pattern(
                    name: "火贪成格",
                    kind: breaking.isEmpty ? .auspicious : .neutral,
                    category: .wealth,
                    branches: [tan],
                    summary: "火星与贪狼同宫或会照，主突发机会。",
                    detail: "火贪主「暴发」，机会来得快也散得快。适合短期冲刺与抓住窗口，但要预设退出条件，别把一次好运当成长期能力。",
                    required: [huo == tan ? "火星与贪狼同宫" : "火星与贪狼三方会照", "贪狼在三方四正"],
                    breaking: breaking,
                    source: "《太微赋》"
                ))
            }
            if let ling = s.branch(of: .lingXing), ling == tan || s.inTrine(ling) {
                out.append(Pattern(
                    name: "铃贪成格",
                    kind: .neutral,
                    category: .wealth,
                    branches: [tan],
                    summary: "铃星与贪狼同宫或会照，主暗中的积累与转机。",
                    detail: "铃贪比火贪慢，力量偏内。适合在不被注意的阶段默默布局，等条件成熟再出手。",
                    required: [ling == tan ? "铃星与贪狼同宫" : "铃星与贪狼三方会照", "贪狼在三方四正"],
                    source: "《太微赋》"
                ))
            }
        }

        // 化禄入财
        let wealthBranch = s.branch(of: .wealth)
        if let lu = s.transformations.first(where: { $0.kind == .lu }),
           let target = s.branch(of: lu.star), Ganzhi.mod(target, 12) == wealthBranch,
           lu.star.isMain {
            out.append(Pattern(
                name: "化禄入财",
                kind: .auspicious,
                category: .wealth,
                branches: [wealthBranch],
                summary: "\(lu.star.rawValue)化禄坐财帛，收入与能力对得上。",
                detail: "化禄入财，代表赚钱的路子和自己的长处是同一件事。适合把主要精力放在能直接产出的事上，别在分支上摊薄。",
                required: ["财帛宫主星化禄"],
                source: "《紫微斗数全书》"
            ))
        }

        // 化权入官
        let careerBranch = s.branch(of: .career)
        if let quan = s.transformations.first(where: { $0.kind == .quan }),
           let target = s.branch(of: quan.star), Ganzhi.mod(target, 12) == careerBranch,
           quan.star.isMain {
            out.append(Pattern(
                name: "化权入官",
                kind: .auspicious,
                category: .wealth,
                branches: [careerBranch],
                summary: "\(quan.star.rawValue)化权坐官禄，事业上有掌控力。",
                detail: "化权入官说明在专业范围内有决定权，容易被推到负责的位置。适合主动接明确的责任，而不是等安排。",
                required: ["官禄宫主星化权"],
                source: "《紫微斗数全书》"
            ))
        }

        // 禄存守命
        if s.lifeStars.contains(.luCun) {
            out.append(Pattern(
                name: "禄存守命",
                kind: .auspicious,
                category: .wealth,
                branches: [s.pivot],
                summary: "禄存坐命，主能守、有底。",
                detail: "禄存坐命的人对资源有天然的分寸感，擅长把已有的东西保住。缺点是偏保守，遇到必须冒险的窗口容易犹豫；羊陀夹禄也提醒要留意小人。",
                required: ["禄存坐命宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 天马入命
        if s.lifeStars.contains(.tianMa) {
            out.append(Pattern(
                name: "天马入命",
                kind: .neutral,
                category: .wealth,
                branches: [s.pivot],
                summary: "天马坐命，主奔波与流动。",
                detail: "天马坐命常见于需要跑动的生活节奏：出差、跨区、换环境。动起来才顺，但要有固定的落脚点，否则容易一直在路上却没有积累。",
                required: ["天马坐命宫"],
                source: "《紫微斗数全书》"
            ))
        }

        return out
    }
}

// MARK: - 文名

private extension PatternEngine {

    static func literaryPatterns(_ s: Scene) -> [Pattern] {
        var out: [Pattern] = []

        // 文桂文华
        if s.has(.wenChang), s.has(.wenQu) {
            out.append(Pattern(
                name: "文桂文华",
                kind: .auspicious,
                category: .literary,
                branches: s.branches(of: [.wenChang, .wenQu]),
                summary: "文昌文曲会照，主文采与条理。",
                detail: "昌曲主文书、考试与表达。三方会齐时，靠文字与逻辑吃饭的事会更顺；要留意「想得漂亮、落得慢」的倾向。",
                required: ["文昌与文曲同在三方四正"],
                source: "《太微赋》"
            ))
        }

        // 阳梁昌禄
        if s.has(.taiYang), s.has(.tianLiang), s.has(.wenChang), s.has(.luCun) {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.isBright(.taiYang) { bonus.append("太阳庙旺") }
            if s.hasTransformation(.ke) { bonus.append("再会化科") }
            if s.isDim(.taiYang) { breaking.append("太阳落陷，光不足") }
            out.append(Pattern(
                name: "阳梁昌禄",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .literary,
                branches: s.branches(of: [.taiYang, .tianLiang, .wenChang, .luCun]),
                summary: "太阳天梁文昌禄存四星齐会，利于考核与专业认证。",
                detail: "四星齐会偏向「靠资格与作品说话」的路线：考试、论文、职称、专业执照都容易吃到力。优势是积累可复用，课题是别只顾考，还要把成果讲给人听。",
                required: ["太阳、天梁、文昌、禄存同在三方四正"],
                bonus: bonus,
                breaking: breaking,
                source: "《紫微斗数全书》"
            ))
        }

        // 科权禄拱
        if s.hasTransformation(.lu), s.hasTransformation(.quan), s.hasTransformation(.ke) {
            out.append(Pattern(
                name: "科权禄拱",
                kind: .auspicious,
                category: .literary,
                branches: s.trine,
                summary: "化禄化权化科齐会命宫三方，主三奇加会。",
                detail: "三奇会命是资源、权柄与名声同时到位的结构。属于「窗口期」格局，适合集中推进重要事项，别把机会摊薄在琐事上。",
                required: ["化禄、化权、化科均落在三方四正"],
                source: "《太微赋》"
            ))
        } else if s.hasTransformation(.ke), s.hasTransformation(.quan) {
            out.append(Pattern(
                name: "科权双会",
                kind: .auspicious,
                category: .literary,
                branches: s.trine,
                summary: "化科与化权同会，名声与实权互相成就。",
                detail: "科给人信任，权给人抓手。两者同会适合走「专业权威」的路线：先靠作品立信，再靠位置推动。缺禄时要注意回报节奏偏慢，别急着折算成钱。",
                required: ["化科与化权同在三方四正"],
                source: "《紫微斗数全书》"
            ))
        }

        // 昌曲夹命
        if s.flanked(by: .wenChang, and: .wenQu) {
            out.append(Pattern(
                name: "昌曲夹命",
                kind: .auspicious,
                category: .literary,
                branches: [s.prevBranch, s.pivot, s.nextBranch],
                summary: "昌曲夹命，主聪明俊秀、利考运。",
                detail: "文昌文曲分居两侧，常见于读书顺、表达早熟的人。优势是学什么都快，课题是别停在「会」的层面，要落到作品与交付上。",
                required: ["文昌与文曲分居命宫前后两宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 魁钺夹命
        if s.flanked(by: .tianKui, and: .tianYue) {
            out.append(Pattern(
                name: "魁钺夹命",
                kind: .auspicious,
                category: .literary,
                branches: [s.prevBranch, s.pivot, s.nextBranch],
                summary: "魁钺夹命，关键时刻常有人提携。",
                detail: "天魁天钺夹命，代表在求学、求职、转岗这类节点上容易遇到愿意帮的人。贵人不会凭空出现，前提是先把事做到值得被帮的程度。",
                required: ["天魁与天钺分居命宫前后两宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 魁钺同会
        if s.has(.tianKui), s.has(.tianYue) {
            out.append(Pattern(
                name: "魁钺同会",
                kind: .auspicious,
                category: .literary,
                branches: s.branches(of: [.tianKui, .tianYue]),
                summary: "魁钺同会三方，主贵人运稳定。",
                detail: "魁钺同时会照，贵人不只在关键时刻出现，日常也容易碰到愿意指路的人。宜主动维护关系，别等用到时才联系。",
                required: ["天魁与天钺同在三方四正"],
                source: "《紫微斗数全书》"
            ))
        }

        // 化科入命
        if let ke = s.transformations.first(where: { $0.kind == .ke }),
           let target = s.branch(of: ke.star), Ganzhi.mod(target, 12) == s.pivot,
           ke.star.isMain {
            out.append(Pattern(
                name: "化科入命",
                kind: .auspicious,
                category: .literary,
                branches: [s.pivot],
                summary: "\(ke.star.rawValue)化科坐命，主名声与文书运。",
                detail: "化科坐命，容易被记住的是「这个人靠谱、讲得清」。适合靠专业形象与作品积累口碑，忌讳虚名跑得比实力快。",
                required: ["命宫主星化科"],
                source: "《紫微斗数全书》"
            ))
        }

        return out
    }
}

// MARK: - 助力

private extension PatternEngine {

    static func supportPatterns(_ s: Scene) -> [Pattern] {
        var out: [Pattern] = []

        // 辅弼夹命
        if s.flanked(by: .zuoFu, and: .youBi) {
            out.append(Pattern(
                name: "辅弼夹命",
                kind: .auspicious,
                category: .support,
                branches: [s.prevBranch, s.pivot, s.nextBranch],
                summary: "左辅右弼夹命，主有人可托、事有人帮。",
                detail: "辅弼夹命的人不太适合单打独斗，团队作战反而出成绩。要练的是「把事分出去还放心」的能力。",
                required: ["左辅与右弼分居命宫前后两宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 辅弼同会
        if s.has(.zuoFu), s.has(.youBi) {
            out.append(Pattern(
                name: "辅弼同会",
                kind: .auspicious,
                category: .support,
                branches: s.branches(of: [.zuoFu, .youBi]),
                summary: "辅弼同会三方，主一生贵人不绝。",
                detail: "左辅右弼同会，代表身边长期有人可用、有人可问。适合组织协调、跨部门推进的事；忌讳的是把帮助当资源无限取用。",
                required: ["左辅与右弼同在三方四正"],
                source: "《紫微斗数全书》"
            ))
        }

        // 天魁天钺 / 昌曲 已在文名；此处补「禄存守身」与「身命同宫」以外的助力
        // 双禄夹命
        if s.flanked(by: .luCun, and: .tianMa) {
            out.append(Pattern(
                name: "禄马夹命",
                kind: .auspicious,
                category: .support,
                branches: [s.prevBranch, s.pivot, s.nextBranch],
                summary: "禄存与天马夹命，资源与机会同时到位。",
                detail: "一守一动夹在两侧，表示既有底子也有出口。适合在有稳定基础的前提下去试新的方向，别只守不动，也别只动不守。",
                required: ["禄存与天马分居命宫前后两宫"],
                source: "《紫微斗数全书》"
            ))
        }

        return out
    }
}

// MARK: - 煞忌

private extension PatternEngine {

    static func pressurePatterns(_ s: Scene) -> [Pattern] {
        var out: [Pattern] = []

        // 羊陀夹忌
        if let ji = s.jiStar(), let jiBranch = s.branch(of: ji), Ganzhi.mod(jiBranch, 12) == s.pivot {
            let left = Ganzhi.mod(jiBranch - 1, 12)
            let right = Ganzhi.mod(jiBranch + 1, 12)
            if s.stars(at: left).contains(.qingYang), s.stars(at: right).contains(.tuoLuo) {
                out.append(Pattern(
                    name: "羊陀夹忌",
                    kind: .caution,
                    category: .pressure,
                    branches: [left, jiBranch, right],
                    summary: "化忌被擎羊陀罗前后夹住，主阻力集中。",
                    detail: "忌星被羊陀夹，代表这件事推进时容易左右受制。处理方式是缩小范围、分步验证，不要一次把所有资源压上去。",
                    required: ["化忌坐命宫", "擎羊陀罗分居命宫前后两宫"],
                    source: "《太微赋》"
                ))
            }
        }

        // 羊陀夹命
        if s.flanked(by: .qingYang, and: .tuoLuo) {
            out.append(Pattern(
                name: "羊陀夹命",
                kind: .caution,
                category: .pressure,
                branches: [s.prevBranch, s.pivot, s.nextBranch],
                summary: "羊陀夹命，进退都有人推着走。",
                detail: "两侧都是煞星，常见的外部感受是「不做也难受、做了也费劲」。适合把目标切小、给自己留缓冲，不要在压力最大的时候做长期承诺。",
                required: ["擎羊与陀罗分居命宫前后两宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 火铃夹命
        if s.flanked(by: .huoXing, and: .lingXing) {
            out.append(Pattern(
                name: "火铃夹命",
                kind: .caution,
                category: .pressure,
                branches: [s.prevBranch, s.pivot, s.nextBranch],
                summary: "火铃夹命，主性急、易起突发事。",
                detail: "火铃夹命的人反应快、火气也快，容易在情绪上先动手。建议把「先回一句、稍后再答」变成习惯，很多麻烦就断在这里。",
                required: ["火星与铃星分居命宫前后两宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 空劫夹命
        if s.flanked(by: .diKong, and: .diJie) {
            out.append(Pattern(
                name: "空劫夹命",
                kind: .caution,
                category: .pressure,
                branches: [s.prevBranch, s.pivot, s.nextBranch],
                summary: "空劫夹命，主财不聚、想法偏超脱。",
                detail: "空劫夹命的人常觉得「追到手就没意思」，对物质的黏性低。适合技术、研究、内容这类靠本事而非靠囤积的事；理财上宜自动化，别靠意志力。",
                required: ["地空与地劫分居命宫前后两宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 命里逢空
        if s.lifeStars.contains(.diKong) || s.lifeStars.contains(.diJie) {
            out.append(Pattern(
                name: "命里逢空",
                kind: .neutral,
                category: .pressure,
                branches: [s.pivot],
                summary: "空劫坐命，主看得开、也容易落空。",
                detail: "空劫坐命常见两种走向：一是对得失看得很淡，二是计划常被临时打断。应对办法是把重要的事写成流程，减少对临场状态的依赖。",
                required: ["地空或地劫坐命宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 廉杀羊
        if s.has(.lianZhen), s.has(.qiSha), s.has(.qingYang) {
            out.append(Pattern(
                name: "廉杀羊",
                kind: .caution,
                category: .pressure,
                branches: s.branches(of: [.lianZhen, .qiSha, .qingYang]),
                summary: "廉贞七杀擎羊三星会照，主刚烈易生冲突。",
                detail: "三星会照代表脾气与行动力都很足，冲劲大也容易擦枪走火。古书对此格多有重语，今天更实用的读法是：争强的时候先问值不值得，安全与手续别省。",
                required: ["廉贞、七杀、擎羊同在三方四正"],
                source: "《紫微斗数全书》"
            ))
        }

        // 巨火羊
        if s.has(.juMen), s.has(.huoXing), s.has(.qingYang) {
            out.append(Pattern(
                name: "巨火羊",
                kind: .caution,
                category: .pressure,
                branches: s.branches(of: [.juMen, .huoXing, .qingYang]),
                summary: "巨门火星擎羊会照，主直言易起摩擦。",
                detail: "巨门的辨析加上火铃的急，容易把话说重。这类组合真正的功课是表达方式：先把事实讲完，再讲判断，最后才给建议。",
                required: ["巨门、火星、擎羊同在三方四正"],
                source: "《骨髓赋》"
            ))
        }

        // 铃昌陀武
        if s.has(.lingXing), s.has(.wenChang), s.has(.tuoLuo), s.has(.wuQu) {
            out.append(Pattern(
                name: "铃昌陀武",
                kind: .caution,
                category: .pressure,
                branches: s.branches(of: [.lingXing, .wenChang, .tuoLuo, .wuQu]),
                summary: "铃昌陀武四星齐会，主拖延与反复。",
                detail: "四星齐会时，最容易出现的不是大事，而是「反复改、迟迟定不下来」。建议给自己设截止时间，并让第三方帮你验收，别一个人无限打磨。",
                required: ["铃星、文昌、陀罗、武曲同在三方四正"],
                source: "《骨髓赋》"
            ))
        }

        // 巨门化忌
        if let ji = s.jiStar(), ji == .juMen, s.has(.juMen) {
            out.append(Pattern(
                name: "巨门化忌",
                kind: .caution,
                category: .pressure,
                branches: s.branches(of: [.juMen]),
                summary: "巨门化忌，主言语易生误会。",
                detail: "巨门化忌的重点在「说」与「被理解」之间的落差。重要沟通尽量留下文字，遇到分歧先确认对方听到的是什么，再解释自己的意思。",
                required: ["巨门在三方四正且化忌"],
                source: "《紫微斗数全书》"
            ))
        }

        return out
    }
}

// MARK: - 结构

private extension PatternEngine {

    static func structurePatterns(_ s: Scene) -> [Pattern] {
        var out: [Pattern] = []

        // 命无正曜
        if !s.lifeHasMainStar {
            out.append(Pattern(
                name: "命无正曜",
                kind: .neutral,
                category: .structure,
                branches: [s.pivot, Ganzhi.mod(s.pivot + 6, 12)],
                summary: "命宫无主星，借对宫安身立命。",
                detail: "命无正曜不代表命薄，而是本命色彩留给环境与选择。对宫星曜的影响会明显放大，环境适配度比个人风格更决定表现。",
                required: ["命宫无十四主星"],
                source: "《紫微斗数全书》"
            ))
        }

        // 天罗地网
        if s.pivot == 4 || s.pivot == 10 {
            out.append(Pattern(
                name: "天罗地网",
                kind: .neutral,
                category: .structure,
                branches: [s.pivot],
                summary: "命宫落辰戌，主受限于规则，也成于规则。",
                detail: "辰戌为天罗地网，起手常觉得束缚多。但这个位置也代表「在一个体系里做深」，越守规矩、越懂规则，后段越稳。",
                required: ["命宫落于辰宫或戌宫"],
                source: "《紫微斗数全书》"
            ))
        }

        // 杀破狼
        if s.has(.qiSha), s.has(.poJun), s.has(.tanLang) {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.hasTransformation(.lu) || s.hasTransformation(.quan) { bonus.append("三方有禄或权，动得有力") }
            if s.has(.zuoFu) && s.has(.youBi) { bonus.append("辅弼同会，变动中有帮手") }
            if s.shaCount(fourSha) >= 3 { breaking.append("煞星偏重，动而难成") }
            if s.lifeStars.contains(where: { twoSha.contains($0) }) { breaking.append("命坐空劫，动得辛苦") }
            out.append(Pattern(
                name: "杀破狼",
                kind: breaking.isEmpty ? .neutral : .caution,
                category: .structure,
                branches: s.trine,
                summary: "七杀、破军、贪狼三合齐会，主变动中求进。",
                detail: "杀破狼是典型的变动结构，节奏快、机会与风险同源。适合开拓与重整，不适合守着旧办法等结果；每次变动前留好退路。",
                required: ["七杀、破军、贪狼同在三方四正"],
                bonus: bonus,
                breaking: breaking,
                source: "《紫微斗数全书》"
            ))
        }

        // 机月同梁
        let jiYueSet = [Star.tianJi, .taiYin, .tianTong, .tianLiang]
        let jiYueCount = jiYueSet.filter { s.has($0) }.count
        if jiYueCount == 4 {
            var bonus: [String] = []
            var breaking: [String] = []
            if s.has(.wenChang) || s.has(.wenQu) { bonus.append("再会昌曲") }
            if s.hasTransformation(.ke) { bonus.append("再会化科") }
            if s.shaCount(fourSha) >= 3 { breaking.append("煞星过多，机月同梁忌煞") }
            out.append(Pattern(
                name: "机月同梁",
                kind: breaking.isEmpty ? .auspicious : .neutral,
                category: .structure,
                branches: s.trine,
                summary: "天机太阴天同天梁齐会，主策划与稳定并存。",
                detail: "机月同梁偏文职与规划，擅长在既有体系里优化流程。优点是稳、细、可靠，课题是决断速度——想清楚之后要敢拍板。",
                required: ["天机、太阴、天同、天梁同在三方四正"],
                bonus: bonus,
                breaking: breaking,
                source: "《骨髓赋》"
            ))
        } else if jiYueCount == 3 {
            let present = jiYueSet.filter { s.has($0) }
            let missing = jiYueSet.filter { !s.has($0) }
            out.append(Pattern(
                name: "机月同梁三星会",
                kind: .neutral,
                category: .structure,
                branches: s.branches(of: present),
                summary: "机月同梁只齐三星，力量比全格减一档。",
                detail: "完整格需要四星齐会，本盘缺 \(missing.map(\.rawValue).joined(separator: "、"))。仍偏文职与积累路线，但少了成格的加持，关键看缺的这颗与四化的配合。",
                required: ["\(present.map(\.rawValue).joined(separator: "、"))同在三方四正"],
                source: "《骨髓赋》"
            ))
        }

        // 身命同宫
        if s.layer.kind == .natal, Ganzhi.mod(s.chart.bodyBranch, 12) == s.pivot {
            out.append(Pattern(
                name: "身命同宫",
                kind: .neutral,
                category: .structure,
                branches: [s.pivot],
                summary: "命宫与身宫同宫，主表里一致、也主一身扛。",
                detail: "命身同宫的人通常不太会「说一套做一套」，想法与行动贴得很近。代价是缺少切换的余地，累了也只能自己消化，必须主动安排恢复。",
                required: ["本命命宫与身宫同宫"],
                source: ""
            ))
        }

        return out
    }
}
