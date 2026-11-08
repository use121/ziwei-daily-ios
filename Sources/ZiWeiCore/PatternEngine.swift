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
}

/// 经典格局：由当前时间层的命宫三方四正与四化组合判定。
public struct Pattern: Identifiable, Codable, Equatable, Sendable {
    public let name: String
    public let kind: PatternKind
    public let branches: [Int]
    public let summary: String
    public let detail: String

    public var id: String { name }

    public var branchText: String {
        branches.map { Ganzhi.branches[Ganzhi.mod($0, 12)] }.joined(separator: "、")
    }
}

/// 格局判定。规则全部基于星曜落宫与四化，不引入随机与外部数据。
public enum PatternEngine {

    public static func patterns(for chart: Chart, layer: TimeLayer) -> [Pattern] {
        let pivot = layer.pivotBranch
        let trine = chart.triad(of: pivot)
        let trineStars = Set(trine.flatMap { chart.stars(at: $0) })
        let lifeStars = Set(chart.stars(at: pivot))
        let transforms = layer.transformations
        var result: [Pattern] = []

        func branch(of star: Star) -> Int? { chart.branch(of: star) }
        func has(_ star: Star) -> Bool { trineStars.contains(star) }

        // 紫府同宫
        if let zi = branch(of: .ziWei), let fu = branch(of: .tianFu), zi == fu, trine.contains(zi) {
            result.append(.init(
                name: "紫府同宫",
                kind: .auspicious,
                branches: [zi],
                summary: "紫微天府同落一宫，主稳重与统筹兼具。",
                detail: "紫微主决断，天府主积累，两者同宫时既想掌舵也重守成。适合承担需要长期经营的角色，但要留意过于求稳而错过窗口。"
            ))
        }

        // 君臣庆会
        if has(.ziWei), (has(.zuoFu) || has(.youBi)), (has(.tianKui) || has(.tianYue)) {
            result.append(.init(
                name: "君臣庆会",
                kind: .auspicious,
                branches: trine.filter { chart.stars(at: $0).contains(.ziWei) },
                summary: "紫微得辅弼魁钺相会，主有助力、易得提携。",
                detail: "紫微为君，辅弼魁钺为臣。三方四正会齐，代表关键时刻容易遇到愿意帮忙的人，也意味着要主动把资源整合起来，别独自硬扛。"
            ))
        }

        // 杀破狼
        if has(.qiSha), has(.poJun), has(.tanLang) {
            result.append(.init(
                name: "杀破狼",
                kind: .neutral,
                branches: trine,
                summary: "七杀、破军、贪狼三合齐会，主变动中求进。",
                detail: "杀破狼是典型的变动结构，节奏快、机会与风险同源。适合开拓与重整，不适合守着旧办法等结果；每次变动前留好退路。"
            ))
        }

        // 机月同梁
        if has(.tianJi), has(.taiYin), has(.tianTong), has(.tianLiang) {
            result.append(.init(
                name: "机月同梁",
                kind: .neutral,
                branches: trine,
                summary: "天机太阴天同天梁齐会，主策划与稳定并存。",
                detail: "机月同梁偏文职与规划，擅长在既有体系里优化流程。优点是稳、细、可靠，课题是决断速度——想清楚之后要敢拍板。"
            ))
        }

        // 府相朝垣
        if has(.tianFu), has(.tianXiang) {
            result.append(.init(
                name: "府相朝垣",
                kind: .auspicious,
                branches: trine.filter { chart.stars(at: $0).contains(.tianFu) || chart.stars(at: $0).contains(.tianXiang) },
                summary: "天府天相会照，主有靠、事务易成。",
                detail: "府相为「衣食之星」，会照命宫三方时，做事容易得到制度或上位者的支持。适合在有规则的场域里积累，忌讳反复变卦。"
            ))
        }

        // 月朗天门
        if lifeStars.contains(.taiYin), pivot == 11 {
            result.append(.init(
                name: "月朗天门",
                kind: .auspicious,
                branches: [11],
                summary: "太阴坐亥，主清明细腻、后劲绵长。",
                detail: "亥为天门，太阴在此得地。思维细、感受准，适合需要长期沉淀的领域；情绪起伏时容易内耗，需要固定的恢复方式。"
            ))
        }

        // 日照雷门
        if lifeStars.contains(.taiYang), pivot == 3 {
            result.append(.init(
                name: "日照雷门",
                kind: .auspicious,
                branches: [3],
                summary: "太阳坐卯，主光明外显、行动力强。",
                detail: "卯为雷门，太阳东升。表达与担当是优势，容易被看见也容易被期待绑住；学会分批释放精力，比一次燃尽更长久。"
            ))
        }

        // 石中隐玉
        if lifeStars.contains(.juMen), pivot == 0 || pivot == 6 {
            result.append(.init(
                name: "石中隐玉",
                kind: .auspicious,
                branches: [pivot],
                summary: "巨门坐子午，主口才与钻研，需时间显价值。",
                detail: "巨门在子午为得地，锋芒内藏。适合研究、教学、谈判这类靠表达与辨析取胜的事。早期容易被误解，越往后越吃香。"
            ))
        }

        // 七杀朝斗
        if lifeStars.contains(.qiSha), pivot == 2 || pivot == 8 {
            result.append(.init(
                name: "七杀朝斗",
                kind: .auspicious,
                branches: [pivot],
                summary: "七杀坐寅申，主魄力与开拓。",
                detail: "七杀朝斗是能扛事的结构，适合从零到一的场景。注意节奏：推进要快，收尾要稳，别把「敢冲」当成唯一手段。"
            ))
        }

        // 雄宿朝垣
        if lifeStars.contains(.tanLang), [2, 6, 10].contains(pivot) {
            result.append(.init(
                name: "雄宿朝垣",
                kind: .auspicious,
                branches: [pivot],
                summary: "贪狼坐寅午戌，主活力与资源整合。",
                detail: "贪狼得火局之地，社交与机会感强。擅长把人和事串起来，课题是取舍——机会太多时，选择比努力更关键。"
            ))
        }

        // 文桂文华
        if has(.wenChang), has(.wenQu) {
            result.append(.init(
                name: "文桂文华",
                kind: .auspicious,
                branches: trine.filter { chart.stars(at: $0).contains(.wenChang) || chart.stars(at: $0).contains(.wenQu) },
                summary: "文昌文曲会照，主文采与条理。",
                detail: "昌曲主文书、考试与表达。三方会齐时，靠文字与逻辑吃饭的事会更顺；要留意「想得漂亮、落得慢」的倾向。"
            ))
        }

        // 科权禄拱
        let luckyBranches = Set(transforms.filter { $0.kind != .ji }.compactMap { branch(of: $0.star) })
        if transforms.contains(where: { $0.kind == .lu }),
           transforms.contains(where: { $0.kind == .quan }),
           transforms.contains(where: { $0.kind == .ke }),
           luckyBranches.isSubset(of: Set(trine)) {
            result.append(.init(
                name: "科权禄拱",
                kind: .auspicious,
                branches: trine,
                summary: "化禄化权化科齐会命宫三方，主三奇加会。",
                detail: "三奇会命是资源、权柄与名声同时到位的结构。属于「窗口期」格局，适合集中推进重要事项，别把机会摊薄在琐事上。"
            ))
        }

        // 禄马交驰
        if let lu = branch(of: .luCun), let ma = branch(of: .tianMa), trine.contains(lu), trine.contains(ma) {
            result.append(.init(
                name: "禄马交驰",
                kind: .auspicious,
                branches: [lu, ma].filter { trine.contains($0) },
                summary: "禄存与天马同会三方，主动中生财。",
                detail: "禄马主「走出去才有资源」。适合跨区域、跨团队、需要跑动的机会；静止不动时，这个格局的优势发挥不出来。"
            ))
        }

        // 火贪 / 铃贪
        if let tan = branch(of: .tanLang), trine.contains(tan) {
            if let huo = branch(of: .huoXing), huo == tan {
                result.append(.init(
                    name: "火贪成格",
                    kind: .neutral,
                    branches: [tan],
                    summary: "火星与贪狼同宫，主突发机会。",
                    detail: "火贪主「暴发」，机会来得快也散得快。适合短期冲刺与抓住窗口，但要预设退出条件，别把一次好运当成长期能力。"
                ))
            }
            if let ling = branch(of: .lingXing), ling == tan {
                result.append(.init(
                    name: "铃贪成格",
                    kind: .neutral,
                    branches: [tan],
                    summary: "铃星与贪狼同宫，主暗中的积累与转机。",
                    detail: "铃贪比火贪慢，力量偏内。适合在不被注意的阶段默默布局，等条件成熟再出手。"
                ))
            }
        }

        // 羊陀夹忌
        if let ji = transforms.first(where: { $0.kind == .ji }), let jiBranch = branch(of: ji.star) {
            let left = Ganzhi.mod(jiBranch - 1, 12)
            let right = Ganzhi.mod(jiBranch + 1, 12)
            if chart.stars(at: left).contains(.qingYang), chart.stars(at: right).contains(.tuoLuo) {
                result.append(.init(
                    name: "羊陀夹忌",
                    kind: .caution,
                    branches: [left, jiBranch, right],
                    summary: "化忌被擎羊陀罗前后夹住，主阻力集中。",
                    detail: "忌星被羊陀夹，代表这件事推进时容易左右受制。处理方式是缩小范围、分步验证，不要一次把所有资源压上去。"
                ))
            }
        }

        // 命无正曜
        if chart.palace(at: pivot).mainStars.isEmpty {
            result.append(.init(
                name: "命无正曜",
                kind: .neutral,
                branches: [pivot, Ganzhi.mod(pivot + 6, 12)],
                summary: "命宫无主星，借对宫安身立命。",
                detail: "命无正曜不代表命薄，而是本命色彩留给环境与选择。对宫星曜的影响会明显放大，环境适配度比个人风格更决定表现。"
            ))
        }

        // 天罗地网
        if chart.palace(at: pivot).mainStars.isEmpty == false, pivot == 4 || pivot == 10 {
            result.append(.init(
                name: "天罗地网",
                kind: .neutral,
                branches: [pivot],
                summary: "命宫落辰戌，主受限于规则，也成于规则。",
                detail: "辰戌为天罗地网，起手常觉得束缚多。但这个位置也代表「在一个体系里做深」，越守规矩、越懂规则，后段越稳。"
            ))
        }

        return result
    }
}
