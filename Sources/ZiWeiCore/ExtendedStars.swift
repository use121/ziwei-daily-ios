import Foundation

/// 全部辅星与神煞的安星法则。
///
/// 分支索引统一为：子 0、丑 1、寅 2 …… 亥 11。
/// 口诀口径沿用《紫微斗数全书》，与本项目主星定位保持一致。
public enum AuxiliaryStars {

    /// 安放全部辅星、神煞。返回「星曜 → 地支」。
    ///
    /// `monthOverride`：闰月口径换算后的有效月份；不传则用原农历月。
    public static func placements(
        lunar: LunarDate,
        hourBranch: Int,
        lifeBranch: Int,
        monthOverride: Int? = nil
    ) -> [Star: Int] {
        let monthOffset = (monthOverride ?? lunar.month) - 1
        let dayOffset = lunar.day - 1
        var result: [Star: Int] = [:]

        // 以时辰起：文昌戌上起子时逆、文曲辰上起子时顺
        let chang = Ganzhi.mod(10 - hourBranch, 12)
        let qu = Ganzhi.mod(4 + hourBranch, 12)
        result[.wenChang] = chang
        result[.wenQu] = qu

        // 以生月起：左辅辰上起正月顺、右弼戌上起正月逆
        let fu = Ganzhi.mod(4 + monthOffset, 12)
        let bi = Ganzhi.mod(10 - monthOffset, 12)
        result[.zuoFu] = fu
        result[.youBi] = bi

        // 地空亥上起子时逆、地劫亥上起子时顺
        result[.diKong] = Ganzhi.mod(11 - hourBranch, 12)
        result[.diJie] = Ganzhi.mod(11 + hourBranch, 12)

        // 天魁天钺：甲戊庚牛羊，乙己鼠猴乡，丙丁猪鸡位，壬癸兔蛇藏，辛逢马虎
        switch lunar.yearStem {
        case 0, 4, 6: result[.tianKui] = 1; result[.tianYue] = 7
        case 1, 5: result[.tianKui] = 0; result[.tianYue] = 8
        case 2, 3: result[.tianKui] = 11; result[.tianYue] = 9
        case 7: result[.tianKui] = 6; result[.tianYue] = 2
        default: result[.tianKui] = 3; result[.tianYue] = 5
        }

        // 禄存与羊陀：擎羊在禄前一位，陀罗在禄后一位
        let luBranches = [2, 3, 5, 5, 6, 6, 8, 9, 11, 0]
        let lu = luBranches[lunar.yearStem]
        result[.luCun] = lu
        result[.qingYang] = Ganzhi.mod(lu + 1, 12)
        result[.tuoLuo] = Ganzhi.mod(lu - 1, 12)

        // 火星铃星：按年支三合起火铃起点，再顺数至生时
        let yearBranch = lunar.yearBranch
        let fireStart: Int
        let bellStart: Int
        switch yearBranch {
        case 2, 6, 10: fireStart = 1; bellStart = 3      // 寅午戌：火丑、铃卯
        case 8, 0, 4: fireStart = 2; bellStart = 10      // 申子辰：火寅、铃戌
        case 5, 9, 1: fireStart = 3; bellStart = 10      // 巳酉丑：火卯、铃戌
        default: fireStart = 9; bellStart = 10           // 亥卯未：火酉、铃戌
        }
        result[.huoXing] = Ganzhi.mod(fireStart + hourBranch, 12)
        result[.lingXing] = Ganzhi.mod(bellStart + hourBranch, 12)

        // 天马：寅午戌马在申，申子辰马在寅，巳酉丑马在亥，亥卯未马在巳
        let horseByGroup = [8, 2, 11, 5]
        let group: Int
        switch yearBranch {
        case 2, 6, 10: group = 0
        case 8, 0, 4: group = 1
        case 5, 9, 1: group = 2
        default: group = 3
        }
        result[.tianMa] = horseByGroup[group]

        // 红鸾卯上起子年逆数，天喜为红鸾对宫
        result[.hongLuan] = Ganzhi.mod(3 - yearBranch, 12)
        result[.tianXi] = Ganzhi.mod(9 - yearBranch, 12)

        // 天姚丑上起正月顺、天刑酉上起正月顺
        result[.tianYao] = Ganzhi.mod(1 + monthOffset, 12)
        result[.tianXing] = Ganzhi.mod(9 + monthOffset, 12)

        // 三台由左辅起初一顺数至生日，八座由右弼起初一逆数至生日
        result[.sanTai] = Ganzhi.mod(fu + dayOffset, 12)
        result[.baZuo] = Ganzhi.mod(bi - dayOffset, 12)

        // 恩光由文昌、天贵由文曲，起初一顺数至生日再退一宫
        result[.enGuang] = Ganzhi.mod(chang + dayOffset - 1, 12)
        result[.tianGui] = Ganzhi.mod(qu + dayOffset - 1, 12)

        // 龙池辰上起子年顺、凤阁戌上起子年逆
        result[.longChi] = Ganzhi.mod(4 + yearBranch, 12)
        result[.fengGe] = Ganzhi.mod(10 - yearBranch, 12)

        // 天哭午上起子年逆、天虚午上起子年顺
        result[.tianKu] = Ganzhi.mod(6 - yearBranch, 12)
        result[.tianXu] = Ganzhi.mod(6 + yearBranch, 12)

        // 天伤居仆役宫，天使居疾厄宫
        result[.tianShang] = Ganzhi.mod(lifeBranch - 7, 12)
        result[.tianShi] = Ganzhi.mod(lifeBranch - 5, 12)

        return result
    }
}

