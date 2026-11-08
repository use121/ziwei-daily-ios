import Foundation

public enum Ganzhi {
    public static let stems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    public static let branches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    public static let animals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]

    public static func mod(_ value: Int, _ divisor: Int) -> Int {
        ((value % divisor) + divisor) % divisor
    }

    public static func string(_ zeroBasedIndex: Int) -> String {
        let index = mod(zeroBasedIndex, 60)
        return "\(stems[index % 10])\(branches[index % 12])"
    }

    public static func index(stem: Int, branch: Int) -> Int {
        (0..<60).first { $0 % 10 == mod(stem, 10) && $0 % 12 == mod(branch, 12) } ?? 0
    }

    public static func element(ofStem stem: Int) -> Element {
        switch mod(stem, 10) / 2 {
        case 0: .wood
        case 1: .fire
        case 2: .earth
        case 3: .metal
        default: .water
        }
    }

    public static func element(ofBranch branch: Int) -> Element {
        switch mod(branch, 12) {
        case 2, 3: .wood
        case 5, 6: .fire
        case 8, 9: .metal
        case 0, 11: .water
        default: .earth
        }
    }

    public static func dayIndex(year: Int, month: Int, day: Int) -> Int {
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = y / 100
        let b = 2 - a + a / 4
        let jd = Int(365.25 * Double(y + 4716)) + Int(30.6001 * Double(m + 1)) + day + b - 1524
        return mod(jd + 49, 60)
    }
}

public enum ChineseCalendarConverter {
    public static func timeZone(for identifier: String) -> TimeZone {
        TimeZone(identifier: identifier) ?? TimeZone(identifier: "Asia/Shanghai")!
    }

    public static func gregorianComponents(_ date: Date, timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    public static func lunarDate(from date: Date, timeZone: TimeZone) -> LunarDate {
        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = timeZone
        let components = chinese.dateComponents([.year, .month, .day, .isLeapMonth], from: date)
        let sexagenaryYear = components.year ?? 1
        let gregorian = gregorianComponents(date, timeZone: timeZone)
        let yearAround = gregorian.year ?? 2000
        let gregorianYear = (yearAround - 1...yearAround + 1).first {
            Ganzhi.mod($0 - 4, 60) == sexagenaryYear - 1
        } ?? yearAround
        return LunarDate(
            gregorianYear: gregorianYear,
            sexagenaryYear: sexagenaryYear,
            month: max(1, components.month ?? 1),
            day: max(1, components.day ?? 1),
            isLeapMonth: components.isLeapMonth ?? false
        )
    }

    public static func hourBranch(hour: Int) -> Int {
        Ganzhi.mod((hour + 1) / 2, 12)
    }

    public static func localDateKey(_ date: Date, timeZone: TimeZone) -> String {
        let c = gregorianComponents(date, timeZone: timeZone)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public static func localNoon(year: Int, month: Int, day: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    public static func equationOfTimeMinutes(dayOfYear: Int) -> Double {
        let angle = 2 * Double.pi * Double(dayOfYear - 81) / 364.0
        return 9.87 * sin(2 * angle) - 7.53 * cos(angle) - 1.5 * sin(angle)
    }
}
