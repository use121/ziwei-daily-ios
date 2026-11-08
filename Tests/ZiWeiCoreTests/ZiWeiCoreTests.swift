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

    // MARK: - 阶段 1：亮度 / 时间层 / 解读

    func testBrightnessTableCoversEveryMainStarAndBranch() {
        for star in Star.mainStars {
            let values = (0..<12).compactMap { BrightnessCatalog.brightness(of: star, at: $0) }
            XCTAssertEqual(values.count, 12, "\(star.rawValue) 亮度缺失")
        }
        // 逐条核对《斗数全书》派的几个锚点
        XCTAssertEqual(BrightnessCatalog.brightness(of: .ziWei, at: 6), .miao)   // 紫微在午庙
        XCTAssertEqual(BrightnessCatalog.brightness(of: .taiYang, at: 0), .xian)  // 太阳在子陷
        XCTAssertEqual(BrightnessCatalog.brightness(of: .taiYin, at: 3), .xian)   // 太阴在卯陷
        XCTAssertEqual(BrightnessCatalog.brightness(of: .tianFu, at: 0), .miao)   // 天府在子庙
        XCTAssertEqual(BrightnessCatalog.brightness(of: .qiSha, at: 5), .ping)    // 七杀在巳平
        XCTAssertEqual(BrightnessCatalog.brightness(of: .poJun, at: 11), .ping)   // 破军在亥平
    }

    func testBrightnessWeightsAreMonotonic() {
        XCTAssertGreaterThan(Brightness.miao.weight, Brightness.wang.weight)
        XCTAssertGreaterThan(Brightness.wang.weight, Brightness.de.weight)
        XCTAssertGreaterThan(Brightness.de.weight, Brightness.bu.weight)
        XCTAssertGreaterThan(Brightness.bu.weight, Brightness.xian.weight)
        XCTAssertTrue(Brightness.miao.isStrong)
        XCTAssertTrue(Brightness.xian.isWeak)
    }

    func testTenStemTransformationTableMatchesClassic() {
        let expected: [[Star]] = [
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
        for stem in 0..<10 {
            let result = ChartEngine.transformations(for: stem, source: .year)
            XCTAssertEqual(result.map(\.star), expected[stem], "\(Ganzhi.stems[stem])干四化不符")
            XCTAssertEqual(result.map(\.kind), [.lu, .quan, .ke, .ji])
        }
    }

    func testNatalLayerPivotMatchesLifePalace() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let natal = chart.timeLayer(kind: .natal, on: date(2026, 11, 8))
        XCTAssertEqual(natal.pivotBranch, chart.lifeBranch)
        XCTAssertEqual(natal.transformations.count, 4)
        XCTAssertEqual(natal.transformations.map(\.source), Array(repeating: .birth, count: 4))
        XCTAssertEqual(chart.palaceKind(at: natal.pivotBranch, pivot: natal.pivotBranch), .life)
        XCTAssertEqual(chart.palaceKind(at: Ganzhi.mod(natal.pivotBranch - 1, 12), pivot: natal.pivotBranch), .siblings)
    }

    func testYearLayerUsesYearBranchAndStem() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let layer = chart.timeLayer(kind: .year, year: 2026, on: date(2026, 11, 8))
        XCTAssertEqual(layer.pivotBranch, Ganzhi.mod(2026 - 4, 12)) // 午
        XCTAssertEqual(layer.stemIndex, Ganzhi.mod(2026 - 4, 10))   // 丙
        XCTAssertEqual(layer.title, "2026 丙午年")
        XCTAssertEqual(layer.transformations.map(\.source), Array(repeating: .year, count: 4))
        XCTAssertEqual(chart.palaceKind(at: layer.pivotBranch, pivot: layer.pivotBranch), .life)
    }

    func testDecadeLayerUsesPalaceStemForTransformations() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let slots = chart.decades()
        XCTAssertEqual(slots.count, 12)
        for slot in slots {
            let layer = chart.timeLayer(kind: .decade, decadeIndex: slot.index, on: date(2026, 11, 8))
            let palace = chart.palace(at: slot.branch)
            XCTAssertEqual(layer.stemIndex, palace.stemIndex)
            XCTAssertEqual(layer.decade, slot)
            XCTAssertEqual(layer.transformations.map(\.source), Array(repeating: .decade, count: 4))
        }
    }

    func testCurrentDecadeContainsNominalAge() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let age = chart.nominalAge(on: date(2026, 11, 8))
        XCTAssertEqual(age, 37)
        let index = chart.currentDecadeIndex(age: age)
        let slot = chart.decades()[index]
        XCTAssertTrue(slot.contains(age: age))
    }

    func testTriadReturnsFourDistinctBranches() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        for branch in 0..<12 {
            let triad = chart.triad(of: branch)
            XCTAssertEqual(triad.count, 4)
            XCTAssertEqual(Set(triad).count, 4)
            XCTAssertEqual(triad, [branch, Ganzhi.mod(branch + 4, 12), Ganzhi.mod(branch + 8, 12), Ganzhi.mod(branch + 6, 12)])
            // 前三个为三合（同属一个三合局），第四个为对宫
            XCTAssertEqual(Set(triad.prefix(3).map { $0 % 4 }).count, 1, "三合宫应同局")
            XCTAssertEqual(triad[3], Ganzhi.mod(branch + 6, 12), "第四位应为对宫")
        }
    }

    func testInsightsAreDeterministicAndComplete() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let layer = chart.timeLayer(kind: .natal, on: date(2026, 11, 8))
        let first = InsightEngine.insights(for: chart, layer: layer)
        let second = InsightEngine.insights(for: chart, layer: layer)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.count, 6)
        XCTAssertEqual(first.map(\.topic), InsightTopic.allCases)
        for insight in first {
            XCTAssertFalse(insight.headline.isEmpty)
            XCTAssertGreaterThanOrEqual(insight.blocks.count, 3)
            XCTAssertTrue(insight.blocks.allSatisfy { !$0.body.isEmpty })
        }
    }

    func testInsightsChangeWithTimeLayer() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let natal = InsightEngine.insights(for: chart, layer: chart.timeLayer(kind: .natal, on: date(2026, 11, 8)))
        let decade = InsightEngine.insights(for: chart, layer: chart.timeLayer(kind: .decade, on: date(2026, 11, 8)))
        XCTAssertNotEqual(natal[0].headline, decade[0].headline)
    }
}
