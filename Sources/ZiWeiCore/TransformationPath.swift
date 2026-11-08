import Foundation

/// 四化落点：哪颗星、化什么、落在哪一宫。
public struct TransformEntry: Identifiable, Codable, Equatable, Sendable {
    public let kind: TransformationKind
    public let star: Star
    public let branch: Int
    public let palace: PalaceKind
    public let source: TransformationSource

    public var id: String { kind.rawValue }
    public var palaceName: String { palace.rawValue }
    public var branchName: String { Ganzhi.branches[Ganzhi.mod(branch, 12)] }
    public var text: String { "\(star.rawValue)\(kind.rawValue) · \(palaceName)（\(branchName)）" }
}

/// 四化飞星的落点关系。
public enum TransformRelation: String, Codable, Sendable {
    case same = "同宫"
    case opposite = "对宫"
    case trine = "三合"
    case adjacent = "邻宫"
    case other = "遥隔"

    public var hint: String {
        switch self {
        case .same: "力量叠在同一件事上，集中但容易失衡。"
        case .opposite: "一推一拉，需要在两端之间找平衡。"
        case .trine: "互相加持，事情会沿着同一条线推进。"
        case .adjacent: "彼此牵动，前后脚发生。"
        case .other: "两件事各自发展，需要分开处理。"
        }
    }
}

public enum TransformationPathEngine {

    public static func entries(chart: Chart, layer: TimeLayer) -> [TransformEntry] {
        layer.transformations.compactMap { transformation in
            guard let branch = chart.branch(of: transformation.star) else { return nil }
            return TransformEntry(
                kind: transformation.kind,
                star: transformation.star,
                branch: branch,
                palace: chart.palaceKind(at: branch, pivot: layer.pivotBranch),
                source: transformation.source
            )
        }
        .sorted { kindOrder($0.kind) < kindOrder($1.kind) }
    }

    /// 化禄宫与化忌宫之间的关系。
    public static func relation(between lhs: Int, and rhs: Int) -> TransformRelation {
        let diff = Ganzhi.mod(rhs - lhs, 12)
        switch diff {
        case 0: return .same
        case 6: return .opposite
        case 4, 8: return .trine
        case 1, 11: return .adjacent
        default: return .other
        }
    }

    /// 一句话串起禄权科忌的去向。
    public static func summary(chart: Chart, layer: TimeLayer) -> String {
        let entries = entries(chart: chart, layer: layer)
        guard let lu = entries.first(where: { $0.kind == .lu }),
              let ji = entries.first(where: { $0.kind == .ji }) else {
            return "当前层没有起四化。"
        }
        let relation = relation(between: lu.branch, and: ji.branch)
        return "\(layer.stemName)干起四化：\(lu.star.rawValue)化禄在\(lu.palaceName)，\(ji.star.rawValue)化忌在\(ji.palaceName)，两者\(relation.rawValue)。\(relation.hint)"
    }

    /// 按宫位归并，便于宫位详情展示。
    public static func grouped(chart: Chart, layer: TimeLayer) -> [PalaceKind: [TransformEntry]] {
        Dictionary(grouping: entries(chart: chart, layer: layer), by: \.palace)
    }

    private static func kindOrder(_ kind: TransformationKind) -> Int {
        switch kind {
        case .lu: 0
        case .quan: 1
        case .ke: 2
        case .ji: 3
        }
    }
}

/// 各解读主题的强弱评分（0–100），用于雷达图与排序。
public struct TopicScore: Identifiable, Equatable, Sendable {
    public let topic: InsightTopic
    public let score: Int

    public var id: String { topic.rawValue }
}

public enum TopicScoreEngine {

    public static func scores(chart: Chart, layer: TimeLayer) -> [TopicScore] {
        let transforms = TransformationPathEngine.entries(chart: chart, layer: layer)
        return InsightTopic.allCases.map { topic in
            TopicScore(topic: topic, score: score(topic: topic, chart: chart, layer: layer, transforms: transforms))
        }
    }

    private static func score(
        topic: InsightTopic,
        chart: Chart,
        layer: TimeLayer,
        transforms: [TransformEntry]
    ) -> Int {
        let branch = branch(for: topic, chart: chart, layer: layer)
        let palace = chart.palace(at: branch)
        var stars = palace.mainStars
        if stars.isEmpty {
            stars = chart.palace(at: Ganzhi.mod(branch + 6, 12)).mainStars
        }
        guard !stars.isEmpty else { return 55 }

        // 主星权重（-2…+2）映射到 58…88
        let weights = stars.map { Double(StarCatalog.profile($0).weight) }
        let average = weights.reduce(0, +) / Double(weights.count)
        var value = 73.0 + average * 7.5

        // 亮度修正
        let brightness = stars.compactMap { star -> Double? in
            guard let level = BrightnessCatalog.brightness(of: star, at: branch) else { return nil }
            return Double(level.weight)
        }
        if !brightness.isEmpty {
            value += brightness.reduce(0, +) / Double(brightness.count) * 2.2
        }

        // 四化修正
        for entry in transforms where entry.branch == branch {
            switch entry.kind {
            case .lu: value += 7
            case .quan: value += 5
            case .ke: value += 4
            case .ji: value -= 8
            }
        }

        // 煞星修正
        let sha: Set<Star> = [.qingYang, .tuoLuo, .huoXing, .lingXing, .diKong, .diJie]
        let shaCount = palace.auxiliaryStars.filter { sha.contains($0) }.count
        value -= Double(shaCount) * 3.2

        // 吉星修正
        let lucky: Set<Star> = [.zuoFu, .youBi, .tianKui, .tianYue, .wenChang, .wenQu, .luCun, .tianMa]
        let luckyCount = palace.auxiliaryStars.filter { lucky.contains($0) }.count
        value += Double(luckyCount) * 1.6

        return min(97, max(38, Int(value.rounded())))
    }

    private static func branch(for topic: InsightTopic, chart: Chart, layer: TimeLayer) -> Int {
        Ganzhi.mod(layer.pivotBranch - PalaceKind.allCases.firstIndex(of: topic.palace)!, 12)
    }
}
