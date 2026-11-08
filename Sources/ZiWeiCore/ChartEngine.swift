import Foundation

public enum ChartEngine {
    public static func makeChart(from input: BirthInput, referenceDate: Date = Date()) throws -> Chart {
        try InputValidator.validate(input, referenceDate: referenceDate)
        let timeZone = ChineseCalendarConverter.timeZone(for: input.timeZoneIdentifier)
        let resolved = resolveBirth(input, timeZone: timeZone)
        let lunar = resolved.lunarDate
        let effectiveMonth = Self.effectiveMonth(lunar: lunar, mode: input.leapMonthMode)
        let monthBranch = Ganzhi.mod(2 + effectiveMonth - 1, 12)
        let lifeBranch = Ganzhi.mod(monthBranch - resolved.hourBranch, 12)
        let bodyBranch = Ganzhi.mod(monthBranch + resolved.hourBranch, 12)
        let yinStem = Ganzhi.mod((lunar.yearStem % 5) * 2 + 2, 10)
        let lifeStem = Ganzhi.mod(yinStem + Ganzhi.mod(lifeBranch - 2, 12), 10)
        let bureau = bureauElement(stem: lifeStem, branch: lifeBranch)
        let effectiveDay = effectiveLunarDay(for: resolved, timeZone: timeZone, mode: input.leapMonthMode)
        var placements = mainStarPlacements(lunarDay: effectiveDay, bureauNumber: bureau.bureauNumber)
        AuxiliaryStars.placements(
            lunar: lunar,
            hourBranch: resolved.hourBranch,
            lifeBranch: lifeBranch,
            monthOverride: effectiveMonth
        ).forEach { placements[$0.key] = $0.value }
        let birthTransformations = transformations(for: lunar.yearStem, source: .birth)
        let forward = (lunar.yearStem % 2 == 0 && input.gender == .male) || (lunar.yearStem % 2 == 1 && input.gender == .female)
        let direction = forward ? 1 : -1

        let palaces: [Palace] = (0..<12).map { branch in
            let offset = Ganzhi.mod(lifeBranch - branch, 12)
            let kind = PalaceKind.allCases[offset]
            let stem = Ganzhi.mod(yinStem + Ganzhi.mod(branch - 2, 12), 10)
            let starsAtBranch = placements.filter { $0.value == branch }.map(\.key)
            let main = Star.mainStars.filter { starsAtBranch.contains($0) }
            let auxiliary = Star.allCases.filter { !$0.isMain && starsAtBranch.contains($0) }
            let transformationsAtBranch = birthTransformations.filter { transformation in
                placements[transformation.star] == branch
            }
            let decadeDistance = Ganzhi.mod((branch - lifeBranch) * direction, 12)
            let start = bureau.bureauNumber + decadeDistance * 10
            return Palace(
                kind: kind,
                branchIndex: branch,
                stemIndex: stem,
                mainStars: main,
                auxiliaryStars: auxiliary,
                transformations: transformationsAtBranch,
                isBodyPalace: branch == bodyBranch,
                decadeStart: start,
                decadeEnd: start + 9
            )
        }
        return Chart(
            input: input,
            resolvedBirth: resolved,
            palaces: palaces,
            lifeBranch: lifeBranch,
            bodyBranch: bodyBranch,
            bureau: bureau,
            birthTransformations: birthTransformations,
            isForwardDecade: forward
        )
    }

