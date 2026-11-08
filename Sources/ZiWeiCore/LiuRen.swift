import Foundation

/// 小六壬的六个宫位。
///
/// 传统掌诀把六宫安在左手食指、中指、无名指的六个指节上，顺数一圈即一周天：
/// 食指下节大安 → 食指上节留连 → 中指上节速喜 → 无名指上节赤口 →
/// 无名指下节小吉 → 中指下节空亡 → 回到大安。
public enum LiuRenPalace: Int, CaseIterable, Identifiable, Sendable {
    case daAn = 0
    case liuLian = 1
    case suXi = 2
    case chiKou = 3
    case xiaoJi = 4
    case kongWang = 5

    public var id: Int { rawValue }

    public var name: String {
        switch self {
        case .daAn: "大安"
        case .liuLian: "留连"
        case .suXi: "速喜"
        case .chiKou: "赤口"
        case .xiaoJi: "小吉"
        case .kongWang: "空亡"
        }
    }

    /// 吉凶倾向。按传统吉凶用朱、凶事用墨，不用刺目的红绿。
    public var verdict: LiuRenVerdict {
        switch self {
        case .daAn, .suXi, .xiaoJi: .auspicious
        case .liuLian: .stalled
        case .chiKou, .kongWang: .inauspicious
        }
    }

    /// 掌诀所在指节，图上标注用。
    public var knuckle: String {
        switch self {
        case .daAn: "食指下节"
        case .liuLian: "食指上节"
        case .suXi: "中指上节"
        case .chiKou: "无名指上节"
        case .xiaoJi: "无名指下节"
        case .kongWang: "中指下节"
        }
    }

    /// 五行与六神，古籍断辞里常一起出现。
    public var element: String {
        switch self {
        case .daAn, .xiaoJi: "木"
        case .liuLian: "水"
        case .suXi: "火"
        case .chiKou: "金"
        case .kongWang: "土"
        }
    }

    public var spirit: String {
        switch self {
        case .daAn: "青龙"
        case .liuLian: "玄武"
        case .suXi: "朱雀"
        case .chiKou: "白虎"
        case .xiaoJi: "六合"
        case .kongWang: "勾陈"
        }
    }

    /// 谋事主数，用来印证日期尾数。
    public var numbers: String {
        switch self {
        case .daAn, .xiaoJi: "一、五、七"
        case .liuLian: "二、八、十"
        case .suXi, .kongWang: "三、六、九"
        case .chiKou: "四、七、十"
        }
    }

    /// 一句主断。
    public var gist: String {
        switch self {
        case .daAn: "事缓而稳，宜守不宜急"
        case .liuLian: "迟滞不前，此事难速成"
        case .suXi: "应声而至，很快有回音"
        case .chiKou: "牵涉口舌是非，有人从中作梗"
        case .xiaoJi: "有转机，和合可成"
        case .kongWang: "事多落空，宜另作打算"
        }
    }

    /// 应期。
    public var pace: String {
        switch self {
        case .daAn: "通常一周左右见分晓"
        case .liuLian: "拖延较久，常以半月计"
        case .suXi: "快则当日，慢不过三日"
        case .chiKou: "争执多在近日，三五天内见"
        case .xiaoJi: "约在两周内看到结果"
        case .kongWang: "多半再无下文"
        }
    }

    /// 落到具体事情上的建议。
    public var counsel: String {
        switch self {
        case .daAn:
            "按原计划推进即可，不必额外加码。若在等人回话，对方多半还在权衡，催也催不出结果。"
        case .liuLian:
            "今天不宜再推进，换个时间或换个人去谈。若对方反复不表态，先按最坏情况做准备。"
        case .suXi:
            "适合马上去问、去查、去投递。想确认的消息，今天就开口，别拖到明天。"
        case .chiKou:
            "话到嘴边留半句，书面沟通优于当面争执。必须谈时，挑第三方在场的场合。"
        case .xiaoJi:
            "适合找人商量、牵线、合伙。把话说开，多半有人愿意帮你一把。"
        case .kongWang:
            "不必再反复确认，也不必为了证明自己没错而硬做。把力气挪到下一件事上。"
        }
    }

    /// 公版古籍断辞（小六壬掌诀歌，历代传抄，无单一作者）。
    public var classic: String {
        switch self {
        case .daAn:
            "大安事事昌，求谋在东方，失物去不远，宅舍保安康，行人身未动，病者主无妨。"
        case .liuLian:
            "留连事难成，求谋日未明，官事凡宜缓，去者未回程，失物南方见，急讨方心称。"
        case .suXi:
            "速喜喜来临，求财向南行，失物申未午，逢人路上寻，官事有福德，病者无祸侵。"
        case .chiKou:
            "赤口主口舌，官非切要防，失物急去寻，行人有惊慌，六畜多作怪，病者出西方。"
        case .xiaoJi:
            "小吉最吉昌，路上好商量，阳人来报喜，失物在坤方，行人立便至，交易甚是强。"
        case .kongWang:
            "空亡事不祥，阴人多乖张，求财无利益，行人有灾殃，失物寻不见，官事有刑伤。"
        }
    }
}

public enum LiuRenVerdict: String, Sendable {
    case auspicious = "吉"
    case stalled = "不利"
    case inauspicious = "凶"

