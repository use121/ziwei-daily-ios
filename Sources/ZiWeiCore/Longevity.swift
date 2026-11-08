import Foundation

/// 长生十二神：按五行局起长生，阳男阴女顺行、阴男阳女逆行。
///
/// 起宫口诀：水二局长生在申，木三局长生在亥，金四局长生在巳，
/// 土五局长生在申，火六局长生在寅。
public enum LongevityTwelve {
    public static let names = [
        "长生", "沐浴", "冠带", "临官", "帝旺", "衰",
        "病", "死", "墓", "绝", "胎", "养"
    ]

    /// 五行局对应的长生起宫。
    public static func startBranch(bureau: Element) -> Int {
        switch bureau {
        case .water: 8    // 水二局：长生在申
        case .wood: 11    // 木三局：长生在亥
        case .metal: 5    // 金四局：长生在巳
        case .earth: 8    // 土五局：长生在申
        case .fire: 2     // 火六局：长生在寅
        }
    }

    /// 返回「地支 → 长生十二神名」。方向沿用大限顺逆（阳男阴女顺、阴男阳女逆）。
    public static func sequence(bureau: Element, isForward: Bool) -> [Int: String] {
        var result: [Int: String] = [:]
        let start = startBranch(bureau: bureau)
        for (offset, name) in names.enumerated() {
            let branch = isForward
                ? Ganzhi.mod(start + offset, 12)
                : Ganzhi.mod(start - offset, 12)
            result[branch] = name
        }
        return result
    }

    /// 长生十二神的简释，用于宫位详情。
    public static func note(_ name: String) -> String {
        switch name {
        case "长生": "初生萌发，气机舒展，宜开新局"
        case "沐浴": "初露锋芒而不稳，易受外缘牵动"
        case "冠带": "渐成气象，适合定型与亮相"
        case "临官": "能力到位，做事有底气"
        case "帝旺": "气势最足的一段，防刚过易折"
        case "衰": "由盛转稳，宜守成不宜冒进"
        case "病": "气力回落，重在调理与减负"
        case "死": "气尽而静，适合收尾与放下"
        case "墓": "收藏入库，利积累不利外拓"
        case "绝": "旧气已尽，新气未生，宜静养"
        case "胎": "新机暗结，酝酿待时"
        case "养": "蓄势渐充，稳步培育"
        default: ""
        }
    }
}

/// 小限：按生年支三合局起一岁，男顺女逆，每年移一宫。
///
/// 寅午戌年生人起辰宫，申子辰年生人起戌宫，
/// 巳酉丑年生人起未宫，亥卯未年生人起丑宫。
public enum MinorLimit {
    /// 一岁小限起宫。
    public static func startBranch(yearBranch: Int) -> Int {
        switch Ganzhi.mod(yearBranch, 12) {
        case 2, 6, 10: 4      // 寅午戌起辰
        case 8, 0, 4: 10      // 申子辰起戌
        case 5, 9, 1: 7       // 巳酉丑起未
        default: 1            // 亥卯未起丑
        }
    }

    /// 指定虚岁的小限所在宫。性别未知时按顺行处理。
    public static func branch(yearBranch: Int, nominalAge age: Int, isMale: Bool = true) -> Int {
        let start = startBranch(yearBranch: yearBranch)
        let offset = max(0, age - 1)
        return Ganzhi.mod(start + (isMale ? offset : -offset), 12)
    }
}

/// 一条自化记录：某宫宫干四化落回本宫。
public struct SelfTransformation: Codable, Equatable, Identifiable, Sendable {
    public let branch: Int
    public let star: Star
    public let kind: TransformationKind

    public var id: String { "\(branch)-\(star.rawValue)-\(kind.rawValue)" }
}

/// 一条飞星记录：某宫宫干飞出的四化及其落点。
public struct FlyingTransformation: Codable, Equatable, Identifiable, Sendable {
    public let originBranch: Int
    public let star: Star
    public let kind: TransformationKind
    public let targetBranch: Int

    public var id: String { "\(originBranch)-\(star.rawValue)-\(kind.rawValue)" }
    /// 落点回本宫即为自化。
    public var isSelfTransformation: Bool { originBranch == targetBranch }
}

public extension Chart {
    /// 全盘的自化列表。
    var selfTransformations: [SelfTransformation] {
        flyingTransformations
            .filter(\.isSelfTransformation)
            .map { SelfTransformation(branch: $0.originBranch, star: $0.star, kind: $0.kind) }
    }

    /// 十二宫各自以宫干飞出的全部四化（共 48 条）。
    var flyingTransformations: [FlyingTransformation] {
        palaces.flatMap { palace in
            ChartEngine.transformations(for: palace.stemIndex, source: .palace).compactMap { item in
                guard let target = branch(of: item.star) else { return nil }
                return FlyingTransformation(
                    originBranch: palace.branchIndex,
                    star: item.star,
                    kind: item.kind,
                    targetBranch: target
                )
            }
        }
    }

    /// 某一宫的自化（无则空数组）。
    func selfTransformations(at branch: Int) -> [SelfTransformation] {
        selfTransformations.filter { $0.branch == Ganzhi.mod(branch, 12) }
    }

    /// 某一宫宫干飞出的四化路径。
    func flyingTransformations(from branch: Int) -> [FlyingTransformation] {
        flyingTransformations.filter { $0.originBranch == Ganzhi.mod(branch, 12) }
    }

    /// 长生十二神：地支 → 神名。
    var longevitySequence: [Int: String] {
        LongevityTwelve.sequence(bureau: bureau, isForward: isForwardDecade)
    }

    /// 当前虚岁的小限宫（男顺女逆；性别未知按顺行）。
    var minorLimitBranch: Int {
        MinorLimit.branch(
            yearBranch: resolvedBirth.lunarDate.yearBranch,
            nominalAge: nominalAge(),
            isMale: input.gender != .female
        )
    }

    /// 指定虚岁的小限宫。
    func minorLimitBranch(age: Int) -> Int {
        MinorLimit.branch(
            yearBranch: resolvedBirth.lunarDate.yearBranch,
            nominalAge: age,
            isMale: input.gender != .female
        )
    }
}
