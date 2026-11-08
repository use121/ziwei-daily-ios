import Foundation

/// 两组以地支起宫的十二神：岁前十二神、将前十二神。
///
/// 起宫口径：
/// - 岁前十二神：岁建落在该层地支所在宫，其后诸神顺行十二宫。
/// - 将前十二神：将星落在该层地支三合局的帝旺位，其后诸神顺行十二宫。
///   申子辰见子、巳酉丑见酉、寅午戌见午、亥卯未见卯。
///
/// 「该层地支」：本命层用生年支；大限、流年、流月、流日、流时各层用该层的命宫地支。
/// 岁前第七位通行排盘写作「岁破」（岁建对宫），与博士十二神里的「大耗」是两颗不同的星，不可混用。
///
/// 神名与起宫法属公版排盘条例；下列释义为本项目按现代语境重写的「今解」，
/// 不作吉凶断语，只提示该位置容易出现的处境。
public enum GodSequence: String, CaseIterable, Identifiable, Sendable {
    case suiQian = "岁前十二神"
    case jiangQian = "将前十二神"

    public var id: String { rawValue }

    public var names: [String] {
        switch self {
        case .suiQian: TwelveGods.suiQianNames
        case .jiangQian: TwelveGods.jiangQianNames
        }
    }

    /// 起宫说明，界面上作为副标题。
    public var rule: String {
        switch self {
        case .suiQian: "岁建起于该层地支，顺行十二宫"
        case .jiangQian: "将星起于三合帝旺位，顺行十二宫"
        }
    }
}

/// 某一宫上的一组神名。
public struct PalaceGod: Identifiable, Equatable, Sendable {
    public let sequence: GodSequence
    /// 神序（0 起），用于排序与取释义。
    public let order: Int
    public let name: String

    public var id: String { "\(sequence.rawValue)-\(name)" }

    public var gist: String { TwelveGods.gist(sequence: sequence, name: name) }
}

public enum TwelveGods {
    /// 岁前十二神，自岁建起顺行。
    public static let suiQianNames = [
        "岁建", "晦气", "丧门", "贯索", "官符", "小耗",
        "岁破", "龙德", "白虎", "天德", "吊客", "病符"
    ]

    /// 将前十二神，自将星起顺行。
    public static let jiangQianNames = [
        "将星", "攀鞍", "岁驿", "息神", "华盖", "劫煞",
        "灾煞", "天煞", "指背", "咸池", "月煞", "亡神"
    ]

    /// 将星所在：三合局帝旺位。
    public static func jiangXingBranch(anchorBranch: Int) -> Int {
        [0, 9, 6, 3][Ganzhi.mod(anchorBranch, 12) % 4]
    }

    /// 该组神在十二宫的落位。返回「地支 → 宫上神」。
    public static func placement(sequence: GodSequence, anchorBranch: Int) -> [Int: PalaceGod] {
        let start: Int
        let names: [String]
        switch sequence {
        case .suiQian:
            start = Ganzhi.mod(anchorBranch, 12)
            names = suiQianNames
        case .jiangQian:
            start = jiangXingBranch(anchorBranch: anchorBranch)
            names = jiangQianNames
        }
        var result: [Int: PalaceGod] = [:]
        for (order, name) in names.enumerated() {
            result[Ganzhi.mod(start + order, 12)] = PalaceGod(sequence: sequence, order: order, name: name)
        }
        return result
    }

    /// 单宫查询。
    public static func god(sequence: GodSequence, anchorBranch: Int, palaceBranch: Int) -> PalaceGod? {
        placement(sequence: sequence, anchorBranch: anchorBranch)[Ganzhi.mod(palaceBranch, 12)]
    }

    public static func gist(sequence: GodSequence, name: String) -> String {
        switch sequence {
        case .suiQian: suiQianGist[name] ?? ""
        case .jiangQian: jiangQianGist[name] ?? ""
        }
    }