    public static func resolveBirth(_ input: BirthInput, timeZone: TimeZone) -> ResolvedBirth {
        var correction = 0
        if input.useTrueSolarTime, let longitude = Double(input.longitudeText) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let dayOfYear = calendar.ordinality(of: .day, in: .year, for: input.birthDate) ?? 81
            let standardMeridian = Double(timeZone.secondsFromGMT(for: input.birthDate)) / 3600.0 * 15.0
            let value = (longitude - standardMeridian) * 4.0 + ChineseCalendarConverter.equationOfTimeMinutes(dayOfYear: dayOfYear)
            correction = Int(value.rounded())
        }
        // 1986–1991 年国内实行夏令时，钟表拨快一小时，排盘需减回
        let appliedDST = input.adjustForDaylightSaving && isChinaDaylightSaving(input.birthDate, timeZone: timeZone)
        if appliedDST {
            correction -= 60
        }
        let adjusted = input.birthDate.addingTimeInterval(TimeInterval(correction * 60))
        let components = ChineseCalendarConverter.gregorianComponents(adjusted, timeZone: timeZone)
        let hour = components.hour ?? 12
        let hourBranch = ChineseCalendarConverter.hourBranch(hour: hour)
        let useNextDay = input.lateZiNextDay && hour == 23
        let lunarBase = useNextDay ? adjusted.addingTimeInterval(86_400) : adjusted
        let lunar = ChineseCalendarConverter.lunarDate(from: lunarBase, timeZone: timeZone)
        return ResolvedBirth(adjustedDate: adjusted, lunarDate: lunar, hourBranch: hourBranch, correctionMinutes: correction, appliedDaylightSaving: appliedDST)
    }

    public static func bureauElement(stem: Int, branch: Int) -> Element {
        let index = Ganzhi.index(stem: stem, branch: branch)
        let pair = index / 2
        let elements: [Element] = [
            .metal, .fire, .wood, .earth, .metal, .fire, .water, .earth, .metal, .wood,
            .water, .earth, .fire, .wood, .water, .metal, .fire, .wood, .earth, .metal,
            .fire, .water, .earth, .metal, .wood, .water, .earth, .fire, .wood, .water
        ]
        return elements[pair]
    }

    public static func mainStarPlacements(lunarDay: Int, bureauNumber: Int) -> [Star: Int] {
        let addition = (bureauNumber - (lunarDay % bureauNumber)) % bureauNumber
        let quotient = (lunarDay + addition) / bureauNumber
        let base = 2 + quotient - 1
        let ziWei = Ganzhi.mod(base + (addition % 2 == 0 ? addition : -addition), 12)
        var result: [Star: Int] = [:]
        let ziWeiOffsets: [(Star, Int)] = [
            (.ziWei, 0), (.tianJi, -1), (.taiYang, -3), (.wuQu, -4), (.tianTong, -5), (.lianZhen, -8)
        ]
        ziWeiOffsets.forEach { result[$0.0] = Ganzhi.mod(ziWei + $0.1, 12) }
        let tianFu = Ganzhi.mod(4 - ziWei, 12)
        let tianFuOffsets: [(Star, Int)] = [
            (.tianFu, 0), (.taiYin, 1), (.tanLang, 2), (.juMen, 3),
            (.tianXiang, 4), (.tianLiang, 5), (.qiSha, 6), (.poJun, 10)
        ]
        tianFuOffsets.forEach { result[$0.0] = Ganzhi.mod(tianFu + $0.1, 12) }
        return result
    }

    public static func transformations(for stem: Int, source: TransformationSource) -> [Transformation] {
        let rows: [[Star]] = [
            [.lianZhen, .poJun, .wuQu, .taiYang],
            [.tianJi, .tianLiang, .ziWei, .taiYin],
            [.tianTong, .tianJi, .wenChang, .lianZhen],
            [.taiYin, .tianTong, .tianJi, .juMen],
            [.tanLang, .taiYin, .youBi, .tianJi],
            [.wuQu, .tanLang, .tianLiang, .wenQu],
            [.taiYang, .wuQu, .taiYin, .tianTong],
            [.juMen, .taiYang, .wenQu, .wenChang],
            [.tianLiang, .ziWei, .zuoFu, .wuQu],
            [.poJun, .juMen, .taiYin, .tanLang]
        ]
        return zip(rows[Ganzhi.mod(stem, 10)], TransformationKind.allCases).map {
            Transformation(star: $0.0, kind: $0.1, source: source)
        }
    }

    /// 闰月参与排盘的有效月份（非闰月恒等于本月）。
    public static func effectiveMonth(lunar: LunarDate, mode: LeapMonthMode) -> Int {
        guard lunar.isLeapMonth else { return lunar.month }
        switch mode {
        case .current:
            return lunar.month
        case .nextMonth:
            return min(12, lunar.month + 1)
        case .splitHalf, .splitAccumulate:
            return lunar.day <= 15 ? lunar.month : min(12, lunar.month + 1)
        }
    }

    /// 1986–1991 国内夏令时窗口（起始日凌晨 2 点拨快，结束日凌晨 2 点拨回）。
    public static func isChinaDaylightSaving(_ date: Date, timeZone: TimeZone) -> Bool {
        guard timeZone.identifier == "Asia/Shanghai" else { return false }
        let c = ChineseCalendarConverter.gregorianComponents(date, timeZone: timeZone)
        guard let year = c.year, let month = c.month, let day = c.day else { return false }
        let windows: [Int: ((Int, Int), (Int, Int))] = [
            1986: ((5, 4), (9, 14)),
            1987: ((4, 12), (9, 13)),
            1988: ((4, 10), (9, 11)),
            1989: ((4, 16), (9, 17)),
            1990: ((4, 15), (9, 16)),
            1991: ((4, 14), (9, 15))
        ]
        guard let (start, end) = windows[year] else { return false }
        let stamp = month * 100 + day
        return stamp >= start.0 * 100 + start.1 && stamp <= end.0 * 100 + end.1
    }

    /// 安紫微所用的日数：闰月按所选口径决定是否累计上一正一月天数。
    private static func effectiveLunarDay(for resolved: ResolvedBirth, timeZone: TimeZone, mode: LeapMonthMode) -> Int {
        let lunar = resolved.lunarDate
        guard lunar.isLeapMonth else { return lunar.day }
        switch mode {
        case .nextMonth:
            return lunar.day
        case .splitHalf where lunar.day > 15:
            return lunar.day - 15
        case .splitHalf, .current, .splitAccumulate:
            return previousMonthDayCount(for: resolved, timeZone: timeZone) + lunar.day
        }
    }

    private static func previousMonthDayCount(for resolved: ResolvedBirth, timeZone: TimeZone) -> Int {
        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = timeZone
        guard let previousMonth = chinese.date(byAdding: .month, value: -1, to: resolved.adjustedDate),
              let count = chinese.range(of: .day, in: .month, for: previousMonth)?.count else {
            return 29
        }
        return count
    }
}
