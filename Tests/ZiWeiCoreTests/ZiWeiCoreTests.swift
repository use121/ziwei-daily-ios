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
        solar.adjustForDaylightSaving = false
        let solarResolved = ChartEngine.resolveBirth(solar, timeZone: timeZone)
        XCTAssertNotEqual(solarResolved.correctionMinutes, 0)

        var lateZi = input(date(1990, 5, 15, 23, 10))
        lateZi.lateZiNextDay = true
        lateZi.adjustForDaylightSaving = false
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
        XCTAssertEqual(first.count, 14)
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

    // MARK: - v1.2 扩星与格局

    func testAuxiliaryStarInvariants() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let lu = chart.branch(of: .luCun)!
        XCTAssertEqual(chart.branch(of: .qingYang), Ganzhi.mod(lu + 1, 12))
        XCTAssertEqual(chart.branch(of: .tuoLuo), Ganzhi.mod(lu - 1, 12))

        let luan = chart.branch(of: .hongLuan)!
        XCTAssertEqual(chart.branch(of: .tianXi), Ganzhi.mod(luan + 6, 12))

        let allAux: [Star] = [
            .wenChang, .wenQu, .zuoFu, .youBi, .tianKui, .tianYue, .luCun,
            .qingYang, .tuoLuo, .diKong, .diJie, .tianMa, .hongLuan, .tianXi,
            .huoXing, .lingXing, .tianYao, .tianXing, .sanTai, .baZuo,
            .enGuang, .tianGui, .longChi, .fengGe, .tianKu, .tianXu,
            .tianShang, .tianShi
        ]
        for star in allAux {
            let branch = chart.branch(of: star)
            XCTAssertNotNil(branch, "\(star.rawValue) 未安星")
            XCTAssertTrue((0..<12).contains(branch ?? -1), "\(star.rawValue) 落宫越界")
        }

        // 天伤居交友，天使居疾厄
        XCTAssertEqual(chart.branch(of: .tianShang), Ganzhi.mod(chart.lifeBranch - 7, 12))
        XCTAssertEqual(chart.branch(of: .tianShi), Ganzhi.mod(chart.lifeBranch - 5, 12))
    }

    func testSoulAndBodyMaster() {
        let souls: [Star] = [.tanLang, .juMen, .luCun, .wenQu, .lianZhen, .wuQu,
                             .poJun, .wuQu, .lianZhen, .wenQu, .luCun, .juMen]
        for branch in 0..<12 {
            XCTAssertEqual(SoulBody.soulMaster(lifeBranch: branch), souls[branch])
        }
        // 身主六星循环
        for branch in 0..<12 {
            XCTAssertEqual(SoulBody.bodyMaster(yearBranch: branch), SoulBody.bodyMaster(yearBranch: branch % 6))
        }
        XCTAssertEqual(SoulBody.bodyMaster(yearBranch: 0), .huoXing)
    }

    func testDoctoralTwelve() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let sequence = chart.doctoralSequence
        XCTAssertEqual(sequence.count, 12)
        XCTAssertEqual(Set(sequence.values).count, 12)
        XCTAssertEqual(sequence[chart.luCunBranch], "博士")
    }

    func testPatternsAreDeterministic() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        for kind in TimeLayerKind.allCases {
            let layer = chart.timeLayer(kind: kind, month: 6, on: date(2026, 11, 8))
            let first = PatternEngine.patterns(for: chart, layer: layer)
            let second = PatternEngine.patterns(for: chart, layer: layer)
            XCTAssertEqual(first, second)
            for pattern in first {
                XCTAssertFalse(pattern.name.isEmpty)
                XCTAssertFalse(pattern.summary.isEmpty)
                XCTAssertFalse(pattern.detail.isEmpty)
                XCTAssertFalse(pattern.branchText.isEmpty)
            }
        }
    }

    func testTransformEntriesAlwaysFour() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        for kind in TimeLayerKind.allCases {
            let layer = chart.timeLayer(kind: kind, month: 6, on: date(2026, 11, 8))
            let entries = TransformationPathEngine.entries(chart: chart, layer: layer)
            XCTAssertEqual(entries.count, 4, "\(kind.rawValue)层四化数量应为 4")
            XCTAssertEqual(Set(entries.map(\.kind)), Set(TransformationKind.allCases))
            XCTAssertFalse(TransformationPathEngine.summary(chart: chart, layer: layer).isEmpty)
        }
    }

    func testMonthLayerCoversTwelveBranches() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        var pivots: Set<Int> = []
        for month in 1...12 {
            let layer = chart.timeLayer(kind: .month, year: 2026, month: month, on: date(2026, 11, 8))
            XCTAssertEqual(layer.lunarMonth, month)
            XCTAssertEqual(layer.transformations.count, 4)
            pivots.insert(layer.pivotBranch)
        }
        XCTAssertEqual(pivots.count, 12, "十二个月应落在十二个不同命宫")
    }

    func testTopicScoresInRange() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let layer = chart.timeLayer(kind: .natal, on: date(2026, 11, 8))
        let scores = TopicScoreEngine.scores(chart: chart, layer: layer)
        XCTAssertEqual(scores.count, 14)
        for item in scores {
            XCTAssertGreaterThanOrEqual(item.score, 38)
            XCTAssertLessThanOrEqual(item.score, 97)
        }
        XCTAssertEqual(TopicScoreEngine.scores(chart: chart, layer: layer), scores)
    }

    func testPatternsAcrossSamples() throws {
        var total = 0
        var names: Set<String> = []
        for year in [1972, 1983, 1990, 1996, 2003, 2011] {
            for month in [2, 7, 11] {
                let chart = try ChartEngine.makeChart(
                    from: input(date(year, month, 12, 14)),
                    referenceDate: date(2026, 11, 8)
                )
                let layer = chart.timeLayer(kind: .natal, on: date(2026, 11, 8))
                let patterns = PatternEngine.patterns(for: chart, layer: layer)
                total += patterns.count
                names.formUnion(patterns.map(\.name))
            }
        }
        XCTAssertGreaterThan(total, 0, "样本盘中应至少命中若干格局")
        XCTAssertGreaterThanOrEqual(names.count, 3, "格局类型应有足够多样性")
    }

    func testFourteenTopicsHaveContent() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let layer = chart.timeLayer(kind: .year, year: 2026, on: date(2026, 11, 8))
        let insights = InsightEngine.insights(for: chart, layer: layer)
        XCTAssertEqual(insights.count, InsightTopic.allCases.count)
        XCTAssertEqual(InsightTopic.core.count, 6)
        for insight in insights {
            XCTAssertFalse(insight.headline.isEmpty)
            XCTAssertGreaterThanOrEqual(insight.blocks.count, 3)
            XCTAssertTrue(insight.blocks.allSatisfy { !$0.body.isEmpty })
        }
    }

    // MARK: - 贵人分析

    func testBenefactorInsightContent() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let layer = chart.timeLayer(kind: .natal, on: date(2026, 11, 8))
        let insights = InsightEngine.insights(for: chart, layer: layer)
        let guiren = insights.first { $0.topic == .guiren }!
        // 魁钺必然上盘，贵人星至少七颗里出现五颗以上（魁钺辅弼禄存恒有）
        XCTAssertGreaterThanOrEqual(guiren.keyStars.count, 5)
        XCTAssertTrue(guiren.keyStars.contains(.tianKui))
        XCTAssertTrue(guiren.keyStars.contains(.tianYue))
        XCTAssertTrue(guiren.headline.contains("天魁"))
        XCTAssertTrue(guiren.headline.contains("天钺"))
        // 四段式：格局 / 来源 / 借力 / 引动
        XCTAssertEqual(guiren.blocks.map(\.heading), ["贵人格局", "贵人来源", "借力方式", "\(layer.kind.rawValue)引动"])
        for block in guiren.blocks {
            XCTAssertFalse(block.body.isEmpty)
        }
        // 贵人运评分在合法区间且确定性
        let scores = TopicScoreEngine.scores(chart: chart, layer: layer)
        let guirenScore = scores.first { $0.topic == .guiren }!
        XCTAssertGreaterThanOrEqual(guirenScore.score, 38)
        XCTAssertLessThanOrEqual(guirenScore.score, 97)
        // 换流年层，贵人来源宫位随时间层旋转
        let yearLayer = chart.timeLayer(kind: .year, year: 2027, on: date(2026, 11, 8))
        let yearInsights = InsightEngine.insights(for: chart, layer: yearLayer)
        let yearGuiren = yearInsights.first { $0.topic == .guiren }!
        XCTAssertFalse(yearGuiren.headline.isEmpty)
    }

    // MARK: - P2 内核

    func testLongevityStartBranches() {
        XCTAssertEqual(LongevityTwelve.startBranch(bureau: .water), 8)
        XCTAssertEqual(LongevityTwelve.startBranch(bureau: .wood), 11)
        XCTAssertEqual(LongevityTwelve.startBranch(bureau: .metal), 5)
        XCTAssertEqual(LongevityTwelve.startBranch(bureau: .earth), 8)
        XCTAssertEqual(LongevityTwelve.startBranch(bureau: .fire), 2)
    }

    func testLongevitySequenceCoversAllBranches() {
        for bureau in Element.allCases {
            for forward in [true, false] {
                let seq = LongevityTwelve.sequence(bureau: bureau, isForward: forward)
                XCTAssertEqual(seq.count, 12)
                XCTAssertEqual(Set(seq.values).count, 12, "十二神不应重复")
                XCTAssertEqual(seq[LongevityTwelve.startBranch(bureau: bureau)], "长生")
            }
        }
    }

    func testMinorLimitRule() {
        // 寅午戌起辰、申子辰起戌、巳酉丑起未、亥卯未起丑
        XCTAssertEqual(MinorLimit.startBranch(yearBranch: 2), 4)
        XCTAssertEqual(MinorLimit.startBranch(yearBranch: 0), 10)
        XCTAssertEqual(MinorLimit.startBranch(yearBranch: 9), 7)
        XCTAssertEqual(MinorLimit.startBranch(yearBranch: 3), 1)
        // 男顺：一岁起宫，五岁前进四宫；女逆
        XCTAssertEqual(MinorLimit.branch(yearBranch: 2, nominalAge: 5, isMale: true), 8)
        XCTAssertEqual(MinorLimit.branch(yearBranch: 2, nominalAge: 5, isMale: false), 0)
        XCTAssertEqual(MinorLimit.branch(yearBranch: 2, nominalAge: 1, isMale: true), 4)
    }

    func testSelfTransformationsSubsetOfFlying() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let flying = chart.flyingTransformations
        XCTAssertEqual(flying.count, 48, "十二宫各飞四化，共 48 条")
        let selfT = chart.selfTransformations
        for item in selfT {
            XCTAssertEqual(item.branch, chart.branch(of: item.star), "自化的星必须落回本宫")
        }
        XCTAssertEqual(selfT.count, flying.filter(\.isSelfTransformation).count)
        // 每个宫干飞出的四化必能找到落点
        for palace in chart.palaces {
            XCTAssertEqual(chart.flyingTransformations(from: palace.branchIndex).count, 4)
        }
    }

    func testDayLayerGanzhiAndPivot() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let target = date(2026, 11, 8)
        let layer = chart.timeLayer(kind: .day, on: target)
        let expectedIndex = Ganzhi.dayIndex(year: 2026, month: 11, day: 8)
        XCTAssertEqual(layer.stemIndex, expectedIndex % 10)
        XCTAssertEqual(layer.title, "\(Ganzhi.string(expectedIndex))日")
        let lunar = ChineseCalendarConverter.lunarDate(from: target, timeZone: timeZone)
        XCTAssertEqual(layer.pivotBranch, Ganzhi.mod(lunar.yearBranch + lunar.month - 1 + lunar.day - 1, 12))
        XCTAssertEqual(layer.transformations.count, 4)
    }

    func testHourLayerStemAndPivot() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30)), referenceDate: date(2026, 11, 8))
        let target = date(2026, 11, 8, 9)
        let layer = chart.timeLayer(kind: .hour, on: target)
        // 巳时 = 5
        XCTAssertEqual(layer.hourBranch, 5)
        let dayStem = Ganzhi.dayIndex(year: 2026, month: 11, day: 8) % 10
        let ziStem = Ganzhi.mod((dayStem % 5) * 2, 10)
        XCTAssertEqual(layer.stemIndex, Ganzhi.mod(ziStem + 5, 10))
        let dayLayer = chart.timeLayer(kind: .day, on: target)
        XCTAssertEqual(layer.pivotBranch, Ganzhi.mod(dayLayer.pivotBranch + 5, 12))
        XCTAssertEqual(layer.transformations.count, 4)
        // 十二时支流时命宫应覆盖十二宫
        let pivots = Set((0..<12).map { chart.timeLayer(kind: .hour, hour: $0, on: target).pivotBranch })
        XCTAssertEqual(pivots.count, 12)
    }

    func testChinaDaylightSavingWindow() {
        XCTAssertTrue(ChartEngine.isChinaDaylightSaving(date(1990, 6, 15), timeZone: timeZone))
        XCTAssertTrue(ChartEngine.isChinaDaylightSaving(date(1986, 5, 4), timeZone: timeZone))
        XCTAssertFalse(ChartEngine.isChinaDaylightSaving(date(1986, 5, 3), timeZone: timeZone))
        XCTAssertFalse(ChartEngine.isChinaDaylightSaving(date(1991, 9, 16), timeZone: timeZone))
        XCTAssertFalse(ChartEngine.isChinaDaylightSaving(date(1992, 6, 15), timeZone: timeZone))
        XCTAssertFalse(ChartEngine.isChinaDaylightSaving(date(1990, 6, 15), timeZone: TimeZone(identifier: "Asia/Tokyo")!))
    }

    func testDaylightSavingAffectsHourBranch() throws {
        // 1989-08-01 00:30 北京夏令时 → 校正后为前一日 23:30，时支从子变子但日期前移一天；
        // 选一个时辰边界点：09:30 夏令时 → 实际 08:30，辰时而非巳时
        var sample = input(date(1989, 8, 1, 9, 30))
        sample.adjustForDaylightSaving = true
        let corrected = try ChartEngine.makeChart(from: sample, referenceDate: date(2026, 11, 8))
        XCTAssertEqual(corrected.resolvedBirth.hourBranch, 4, "夏令时校正后应为辰时")
        sample.adjustForDaylightSaving = false
        let raw = try ChartEngine.makeChart(from: sample, referenceDate: date(2026, 11, 8))
        XCTAssertEqual(raw.resolvedBirth.hourBranch, 5, "不校正则为巳时")
    }

    func testLeapMonthModes() {
        let leap = LunarDate(gregorianYear: 2020, sexagenaryYear: 37, month: 4, day: 16, isLeapMonth: true)
        XCTAssertEqual(ChartEngine.effectiveMonth(lunar: leap, mode: .current), 4)
        XCTAssertEqual(ChartEngine.effectiveMonth(lunar: leap, mode: .nextMonth), 5)
        XCTAssertEqual(ChartEngine.effectiveMonth(lunar: leap, mode: .splitHalf), 5)
        XCTAssertEqual(ChartEngine.effectiveMonth(lunar: leap, mode: .splitAccumulate), 5)
        let early = LunarDate(gregorianYear: 2020, sexagenaryYear: 37, month: 4, day: 10, isLeapMonth: true)
        XCTAssertEqual(ChartEngine.effectiveMonth(lunar: early, mode: .splitHalf), 4)
        // 非闰月不受影响
        let normal = LunarDate(gregorianYear: 2020, sexagenaryYear: 37, month: 4, day: 20, isLeapMonth: false)
        for mode in LeapMonthMode.allCases {
            XCTAssertEqual(ChartEngine.effectiveMonth(lunar: normal, mode: mode), 4)
        }
    }

    func testLeapMonthModeChangesWholeChart() throws {
        // 2020-06-01 为农历闰四月初十
        let birth = date(2020, 6, 1, 10)
        let lunar = ChineseCalendarConverter.lunarDate(from: birth, timeZone: timeZone)
        XCTAssertTrue(lunar.isLeapMonth, "该日期应落在闰月，实际：\(lunar.displayText)")

        var current = input(birth)
        current.leapMonthMode = .current
        var next = input(birth)
        next.leapMonthMode = .nextMonth
        var splitHalf = input(birth)
        splitHalf.leapMonthMode = .splitHalf

        let chartCurrent = try ChartEngine.makeChart(from: current, referenceDate: date(2026, 11, 8))
        let chartNext = try ChartEngine.makeChart(from: next, referenceDate: date(2026, 11, 8))
        let chartSplit = try ChartEngine.makeChart(from: splitHalf, referenceDate: date(2026, 11, 8))

        // 初十在十五之前：十五为界口径应与「当本月」一致
        XCTAssertEqual(chartCurrent.lifeBranch, chartSplit.lifeBranch)
        // 作下月则命宫整体前移一宫
        XCTAssertEqual(chartNext.lifeBranch, Ganzhi.mod(chartCurrent.lifeBranch + 1, 12))
        XCTAssertNotEqual(chartNext.palace(.life).mainStars, chartCurrent.palace(.life).mainStars)
    }

    /// 综合分必须由四项推出来：否则会出现「总分 75、四项最高 77」这类互相矛盾的数字
    func testOverallScoreIsAverageOfDimensions() throws {
        let births = [date(1990, 6, 15, 9, 30), date(1985, 2, 3, 22), date(1998, 11, 20, 4), date(1972, 7, 8, 14)]
        for birth in births {
            let chart = try ChartEngine.makeChart(from: input(birth), referenceDate: date(2026, 11, 8))
            for offset in [0, 1, 7, 33, 180] {
                let day = date(2026, 11, 8).addingTimeInterval(TimeInterval(offset * 86_400))
                let report = FortuneEngine.report(for: chart, on: day)
                let scores = report.dimensions.map(\.score)
                XCTAssertEqual(report.dimensions.count, 4)
                XCTAssertTrue(scores.allSatisfy { $0 >= 0 && $0 <= 100 })
                let average = Int((Double(scores.reduce(0, +)) / Double(scores.count)).rounded())
                XCTAssertEqual(report.score, average, "综合分应等于四项平均")
                XCTAssertEqual(report.dimensions.map(\.title), ["事业", "财务", "人际", "身心"])
                // 小字里引用的分数必须与分项卡一致
                XCTAssertTrue(report.highlights[0].contains("\(scores.max()!) 分"))
                XCTAssertTrue(report.summary.contains(scores.min()!.description))
            }
        }
    }

    func testClassicLibraryIntegrity() {
        XCTAssertFalse(ClassicLibrary.quotes.isEmpty)
        for quote in ClassicLibrary.quotes {
            XCTAssertFalse(quote.original.isEmpty)
            XCTAssertFalse(quote.plain.isEmpty)
            XCTAssertTrue(quote.source.contains("赋") || quote.source.contains("全书"))
        }
        XCTAssertNotNil(ClassicLibrary.quote(for: "紫府同宫"))
        XCTAssertNil(ClassicLibrary.quote(for: "不存在的格局"))
    }

    // MARK: - 一生运程

    func testLifeTimelineCoversTwelveStages() throws {
        let reference = date(2026, 11, 8)
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30), gender: .female), referenceDate: reference)
        let overview = LifeTimelineEngine.overview(for: chart, referenceDate: reference)

        XCTAssertEqual(overview.stages.count, 12)
        XCTAssertEqual(Set(overview.stages.map(\.branch)).count, 12, "十二大限各占一宫，不应重复")
        XCTAssertEqual(overview.stages.filter(\.isCurrent).count, 1)

        for (previous, next) in zip(overview.stages, overview.stages.dropFirst()) {
            XCTAssertEqual(next.startAge, previous.endAge + 1, "大限年龄应连续")
            XCTAssertEqual(next.startYear, previous.endYear + 1, "对应的公历年份应连续")
        }

        let age = chart.nominalAge(on: reference)
        let current = overview.current!
        XCTAssertTrue(current.startAge <= age && age <= current.endAge)
        XCTAssertEqual(current.index, overview.currentStageIndex)

        for stage in overview.stages {
            XCTAssertFalse(stage.themeLine.isEmpty)
            XCTAssertFalse(stage.career.isEmpty)
            XCTAssertFalse(stage.family.isEmpty)
            XCTAssertFalse(stage.parents.isEmpty)
            XCTAssertFalse(stage.health.isEmpty)
            XCTAssertTrue((42...93).contains(stage.score), "阶段评分应在合法区间")
            XCTAssertFalse(stage.milestones.isEmpty, "每十年至少有流年归位可标")
            XCTAssertGreaterThan(stage.endYear, stage.startYear)
        }

        // 同一张盘、同一天，结果必须完全一致
        let again = LifeTimelineEngine.overview(for: chart, referenceDate: reference)
        XCTAssertEqual(overview, again)

        // 当前阶段的三条提醒：主线 / 四化落点 / 未来三年
        XCTAssertEqual(overview.currentFocus.count, 3)
        XCTAssertTrue(overview.currentFocus[0].contains(current.title))
        XCTAssertTrue(overview.currentFocus[2].contains("未来三年"))

        // 关键年份至少含当前与未来两个大限，且都带正文
        XCTAssertFalse(overview.keyNodes.isEmpty)
        for node in overview.keyNodes {
            XCTAssertFalse(node.title.isEmpty)
            XCTAssertFalse(node.detail.isEmpty)
            XCTAssertGreaterThanOrEqual(node.age, 1)
        }
        XCTAssertTrue(overview.keyNodes.contains { $0.kind == .opening })
        XCTAssertTrue(overview.keyNodes.contains { $0.kind == .caution })
    }

    func testLifeTimelineBestAndHardestStage() throws {
        let reference = date(2026, 11, 8)
        let chart = try ChartEngine.makeChart(from: input(date(1985, 3, 2, 15)), referenceDate: reference)
        let overview = LifeTimelineEngine.overview(for: chart, referenceDate: reference)

        let best = overview.bestStage!
        let hardest = overview.hardestStage!
        XCTAssertEqual(best.score, overview.stages.map(\.score).max()!)
        XCTAssertEqual(hardest.score, overview.stages.map(\.score).min()!)
        XCTAssertGreaterThanOrEqual(best.score, hardest.score)
        XCTAssertTrue(overview.headline.contains(best.title))
        XCTAssertTrue(overview.arc.contains("平均"))
    }

    func testCurrentStageFollowsReferenceDate() throws {
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30), gender: .female), referenceDate: date(2026, 11, 8))
        let at30 = LifeTimelineEngine.overview(for: chart, referenceDate: date(2019, 6, 15))
        let at50 = LifeTimelineEngine.overview(for: chart, referenceDate: date(2039, 6, 15))
        XCTAssertNotEqual(at30.currentStageIndex, at50.currentStageIndex)
        XCTAssertLessThan(at30.currentStageIndex, at50.currentStageIndex, "年纪越大，所处大限应越靠后")
        // 十二运程本身不随查看日期改变，只有「当前」标记会移
        let strip: (LifeStage) -> LifeStage = { stage in
            LifeStage(
                index: stage.index, startAge: stage.startAge, endAge: stage.endAge,
                startYear: stage.startYear, endYear: stage.endYear, branch: stage.branch,
                natalKind: stage.natalKind, ganzhi: stage.ganzhi, stars: stage.stars,
                title: stage.title, themeLine: stage.themeLine, score: stage.score, tone: stage.tone,
                career: stage.career, family: stage.family, parents: stage.parents,
                health: stage.health, milestones: stage.milestones, isCurrent: false
            )
        }
        XCTAssertEqual(at30.stages.map(strip), at50.stages.map(strip), "换参考日期不应改变十二运程本身，只改当前位置")
        XCTAssertEqual(at30.currentStageIndex, chart.currentDecadeIndex(age: chart.nominalAge(on: date(2019, 6, 15))))
    }

    func testLifeStageTextIsWellFormed() throws {
        let reference = date(2026, 11, 8)
        for (month, hour) in [(3, 8), (7, 14), (11, 20)] {
            let chart = try ChartEngine.makeChart(from: input(date(1988, month, 9, hour)), referenceDate: reference)
            let overview = LifeTimelineEngine.overview(for: chart, referenceDate: reference)

            // 十二限各落一宫，标题必然互不相同
            XCTAssertEqual(Set(overview.stages.map(\.title)).count, 12)
            XCTAssertEqual(Set(overview.stages.map(\.natalKind)).count, 12)

            for stage in overview.stages {
                let text = stage.themeLine + stage.career + stage.family + stage.parents + stage.health
                XCTAssertFalse(text.contains("宫宫"), "出现叠字：\(stage.themeLine)")
                XCTAssertFalse(text.contains("命命"), "出现叠字：\(stage.themeLine)")
                XCTAssertFalse(text.contains("。。"), "出现双句号")
                XCTAssertFalse(text.contains("；。"), "出现分号接句号")
                XCTAssertFalse(text.contains("  "), "出现连续空格")
            }
            for line in overview.currentFocus {
                XCTAssertFalse(line.isEmpty)
                XCTAssertFalse(line.contains("宫宫"))
            }
        }
    }

    // MARK: - 同盘古人

    func testHistoricalFigureLibraryIntegrity() {
        XCTAssertGreaterThanOrEqual(HistoricalFigures.all.count, 30)
        XCTAssertEqual(Set(HistoricalFigures.all.map(\.id)).count, HistoricalFigures.all.count, "人物 id 不应重复")
        let combos = HistoricalFigures.all.map { Set($0.stars) }
        XCTAssertEqual(Set(combos.map { $0.map(\.rawValue).sorted().joined(separator: "+") }).count, combos.count, "每个主星组合只应对应一位人物")
        for figure in HistoricalFigures.all {
            XCTAssertFalse(figure.stars.isEmpty)
            XCTAssertFalse(figure.name.isEmpty)
            XCTAssertFalse(figure.era.isEmpty)
            XCTAssertGreaterThan(figure.story.count, 20)
            XCTAssertGreaterThan(figure.resonance.count, 15)
            XCTAssertGreaterThan(figure.lesson.count, 10)
        }
        XCTAssertFalse(HistoricalFigures.disclaimer.isEmpty)
    }

    func testHistoricalFigureMatching() throws {
        let reference = date(2026, 11, 8)
        let chart = try ChartEngine.makeChart(from: input(date(1990, 6, 15, 9, 30), gender: .female), referenceDate: reference)
        let matches = HistoricalFigures.matches(for: chart)
        XCTAssertFalse(matches.isEmpty)
        XCTAssertLessThanOrEqual(matches.count, 2)

        let lifeStars = Set(chart.palace(at: chart.lifeBranch).mainStars)
        for match in matches {
            XCTAssertFalse(match.figure.story.isEmpty)
            XCTAssertFalse(match.sharedStars.isEmpty)
            XCTAssertTrue(Set(match.sharedStars).isSubset(of: Set(match.figure.stars)))
            if match.kind == .sameCombo {
                XCTAssertEqual(Set(match.figure.stars), lifeStars)
            } else {
                XCTAssertFalse(Set(match.figure.stars).isDisjoint(with: lifeStars))
            }
        }
        XCTAssertEqual(HistoricalFigures.matches(for: chart), matches, "同一张盘应匹配到固定的人物")
    }

    func testHistoricalFigureCoversEveryStarCombination() throws {
        // 遍历多个生日，命宫主星组合都应能在人物库里找到同宫或同星的对照
        for month in [1, 4, 7, 10] {
            for hour in [2, 9, 15, 21] {
                let chart = try ChartEngine.makeChart(from: input(date(1992, month, 12, hour)), referenceDate: date(2026, 11, 8))
                let matches = HistoricalFigures.matches(for: chart)
                XCTAssertFalse(matches.isEmpty, "命宫 \(chart.palace(at: chart.lifeBranch).mainStars) 未匹配到人物")
            }
        }
    }

    // MARK: - 小六壬

    func testLiuRenMonthCountsFromDaAn() {
        // 正月起大安，月份几就数几位，起点那一宫算第一位
        XCTAssertEqual(LiuRenEngine.palaces(lunarMonth: 1, lunarDay: 1, hourBranch: 0).month, .daAn)
        XCTAssertEqual(LiuRenEngine.palaces(lunarMonth: 6, lunarDay: 1, hourBranch: 0).month, .kongWang)
        XCTAssertEqual(LiuRenEngine.palaces(lunarMonth: 7, lunarDay: 1, hourBranch: 0).month, .daAn, "数满六位回到大安")
        XCTAssertEqual(LiuRenEngine.palaces(lunarMonth: 9, lunarDay: 1, hourBranch: 0).month, .suXi)
    }

    func testLiuRenDayStartsFromMonthPalace() {
        // 日从月落之宫起初一
        let first = LiuRenEngine.palaces(lunarMonth: 1, lunarDay: 1, hourBranch: 0)
        XCTAssertEqual(first.day, first.month)

        let second = LiuRenEngine.palaces(lunarMonth: 1, lunarDay: 2, hourBranch: 0)
        XCTAssertEqual(second.day, .liuLian)

        // 月落空亡（第 6 位），初一仍在空亡
        let fromKong = LiuRenEngine.palaces(lunarMonth: 6, lunarDay: 1, hourBranch: 0)
        XCTAssertEqual(fromKong.month, .kongWang)
        XCTAssertEqual(fromKong.day, .kongWang)
        // 空亡之后初二回到大安
        XCTAssertEqual(LiuRenEngine.palaces(lunarMonth: 6, lunarDay: 2, hourBranch: 0).day, .daAn)
    }

    func testLiuRenHourStartsFromDayPalace() {
        // 从日落之宫起子时，子一丑二
        let result = LiuRenEngine.palaces(lunarMonth: 3, lunarDay: 15, hourBranch: 0)
        XCTAssertEqual(result.hour, result.day, "子时落在日本身")

        let next = LiuRenEngine.palaces(lunarMonth: 3, lunarDay: 15, hourBranch: 1)
        XCTAssertEqual(next.hour.rawValue, (result.day.rawValue + 1) % 6)

        // 亥时是第 12 位，向前 11 位
        let hai = LiuRenEngine.palaces(lunarMonth: 3, lunarDay: 15, hourBranch: 11)
        XCTAssertEqual(hai.hour.rawValue, (result.day.rawValue + 11) % 6)
    }

    func testLiuRenVerdictUsesHourPalace() {
        let cast = LiuRenEngine.cast(on: date(2026, 11, 8, 14, 30))
        XCTAssertEqual(cast.verdictPalace, cast.hourPalace)
        XCTAssertEqual(cast.hourBranch, 7, "14:30 为未时")
        XCTAssertEqual(cast.monthPalace, LiuRenPalace(rawValue: (cast.lunarMonth - 1) % 6))
    }

    func testLiuRenCastIsDeterministic() {
        let moment = date(2026, 3, 3, 21, 5)
        let a = LiuRenEngine.cast(on: moment)
        let b = LiuRenEngine.cast(on: moment)
        XCTAssertEqual(a, b, "同一时刻起课结果必须一致")
    }

    func testLiuRenStepsDescribeTheSamePath() {
        let cast = LiuRenEngine.cast(on: date(2026, 5, 20, 10, 0))
        let steps = cast.steps
        XCTAssertEqual(steps.count, 3)
        XCTAssertEqual(steps[0].from, .daAn)
        XCTAssertEqual(steps[0].to, cast.monthPalace)
        XCTAssertEqual(steps[1].from, cast.monthPalace)
        XCTAssertEqual(steps[1].to, cast.dayPalace)
        XCTAssertEqual(steps[2].from, cast.dayPalace)
        XCTAssertEqual(steps[2].to, cast.hourPalace)
        XCTAssertEqual(steps[2].count, cast.hourBranch + 1)
        for step in steps {
            XCTAssertFalse(step.line.isEmpty)
        }
    }

    func testLiuRenPalaceLoreIsComplete() {
        for palace in LiuRenPalace.allCases {
            XCTAssertFalse(palace.gist.isEmpty)
            XCTAssertFalse(palace.counsel.isEmpty)
            XCTAssertFalse(palace.classic.isEmpty)
            XCTAssertFalse(palace.knuckle.isEmpty)
            XCTAssertFalse(palace.element.isEmpty)
            // 断辞、建议里不应出现绝对化的灾祸承诺
            for banned in ["必死", "必然破财", "必遭", "一定会"] {
                XCTAssertFalse(palace.counsel.contains(banned), "\(palace.name) 含绝对化措辞：\(banned)")
                XCTAssertFalse(palace.gist.contains(banned))
            }
        }
    }

    func testLiuRenThreeAuspiciousThreeNot() {
        XCTAssertEqual(LiuRenPalace.daAn.verdict, .auspicious)
        XCTAssertEqual(LiuRenPalace.suXi.verdict, .auspicious)
        XCTAssertEqual(LiuRenPalace.xiaoJi.verdict, .auspicious)
        XCTAssertEqual(LiuRenPalace.liuLian.verdict, .stalled)
        XCTAssertEqual(LiuRenPalace.chiKou.verdict, .inauspicious)
        XCTAssertEqual(LiuRenPalace.kongWang.verdict, .inauspicious)
    }

    func testChineseMonthAndDayNames() {
        XCTAssertEqual(ChineseMonthName.text(month: 1, isLeap: false), "正月")
        XCTAssertEqual(ChineseMonthName.text(month: 11, isLeap: false), "冬月")
        XCTAssertEqual(ChineseMonthName.text(month: 12, isLeap: false), "腊月")
        XCTAssertEqual(ChineseMonthName.text(month: 6, isLeap: true), "闰六月")
        XCTAssertEqual(ChineseDayName.text(day: 1), "初一")
        XCTAssertEqual(ChineseDayName.text(day: 10), "初十")
        XCTAssertEqual(ChineseDayName.text(day: 15), "十五")
        XCTAssertEqual(ChineseDayName.text(day: 23), "廿三")
        XCTAssertEqual(ChineseDayName.text(day: 30), "三十")
    }
}