    /// 岁前诸神的今解。
    private static let suiQianGist: [String: String] = [
        "岁建": "一年的当值之位，也是这段运限的起点。适合定方向、立计划，把主导权拿在手上。",
        "晦气": "兴致偏低、事情容易拖泥带水的位置。先减负再谈推进，别把状态差误判成方向错。",
        "丧门": "与告别、收束、整理旧事相关。适合清点与收尾，不宜在这种气氛里仓促下定论。",
        "贯索": "牵连与缠绕。几件事容易互相勾住，处理时先拆线、理清责任边界。",
        "官符": "规则、文书、流程相关的位。合同与承诺要留痕，按程序走比走捷径省事。",
        "小耗": "零碎的漏损。金额都不大，但累加起来可观，宜记账、控制随手支出。",
        "岁破": "与岁建正对，代表对冲与重来。适合重启旧项目，遇硬碰的局面先稳住基本盘。",
        "龙德": "转圜与缓冲。事情卡住时这里常留有余地，宜主动找人商量。",
        "白虎": "冲撞与急事。注意安全与情绪，别在气头上做决定，也不宜争强。",
        "天德": "福德与化解之处。适合求助、修复关系、把话说开。",
        "吊客": "牵挂与往来。人情事务偏多，宜分清主次，别把别人的急事都接过来。",
        "病符": "疲累与身体信号。适合体检、早睡、把节奏调慢一点。"
    ]

    /// 将前诸神的今解。
    private static let jiangQianGist: [String: String] = [
        "将星": "主导与统御。适合担纲、定调、把一摊事拢起来。",
        "攀鞍": "上进与晋阶。适合争取机会、递材料、把成果摆到台面上。",
        "岁驿": "走动与迁转。出行、外派、跨区域的事务偏多，行程留缓冲。",
        "息神": "休整与停顿。适合复盘与养精蓄锐，不宜在此时猛冲。",
        "华盖": "孤高与才艺。适合独处钻研、创作与做需要专注的事。",
        "劫煞": "突发与夺取。宜守成，防意外支出与临时插队的事。",
        "灾煞": "波折与磕碰。注意行程与健康，凡事多留一手。",
        "天煞": "外来压力。宜低调，少树敌，把精力放在能控制的部分。",
        "指背": "背后的议论。把话说在前面、留下凭据，比事后解释有效。",
        "咸池": "情缘与魅力。社交场合容易加分，也容易分心，界限要清楚。",
        "月煞": "阴性的阻滞。推进偏慢，适合耐心打磨，别频繁改方案。",
        "亡神": "失落与遗忘。重要事项写下来、复核一遍，别依赖记忆。"
    ]
}

public extension Chart {
    /// 某一时间层的十二神起宫地支。
    ///
    /// 本命层取生年支；其余各层取该层命宫地支（流年即流年支、大限即大限宫支）。
    func godAnchor(for layer: TimeLayer) -> Int {
        switch layer.kind {
        case .natal: Ganzhi.mod(resolvedBirth.lunarDate.yearBranch, 12)
        default: Ganzhi.mod(layer.pivotBranch, 12)
        }
    }

    /// 某一时间层、某一宫上的岁前十二神。
    func suiQianGod(layer: TimeLayer, branch: Int) -> PalaceGod? {
        TwelveGods.god(sequence: .suiQian, anchorBranch: godAnchor(for: layer), palaceBranch: branch)
    }

    /// 某一时间层、某一宫上的将前十二神。
    func jiangQianGod(layer: TimeLayer, branch: Int) -> PalaceGod? {
        TwelveGods.god(sequence: .jiangQian, anchorBranch: godAnchor(for: layer), palaceBranch: branch)
    }

    /// 十二宫逐宫的岁前与将前神名，按地支 0…11 排列。
    func godTable(for layer: TimeLayer) -> [(branch: Int, suiQian: PalaceGod, jiangQian: PalaceGod)] {
        let anchor = godAnchor(for: layer)
        let sui = TwelveGods.placement(sequence: .suiQian, anchorBranch: anchor)
        let jiang = TwelveGods.placement(sequence: .jiangQian, anchorBranch: anchor)
        return (0..<12).compactMap { branch in
            guard let s = sui[branch], let j = jiang[branch] else { return nil }
            return (branch, s, j)
        }
    }
}
