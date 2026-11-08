import XCTest
@testable import ZiWeiCore

final class ZiWeiCoreTests: XCTestCase {
    private let timeZone = TimeZone(identifier: "Asia/Shanghai")!

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func input(_ birthDate: Date, gender: Gender = .male) -> BirthInput {
        BirthInput(displayName: "测试", birthDate: birthDate, gender: gender, birthplace: "上海", longitudeText: "121.4737")
    }

    func testKnownGregorianToLunarConversion() {
        let lunar = ChineseCalendarConverter.lunarDate(from: date(1990, 6, 15), timeZone: timeZone)
        XCTAssertEqual(lunar.yearGanzhi, "庚午")
        XCTAssertEqual(lunar.month, 5)
        XCTAssertEqual(lunar.day, 23)
        XCTAssertFalse(lunar.isLeapMonth)
        XCTAssertEqual(lunar.displayText, "庚午年 五月廿三")
    }

    func testKnownSexagenaryDay() {
        let index = Ganzhi.dayIndex(year: 2000, month: 1, day: 1)
        XCTAssertEqual(index, 54)
        XCTAssertEqual(Ganzhi.string(index), "戊午")
    }

    func testLifeAndBodyPalaceRule() throws {
        let birth = date(1990, 5, 15, 20)
        let lunar = ChineseCalendarConverter.lunarDate(from: birth, timeZone: timeZone)
        XCTAssertEqual(lunar.month, 4)
        let chart = try ChartEngine.makeChart(from: input(birth), referenceDate: date(2026, 11, 8))
        XCTAssertEqual(Ganzhi.branches[chart.lifeBranch], "未")
        XCTAssertEqual(Ganzhi.branches[chart.bodyBranch], "卯")
        XCTAssertTrue(chart.palace(at: chart.bodyBranch).isBodyPalace)
    }

    func testZiWeiPlacementExamples() {
        XCTAssertEqual(Ganzhi.branches[ChartEngine.mainStarPlacements(lunarDay: 18, bureauNumber: 2)[.ziWei]!], "戌")
        XCTAssertEqual(Ganzhi.branches[ChartEngine.mainStarPlacements(lunarDay: 17, bureauNumber: 6)[.ziWei]!], "卯")
        XCTAssertEqual(Ganzhi.branches[ChartEngine.mainStarPlacements(lunarDay: 26, bureauNumber: 4)[.ziWei]!], "戌")
        XCTAssertEqual(Ganzhi.branches[ChartEngine.mainStarPlacements(lunarDay: 25, bureauNumber: 3)[.ziWei]!], "子")
        XCTAssertEqual(Ganzhi.branches[ChartEngine.mainStarPlacements(lunarDay: 15, bureauNumber: 6)[.ziWei]!], "丑")
    }

    func testFourteenMainStarsWhenZiWeiInZi() {
        let stars = ChartEngine.mainStarPlacements(lunarDay: 25, bureauNumber: 3)
        XCTAssertEqual(stars[.ziWei], 0)
        XCTAssertEqual(stars[.tianJi], 11)
        XCTAssertEqual(stars[.taiYang], 9)
        XCTAssertEqual(stars[.wuQu], 8)
        XCTAssertEqual(stars[.tianTong], 7)
        XCTAssertEqual(stars[.lianZhen], 4)
        XCTAssertEqual(stars[.tianFu], 4)
        XCTAssertEqual(stars[.taiYin], 5)
        XCTAssertEqual(stars[.tanLang], 6)
        XCTAssertEqual(stars[.juMen], 7)
        XCTAssertEqual(stars[.tianXiang], 8)
        XCTAssertEqual(stars[.tianLiang], 9)
        XCTAssertEqual(stars[.qiSha], 10)
        XCTAssertEqual(stars[.poJun], 2)
        XCTAssertEqual(Set(stars.values).count, 10)
    }