/// 命主与身主。
public enum SoulBody {
    /// 命主：由命宫所在地支决定。
    public static func soulMaster(lifeBranch: Int) -> Star {
        let table: [Star] = [
            .tanLang, .juMen, .luCun, .wenQu, .lianZhen, .wuQu,
            .poJun, .wuQu, .lianZhen, .wenQu, .luCun, .juMen
        ]
        return table[Ganzhi.mod(lifeBranch, 12)]
    }

    /// 身主：由生年地支决定，六星循环。
    public static func bodyMaster(yearBranch: Int) -> Star {
        let table: [Star] = [.huoXing, .tianXiang, .tianLiang, .tianTong, .wenChang, .tianJi]
        return table[Ganzhi.mod(yearBranch, 12) % 6]
    }
}

/// 博士十二神：由禄存宫起博士，阳男阴女顺行、阴男阳女逆行。
public enum DoctoralTwelve {
    public static let names = [
        "博士", "力士", "青龙", "小耗", "将军", "奏书",
        "飞廉", "喜神", "病符", "大耗", "伏兵", "官府"
    ]

    /// 返回「地支 → 神名」。
    public static func sequence(luBranch: Int, isForward: Bool) -> [Int: String] {
        var result: [Int: String] = [:]
        for (offset, name) in names.enumerated() {
            let branch = isForward
                ? Ganzhi.mod(luBranch + offset, 12)
                : Ganzhi.mod(luBranch - offset, 12)
            result[branch] = name
        }
        return result
    }
}

public extension Chart {
    /// 命主星。
    var soulMaster: Star { SoulBody.soulMaster(lifeBranch: lifeBranch) }
    /// 身主星。
    var bodyMaster: Star { SoulBody.bodyMaster(yearBranch: resolvedBirth.lunarDate.yearBranch) }
    /// 禄存所在宫位，博士十二神由此起。
    var luCunBranch: Int { branch(of: .luCun) ?? 2 }
    /// 地支 → 博士十二神名。
    var doctoralSequence: [Int: String] {
        DoctoralTwelve.sequence(luBranch: luCunBranch, isForward: isForwardDecade)
    }
    /// 命主星与身主星落在哪一宫。
    func palaceHolding(_ star: Star) -> Palace? {
        palaces.first { $0.mainStars.contains(star) || $0.auxiliaryStars.contains(star) }
    }
}