    /// 说明用的一句话，避免只给一个吉凶字。
    public var note: String {
        switch self {
        case .auspicious: "此事有可为处，节奏对就能成"
        case .stalled: "不是坏事，只是推不动，宜缓"
        case .inauspicious: "阻力在人和与时机，宜避锋"
        }
    }
}

/// 一次起课的结果。
public struct LiuRenCast: Equatable, Sendable {
    public let moment: Date
    public let timeZoneIdentifier: String
    public let lunarMonth: Int
    public let lunarDay: Int
    public let isLeapMonth: Bool
    /// 0 = 子时，11 = 亥时
    public let hourBranch: Int
    public let monthPalace: LiuRenPalace
    public let dayPalace: LiuRenPalace
    public let hourPalace: LiuRenPalace

    /// 末宫定时：时宫为断。
    public var verdictPalace: LiuRenPalace { hourPalace }

    public var hourBranchName: String { Ganzhi.branches[hourBranch] }

    public var lunarText: String {
        "农历\(ChineseMonthName.text(month: lunarMonth, isLeap: isLeapMonth))\(ChineseDayName.text(day: lunarDay))"
    }
}

public enum LiuRenEngine {
    /// 三步顺数：月从大安起，日从月落之宫起，时从日落之宫起。
    /// 起点所在的那一宫算第一位，数满一圈接着从大安续。
    public static func palaces(lunarMonth: Int, lunarDay: Int, hourBranch: Int) -> (month: LiuRenPalace, day: LiuRenPalace, hour: LiuRenPalace) {
        let month = max(1, lunarMonth)
        let day = max(1, lunarDay)
        let branch = Ganzhi.mod(hourBranch, 12)

        let monthIndex = (month - 1) % 6
        let dayIndex = (monthIndex + day - 1) % 6
        let hourIndex = (dayIndex + branch) % 6

        return (
            LiuRenPalace(rawValue: monthIndex) ?? .daAn,
            LiuRenPalace(rawValue: dayIndex) ?? .daAn,
            LiuRenPalace(rawValue: hourIndex) ?? .daAn
        )
    }

    /// 以此刻起课。用设备时间与设备时区，闰月按本月数。
    public static func cast(on date: Date = Date(), timeZone: TimeZone = .current) -> LiuRenCast {
        let lunar = ChineseCalendarConverter.lunarDate(from: date, timeZone: timeZone)
        let components = ChineseCalendarConverter.gregorianComponents(date, timeZone: timeZone)
        // 23 点后仍记当天农历日，时辰已入子时，这与排盘里的晚子时口径一致
        let branch = ChineseCalendarConverter.hourBranch(hour: components.hour ?? 12)
        let result = palaces(lunarMonth: lunar.month, lunarDay: lunar.day, hourBranch: branch)

        return LiuRenCast(
            moment: date,
            timeZoneIdentifier: timeZone.identifier,
            lunarMonth: lunar.month,
            lunarDay: lunar.day,
            isLeapMonth: lunar.isLeapMonth,
            hourBranch: branch,
            monthPalace: result.month,
            dayPalace: result.day,
            hourPalace: result.hour
        )
    }
}

/// 起课三步的文字推演，界面上逐步展示，让算法看得见。
public struct LiuRenStep: Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let count: Int
    public let from: LiuRenPalace
    public let to: LiuRenPalace
    public let note: String

    /// 「从大安起数九位，落速喜」
    public var line: String {
        "从\(from.name)起数 \(count) 位，落\(to.name)"
    }
}

public extension LiuRenCast {
    var steps: [LiuRenStep] {
        [
            LiuRenStep(id: 0, title: "月", count: lunarMonth, from: .daAn, to: monthPalace,
                       note: "正月起大安，月份几就数几位"),
            LiuRenStep(id: 1, title: "日", count: lunarDay, from: monthPalace, to: dayPalace,
                       note: "从月落之宫起初一，日几就数几位"),
            LiuRenStep(id: 2, title: "时", count: hourBranch + 1, from: dayPalace, to: hourPalace,
                       note: "从日落之宫起子时，子一丑二顺数")
        ]
    }
}

/// 农历月份写法：正月、冬月、腊月，闰月前缀闰。
public enum ChineseMonthName {
    public static func text(month: Int, isLeap: Bool) -> String {
        let base: String
        switch month {
        case 1: base = "正月"
        case 11: base = "冬月"
        case 12: base = "腊月"
        default: base = "\(number(month))月"
        }
        return isLeap ? "闰" + base : base
    }

    public static func number(_ value: Int) -> String {
        let digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        switch value {
        case 1...10: return digits[value]
        case 11...19: return "十" + digits[value - 10]
        case 20: return "二十"
        case 21...29: return "二十" + digits[value - 20]
        case 30: return "三十"
        default: return String(value)
        }
    }
}

public enum ChineseDayName {
    public static func text(day: Int) -> String {
        switch day {
        case 1...10: return "初" + ChineseMonthName.number(day)
        case 11...19: return "十" + ChineseMonthName.number(day - 10)
        case 20: return "二十"
        case 21...29: return "廿" + ChineseMonthName.number(day - 20)
        case 30: return "三十"
        default: return String(day)
        }
    }
}
