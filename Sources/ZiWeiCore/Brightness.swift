import Foundation

/// 星曜亮度七档：庙、旺、得、利、平、不、陷。
///
/// 数据口径：《紫微斗数全书》派（主流排盘软件默认），表内数值 1=庙 … 7=陷，
/// 排列顺序为「子丑寅卯辰巳午未申酉戌亥」。
/// 数据来源：Renhuai123/ziwei-doushu（MIT）整理的全星亮度表，按其金标准盘核对结果收录。
public enum Brightness: Int, Codable, CaseIterable, Sendable {
    case miao = 1
    case wang = 2
    case de = 3
    case li = 4
    case ping = 5
    case bu = 6
    case xian = 7

    public var label: String {
        switch self {
        case .miao: "庙"
        case .wang: "旺"
        case .de: "得"
        case .li: "利"
        case .ping: "平"
        case .bu: "不"
        case .xian: "陷"
        }
    }

    /// 力量偏向：庙旺得为得力，不陷为受制。
    public var isStrong: Bool {
        self == .miao || self == .wang || self == .de
    }

    public var isWeak: Bool {
        self == .bu || self == .xian
    }

    /// 用于今日评分与解读措辞的修正值。
    public var weight: Int {
        switch self {
        case .miao: 3
        case .wang: 2
        case .de: 1
        case .li: 0
        case .ping: 0
        case .bu: -1
        case .xian: -2
        }
    }

    public var phrase: String {
        switch self {
        case .miao: "力量最足"
        case .wang: "力量充足"
        case .de: "得地有力"
        case .li: "尚可发挥"
        case .ping: "表现平稳"
        case .bu: "力量偏弱"
        case .xian: "受制明显"
        }
    }

    public var advice: String {
        switch self {
        case .miao, .wang: "可以正面用力，把握主动"
        case .de, .li, .ping: "按节奏推进，不必强求"
        case .bu, .xian: "先补条件、借外力，不宜硬推"
        }
    }
}

public enum BrightnessCatalog {
    /// 子起：0=子 … 11=亥。表按《斗数全书》派，未收录的星曜返回 nil。
    private static let table: [Star: [Int]] = [
        .ziWei: [5, 1, 2, 2, 3, 2, 1, 1, 2, 2, 3, 2],
        .tianJi: [1, 7, 3, 2, 4, 5, 1, 7, 3, 2, 4, 5],
        .taiYang: [7, 6, 2, 1, 2, 2, 2, 3, 3, 5, 6, 7],
        .wuQu: [2, 1, 3, 4, 1, 5, 2, 1, 3, 4, 1, 5],
        .tianTong: [2, 6, 4, 5, 5, 1, 7, 6, 2, 5, 5, 1],
        .lianZhen: [5, 4, 1, 5, 4, 7, 5, 4, 1, 5, 4, 7],
        .tianFu: [1, 1, 1, 3, 1, 3, 2, 1, 3, 2, 1, 3],
        .taiYin: [1, 1, 2, 7, 7, 7, 6, 6, 4, 2, 2, 1],
        .tanLang: [2, 1, 5, 4, 1, 7, 2, 1, 5, 4, 1, 7],
        .juMen: [2, 6, 1, 1, 7, 2, 2, 6, 1, 1, 7, 2],
        .tianXiang: [1, 1, 1, 7, 3, 3, 1, 3, 1, 7, 3, 3],
        .tianLiang: [1, 2, 1, 1, 1, 3, 1, 2, 7, 3, 1, 7],
        .qiSha: [2, 1, 1, 2, 1, 5, 2, 1, 1, 2, 1, 5],
        .poJun: [1, 2, 3, 7, 2, 5, 1, 2, 3, 7, 2, 5],
        .wenChang: [3, 1, 7, 4, 3, 1, 7, 4, 3, 1, 7, 4],
        .wenQu: [3, 1, 5, 2, 3, 1, 7, 2, 3, 1, 7, 2],
        .zuoFu: [2, 1, 1, 7, 1, 5, 2, 1, 5, 7, 1, 6],
        .youBi: [1, 1, 2, 7, 1, 5, 2, 1, 6, 7, 1, 5],
        .tianKui: [2, 2, 0, 1, 0, 0, 1, 0, 0, 0, 0, 2],
        .tianYue: [0, 0, 2, 0, 0, 2, 0, 2, 1, 1, 0, 0],
        .luCun: [1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1],
        .tianMa: [0, 0, 2, 0, 0, 5, 0, 0, 2, 0, 0, 5],
        .qingYang: [7, 1, 0, 7, 1, 0, 7, 1, 0, 7, 1, 0],
        .tuoLuo: [0, 1, 7, 0, 1, 7, 0, 1, 7, 0, 1, 7],
        .diKong: [5, 7, 7, 5, 7, 1, 1, 5, 1, 1, 7, 7],
        .diJie: [7, 7, 5, 5, 7, 6, 1, 5, 1, 5, 5, 7]
    ]

    /// 该星在指定地支的亮度。表内为 0 表示该宫不标亮度。
    public static func brightness(of star: Star, at branch: Int) -> Brightness? {
        guard let row = table[star] else { return nil }
        let value = row[Ganzhi.mod(branch, 12)]
        guard value != 0, let brightness = Brightness(rawValue: value) else { return nil }
        return brightness
    }

    /// 该宫主星的平均力量修正，用于今日评分。
    public static func averageWeight(of stars: [Star], at branch: Int) -> Double {
        let values = stars.compactMap { brightness(of: $0, at: branch) }
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0) { $0 + $1.weight }) / Double(values.count)
    }
}
