import Foundation

public enum ChartEngine {
    public static func makeChart(from input: BirthInput, referenceDate: Date = Date()) throws -> Chart {
        try InputValidator.validate(input, referenceDate: referenceDate)
        let timeZone = ChineseCalendarConverter.timeZone(for: input.timeZoneIdentifier)
        let resolved = resolveBirth(input, timeZone: timeZone)
        let lunar = resolved.lunarDate
        let monthBranch = 2 + lunar.month - 1
        let lifeBranch = Ganzhi.mod(monthBranch - resolved.hourBranch, 12)
        let bodyBranch = Ganzhi.mod(monthBranch + resolved.hourBranch, 12)
        let yinStem = Ganzhi.mod((lunar.yearStem % 5) * 2 + 2, 10)
        let lifeStem = Ganzhi.mod(yinStem + Ganzhi.mod(lifeBranch - 2, 12), 10)
        let bureau = bureauElement(stem: lifeStem, branch: lifeBranch)
        let effectiveDay = effectiveLunarDay(for: resolved, timeZone: timeZone)
        var placements = mainStarPlacements(lunarDay: effectiveDay, bureauNumber: bureau.bureauNumber)
        auxiliaryPlacements(lunar: lunar, hourBranch: resolved.hourBranch).forEach { placements[$0.key] = $0.value }
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
        let adjusted = input.birthDate.addingTimeInterval(TimeInterval(correction * 60))
        let components = ChineseCalendarConverter.gregorianComponents(adjusted, timeZone: timeZone)
        let hour = components.hour ?? 12
        let hourBranch = ChineseCalendarConverter.hourBranch(hour: hour)
        let useNextDay = input.lateZiNextDay && hour == 23
        let lunarBase = useNextDay ? adjusted.addingTimeInterval(86_400) : adjusted
        let lunar = ChineseCalendarConverter.lunarDate(from: lunarBase, timeZone: timeZone)
        return ResolvedBirth(adjustedDate: adjusted, lunarDate: lunar, hourBranch: hourBranch, correctionMinutes: correction)
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

    private static func effectiveLunarDay(for resolved: ResolvedBirth, timeZone: TimeZone) -> Int {
        let lunar = resolved.lunarDate
        guard lunar.isLeapMonth else { return lunar.day }
        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = timeZone
        guard let previousMonth = chinese.date(byAdding: .month, value: -1, to: resolved.adjustedDate),
              let count = chinese.range(of: .day, in: .month, for: previousMonth)?.count else {
            return 29 + lunar.day
        }
        return count + lunar.day
    }

    private static func auxiliaryPlacements(lunar: LunarDate, hourBranch: Int) -> [Star: Int] {
        let monthOffset = lunar.month - 1
        var result: [Star: Int] = [
            .wenChang: Ganzhi.mod(10 - hourBranch, 12),
            .wenQu: Ganzhi.mod(4 + hourBranch, 12),
            .zuoFu: Ganzhi.mod(4 + monthOffset, 12),
            .youBi: Ganzhi.mod(10 - monthOffset, 12),
            .diKong: Ganzhi.mod(11 - hourBranch, 12),
            .diJie: Ganzhi.mod(11 + hourBranch, 12)
        ]
        switch lunar.yearStem {
        case 0, 4, 6: result[.tianKui] = 1; result[.tianYue] = 7
        case 1, 5: result[.tianKui] = 0; result[.tianYue] = 8
        case 2, 3: result[.tianKui] = 11; result[.tianYue] = 9
        case 7: result[.tianKui] = 6; result[.tianYue] = 2
        default: result[.tianKui] = 3; result[.tianYue] = 5
        }
        let luBranches = [2, 3, 5, 5, 6, 6, 8, 9, 11, 0]
        let lu = luBranches[lunar.yearStem]
        result[.luCun] = lu
        result[.qingYang] = Ganzhi.mod(lu + 1, 12)
        result[.tuoLuo] = Ganzhi.mod(lu - 1, 12)
        let horseByGroup = [8, 2, 11, 5]
        let branchGroup: Int
        switch lunar.yearBranch {
        case 2, 6, 10: branchGroup = 0
        case 8, 0, 4: branchGroup = 1
        case 5, 9, 1: branchGroup = 2
        default: branchGroup = 3
        }
        result[.tianMa] = horseByGroup[branchGroup]
        result[.hongLuan] = Ganzhi.mod(3 - lunar.yearBranch, 12)
        result[.tianXi] = Ganzhi.mod(9 - lunar.yearBranch, 12)
        return result
    }
}