    func testBirthTransformations() {
        let jia = ChartEngine.transformations(for: 0, source: .birth)
        XCTAssertEqual(jia.map(\.star), [.lianZhen, .poJun, .wuQu, .taiYang])
        XCTAssertEqual(jia.map(\.kind), [.lu, .quan, .ke, .ji])
        let gui = ChartEngine.transformations(for: 9, source: .day)
        XCTAssertEqual(gui.map(\.star), [.poJun, .juMen, .taiYin, .tanLang])
    }

    func testCompleteChartHasEveryMainStarExactlyOnce() throws {
        for day in 1...20 {
            let chart = try ChartEngine.makeChart(from: input(date(1992, 3, day, day % 24)), referenceDate: date(2026, 11, 8))
            let stars = chart.palaces.flatMap(\.mainStars)
            XCTAssertEqual(stars.count, 14)
            XCTAssertEqual(Set(stars).count, 14)
            XCTAssertEqual(chart.palaces.count, 12)
            XCTAssertEqual(Set(chart.palaces.map(\.kind)).count, 12)
            XCTAssertTrue(chart.palaces.allSatisfy { (2...116).contains($0.decadeStart) && $0.decadeEnd == $0.decadeStart + 9 })
        }
    }

    func testValidationCatchesRequiredAndInvalidFields() {
        var invalid = BirthInput(birthDate: date(2030, 1, 1), birthplace: " ", timeZoneIdentifier: "Invalid/Zone", longitudeText: "999")
        invalid.useTrueSolarTime = true
        XCTAssertThrowsError(try InputValidator.validate(invalid, referenceDate: date(2026, 11, 8))) { error in
            guard let validation = error as? InputValidationError else { return XCTFail("错误类型不正确") }
            let fields = Set(validation.issues.map(\.field))
            XCTAssertTrue(fields.contains("gender"))
            XCTAssertTrue(fields.contains("birthplace"))
            XCTAssertTrue(fields.contains("timeZone"))
        }

        var future = input(date(2027, 1, 1))
        future.gender = .female
        XCTAssertThrowsError(try InputValidator.validate(future, referenceDate: date(2026, 11, 8))) { error in
            let validation = error as? InputValidationError
            XCTAssertTrue(validation?.issues.contains { $0.field == "birthDate" } == true)
        }
    }

    func testTrueSolarTimeAndLateZiHour() throws {
        var solar = input(date(1990, 5, 15, 12, 10))
        solar.useTrueSolarTime = true
        let solarResolved = ChartEngine.resolveBirth(solar, timeZone: timeZone)
        XCTAssertNotEqual(solarResolved.correctionMinutes, 0)

        var lateZi = input(date(1990, 5, 15, 23, 10))
        lateZi.lateZiNextDay = true
        let nextDay = ChartEngine.resolveBirth(lateZi, timeZone: timeZone)
        XCTAssertEqual(nextDay.hourBranch, 0)
        lateZi.lateZiNextDay = false
        let sameDay = ChartEngine.resolveBirth(lateZi, timeZone: timeZone)
        XCTAssertNotEqual(sameDay.lunarDate.day, nextDay.lunarDate.day)
    }

    func testDailyReportIsDeterministicBoundedAndVaries() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let today = date(2026, 11, 8, 12)
        let first = FortuneEngine.report(for: chart, on: today)
        let second = FortuneEngine.report(for: chart, on: today)
        XCTAssertEqual(first, second)
        XCTAssertTrue((0...100).contains(first.score))
        XCTAssertEqual(first.dimensions.count, 4)
        XCTAssertTrue(first.dimensions.allSatisfy { (0...100).contains($0.score) })
        XCTAssertFalse(first.summary.isEmpty)
        XCTAssertFalse(first.scoringNotes.isEmpty)
        XCTAssertEqual(first.dayGanzhi.count, 2)
        let scores = (1...60).map { FortuneEngine.report(for: chart, on: today.addingTimeInterval(TimeInterval($0 * 86_400))).score }
        XCTAssertGreaterThan(Set(scores).count, 5)
    }
}
