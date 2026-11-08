import SwiftUI
import ZiWeiCore

private struct BranchSelection: Identifiable {
    let branch: Int
    var id: Int { branch }
}

private struct PosterShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ChartView: View {
    @EnvironmentObject private var state: AppState
    @State private var selection: BranchSelection?
    @State private var posterShare: PosterShareItem?
    @State private var liuRenActive = false

    var body: some View {
        NavigationStack {
            if let chart = state.chart, let layer = state.currentLayer {
                ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(chart, layer: layer)

                        LayerSwitcher()
                            .ziWeiCard(padding: 14)

                        PalaceGrid(
                            chart: chart,
                            layer: layer,
                            selectedBranch: selection?.branch,
                            onSelect: { branch in
                                selection = BranchSelection(branch: branch)
                            }
                        )

                        HStack(spacing: 10) {
                            summaryItem("\(layer.kind.rawValue)命宫", Ganzhi.branches[layer.pivotBranch])
                            summaryItem("身宫", Ganzhi.branches[chart.bodyBranch])
                            summaryItem("五行局", chart.bureau.bureauName)
                        }

                        HStack(spacing: 10) {
                            summaryItem("命主", chart.soulMaster.rawValue)
                            summaryItem("身主", chart.bodyMaster.rawValue)
                            summaryItem("博士十二神", chart.doctoralSequence[layer.pivotBranch] ?? "—")
                        }

                        HStack(spacing: 10) {
                            summaryItem("小限（\(chart.nominalAge()) 岁）", Ganzhi.branches[chart.minorLimitBranch])
                            summaryItem("命宫长生", chart.longevitySequence[chart.lifeBranch] ?? "—")
                            summaryItem("自化", chart.selfTransformations.isEmpty ? "无" : "\(chart.selfTransformations.count) 处")
                        }

                        transformationCard(chart: chart, layer: layer)
                        patternCard(layer: layer)
                            .id("patterns")
                        infoCard(chart: chart, layer: layer)
                        palaceList(chart: chart, layer: layer)

                        CulturalDisclaimer()
                    }
                    .padding(18)
                    .padding(.bottom, 28)
                }
                #if DEBUG
                .onAppear {
                    if ProcessInfo.processInfo.environment["ZIWEI_SCROLL"] == "patterns" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            proxy.scrollTo("patterns", anchor: .top)
                        }
                    }
                }
                #endif
                }
                .background(Theme.paper)
                .navigationTitle("紫微命盘")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            LiuRenView()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "hand.point.up.left.fill")
                                    .font(.footnote)
                                Text("小六起卦")
                            }
                            .foregroundStyle(Theme.cinnabar)
                        }
                        .accessibilityLabel("小六起卦")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            exportPoster(chart: chart, layer: layer)
                        } label: {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundStyle(Theme.cinnabar)
                        }
                        .accessibilityLabel("导出长图")
                    }
                }
                .navigationDestination(isPresented: $liuRenActive) {
                    LiuRenView()
                }
                #if DEBUG
                .onAppear {
                    if ProcessInfo.processInfo.environment["ZIWEI_LIUREN"] == "1" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { liuRenActive = true }
                    }
                }
                #endif
                .sheet(item: $selection) { item in
                    PalaceDetailView(chart: chart, layer: layer, branch: item.branch)
                        .presentationBackground(Theme.paper)
                }
                .sheet(item: $posterShare) { item in
                    ActivityView(items: [item.image])
                        .presentationDetents([.medium, .large])
                }
                #if DEBUG
                .onAppear {
                    let detailEnv = ProcessInfo.processInfo.environment["ZIWEI_DETAIL"]
                    if detailEnv != nil, detailEnv != "0", selection == nil {
                        selection = BranchSelection(branch: layer.pivotBranch)
                    }
                    if ProcessInfo.processInfo.environment["ZIWEI_POSTER"] == "1",
                       let image = PosterExporter.render(chart: chart, layer: layer),
                       let data = image.pngData(),
                       let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        try? data.write(to: dir.appendingPathComponent("poster.png"))
                    }
                }
                #endif
            } else {
                EmptyStateView(
                    title: "命盘尚未生成",
                    message: "完成出生资料录入后，这里会展示十二宫、十四主星、亮度、四化与大限。",
                    buttonTitle: "去排盘"
                ) {
                    state.selectedTab = .input
                }
                .navigationTitle("紫微命盘")
            }
        }
    }

    // MARK: - 区块

    private func header(_ chart: Chart, layer: TimeLayer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(chartTitle(chart))
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("\(chart.resolvedBirth.lunarDate.displayText) · \(Ganzhi.branches[chart.resolvedBirth.hourBranch])时 · \(layer.kind.rawValue)视角")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func transformationCard(chart: Chart, layer: TimeLayer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(
                title: layer.kind == .natal ? "生年四化" : "\(layer.stemName)干四化",
                subtitle: layer.kind == .natal ? chart.resolvedBirth.lunarDate.yearGanzhi : layer.kind.rawValue
            )
            FlowLayout {
                ForEach(layer.transformations, id: \.star) { item in
                    let branch = chart.branch(of: item.star)
                    let name = branch.map { chart.palaceKind(at: $0, pivot: layer.pivotBranch).rawValue } ?? ""
                    TagPill(
                        text: "\(item.star.rawValue) \(item.kind.rawValue) · \(name)",
                        color: Theme.transformationColor(item.kind)
                    )
                }
            }
            if layer.kind != .natal {
                Text("同一颗星在不同时间层会有不同的四化标记，读盘时先确认当前看的是哪一层，不要把各层标记混成一条结论。")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
        .ziWeiCard()
    }

    @ViewBuilder
    private func patternCard(layer: TimeLayer) -> some View {
        let patterns = state.patterns
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(
                title: "格局",
                subtitle: patterns.isEmpty ? "\(layer.kind.rawValue)层未见经典格局" : "共 \(patterns.count) 组，按\u{201C}吉\u{201D}与\u{201C}留意\u{201D}分类"
            )
            if patterns.isEmpty {
                Text("这张盘的结构不属于常见成格组合，按十四主星与四化逐宫来看更准确。")
                    .font(.callout)
                    .foregroundStyle(Theme.secondaryInk)
            } else {
                ForEach(patterns) { pattern in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Text(pattern.name)
                                .font(.system(.subheadline, design: .serif, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            TagPill(text: pattern.kind.rawValue, color: patternColor(pattern.kind))
                            Spacer()
                            Text(pattern.branchText)
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryInk)
                        }
                        Text(pattern.summary)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                        if let quote = ClassicLibrary.quote(for: pattern.name) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("「\(quote.original)」")
                                        .font(.system(.caption, design: .serif))
                                        .foregroundStyle(Theme.cinnabar)
                                    Text(quote.source)
                                        .font(.caption2)
                                        .foregroundStyle(Theme.secondaryInk)
                                }
                                Text(quote.plain)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.secondaryInk)
                            }
                            .padding(9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.goldLight.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.vertical, 2)
                    if pattern.id != patterns.last?.id {
                        Divider().overlay(Theme.line.opacity(0.4))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func patternColor(_ kind: PatternKind) -> Color {
        switch kind {
        case .auspicious: Theme.jade
        case .neutral: Theme.gold
        case .caution: Theme.cinnabar
        }
    }

    private func infoCard(chart: Chart, layer: TimeLayer) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeading(title: "排盘信息", subtitle: chart.input.birthplace)
            infoRow("公历", birthText(chart))
            infoRow("农历", chart.resolvedBirth.lunarDate.displayText)
            infoRow("时辰", "\(Ganzhi.branches[chart.resolvedBirth.hourBranch])时（\(hourText(chart))）")
            infoRow("命主 / 身主", "\(chart.soulMaster.rawValue) / \(chart.bodyMaster.rawValue)")
            infoRow("大限", chart.isForwardDecade ? "顺行" : "逆行")
            infoRow("当前虚岁", "\(chart.nominalAge()) 岁")
            infoRow("小限", "\(Ganzhi.branches[chart.minorLimitBranch])宫（\(chart.palaceKind(at: chart.minorLimitBranch, pivot: chart.lifeBranch).rawValue)）")
            if let decade = layer.decade {
                infoRow("所选大限", decade.rangeText)
            }
            if chart.input.useTrueSolarTime {
                infoRow("真太阳时", "已校正 \(chart.resolvedBirth.correctionMinutes) 分钟")
            }
            if chart.resolvedBirth.appliedDaylightSaving {
                infoRow("夏令时", "出生时间处于 1986–1991 夏令时，已回拨 1 小时")
            }
            if chart.resolvedBirth.lunarDate.isLeapMonth {
                Text("闰月口径：\(chart.input.leapMonthMode.rawValue)。\(chart.input.leapMonthMode.note)。")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
        .ziWeiCard()
    }

    private func palaceList(chart: Chart, layer: TimeLayer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "十二宫详情", subtitle: "点按查看四段式解读")
            ForEach(0..<12, id: \.self) { branch in
                let palace = chart.palace(at: branch)
                let kind = chart.palaceKind(at: branch, pivot: layer.pivotBranch)
                Button {
                    selection = BranchSelection(branch: branch)
                } label: {
                    HStack(spacing: 12) {
                        Text(Ganzhi.branches[branch])
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Theme.cinnabar)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(kind.rawValue).font(.headline)
                                if palace.branchIndex == chart.bodyBranch {
                                    TagPill(text: "身宫", color: Theme.jade)
                                }
                                if kind == .life && layer.kind != .natal {
                                    TagPill(text: "\(layer.kind.rawValue)命宫", color: Theme.gold)
                                }
                            }
                            Text(starSummary(chart: chart, branch: branch))
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryInk)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(palace.decadeText)
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryInk)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.line)
                    }
                    .padding(13)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 小工具

    private func exportPoster(chart: Chart, layer: TimeLayer) {
        guard let image = PosterExporter.render(chart: chart, layer: layer) else { return }
        posterShare = PosterShareItem(image: image)
    }

    private func starSummary(chart: Chart, branch: Int) -> String {
        let palace = chart.palace(at: branch)
        guard !palace.mainStars.isEmpty else { return "空宫 · 借对宫星曜" }
        return palace.mainStars.map { star in
            let label = BrightnessCatalog.brightness(of: star, at: branch)?.label ?? ""
            return star.rawValue + label
        }.joined(separator: "、")
    }

    private func chartTitle(_ chart: Chart) -> String {
        let name = chart.input.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "本命十二宫" : "\(name)的十二宫"
    }

    private func summaryItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: 5) {
            Text(title).font(.caption).foregroundStyle(Theme.secondaryInk)
            Text(value).font(.system(.subheadline, design: .serif, weight: .semibold)).foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Theme.goldLight.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).font(.caption).foregroundStyle(Theme.secondaryInk).frame(width: 68, alignment: .leading)
            Text(value).font(.subheadline).foregroundStyle(Theme.ink)
            Spacer()
        }
    }

    private func birthText(_ chart: Chart) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: chart.input.timeZoneIdentifier)
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: chart.input.birthDate)
    }

    private func hourText(_ chart: Chart) -> String {
        let starts = ["23–01", "01–03", "03–05", "05–07", "07–09", "09–11", "11–13", "13–15", "15–17", "17–19", "19–21", "21–23"]
        return starts[chart.resolvedBirth.hourBranch]
    }
}

// MARK: - 十二宫方盘

private struct PalaceGrid: View {
    let chart: Chart
    let layer: TimeLayer
    let selectedBranch: Int?
    let onSelect: (Int) -> Void

    private let cells: [(row: Int, column: Int, branch: Int)] = [
        (0, 0, 5), (0, 1, 6), (0, 2, 7), (0, 3, 8),
        (1, 0, 4), (1, 3, 9),
        (2, 0, 3), (2, 3, 10),
        (3, 0, 2), (3, 1, 1), (3, 2, 0), (3, 3, 11)
    ]

    private var highlighted: Set<Int> {
        guard let selectedBranch else { return [] }
        return Set(chart.triad(of: selectedBranch))
    }

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width / 4
            ZStack {
                center
                    .frame(width: side * 2, height: side * 2)
                    .position(x: geometry.size.width / 2, y: geometry.size.width / 2)
                ForEach(cells, id: \.branch) { cell in
                    Button { onSelect(cell.branch) } label: {
                        palaceCell(branch: cell.branch)
                            .frame(width: side, height: side)
                    }
                    .buttonStyle(.plain)
                    .position(x: (CGFloat(cell.column) + 0.5) * side, y: (CGFloat(cell.row) + 0.5) * side)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Theme.gold, lineWidth: 1.2) }
        .accessibilityLabel("紫微斗数十二宫盘，点按宫位查看详情")
    }

    private var center: some View {
        VStack(spacing: 7) {
            Image(systemName: "sparkles").foregroundStyle(Theme.gold)
            Text(layer.title)
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
                .padding(.horizontal, 8)
            Text(chart.bureau.bureauName).font(.subheadline).foregroundStyle(Theme.cinnabar)
            Divider().padding(.horizontal, 26)
            Text("命在\(Ganzhi.branches[layer.pivotBranch]) · 身在\(Ganzhi.branches[chart.bodyBranch])")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
            if let decade = layer.decade {
                Text(decade.rangeText).font(.caption2).foregroundStyle(Theme.gold)
            }
        }
        .background(Theme.paper)
        .overlay { Rectangle().stroke(Theme.line, lineWidth: 0.7) }
    }

    private func palaceCell(branch: Int) -> some View {
        let palace = chart.palace(at: branch)
        let kind = chart.palaceKind(at: branch, pivot: layer.pivotBranch)
        let isSelected = selectedBranch == branch
        let isTriad = highlighted.contains(branch)
        let isLife = kind == .life

        let marks = layer.transformations.filter { chart.branch(of: $0.star) == branch }
        let selfMarks = chart.selfTransformations(at: branch)
        let longevity = chart.longevitySequence[branch]
        let isMinorLimit = branch == chart.minorLimitBranch

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(kind.rawValue)
                    .font(.system(size: 11, weight: isLife ? .bold : .semibold))
                    .foregroundStyle(isLife ? Theme.cinnabar : Theme.ink)
                if palace.branchIndex == chart.bodyBranch {
                    Text("身").font(.system(size: 8)).foregroundStyle(.white)
                        .padding(2).background(Theme.jade).clipShape(Circle())
                }
                if isMinorLimit {
                    Text("限").font(.system(size: 8)).foregroundStyle(.white)
                        .padding(2).background(Theme.gold).clipShape(Circle())
                }
                Spacer(minLength: 0)
                Text(Ganzhi.branches[branch]).font(.system(size: 9)).foregroundStyle(Theme.secondaryInk)
            }

            Spacer(minLength: 0)

            Text(mainStarText(chart: chart, branch: branch))
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(palace.mainStars.isEmpty ? Theme.secondaryInk : Theme.cinnabar)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            if !palace.auxiliaryStars.isEmpty {
                Text(palace.auxiliaryStars.prefix(3).map(\.rawValue).joined(separator: "·"))
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            HStack(spacing: 2) {
                ForEach(marks, id: \.star) { item in
                    Text(item.kind.rawValue.replacingOccurrences(of: "化", with: ""))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 13, height: 13)
                        .background(Theme.transformationColor(item.kind))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                ForEach(selfMarks) { item in
                    Text("自")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Theme.transformationColor(item.kind))
                        .frame(width: 13, height: 13)
                        .overlay {
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Theme.transformationColor(item.kind), lineWidth: 0.8)
                        }
                }
                Spacer(minLength: 0)
                if let longevity {
                    Text(longevity)
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.gold)
                }
                Text("\(palace.decadeStart)")
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
        .padding(5)
        .background(background(isSelected: isSelected, isTriad: isTriad, isLife: isLife))
        .overlay { Rectangle().stroke(Theme.line.opacity(0.8), lineWidth: 0.55) }
    }

    private func background(isSelected: Bool, isTriad: Bool, isLife: Bool) -> Color {
        if isSelected { return Theme.cinnabarLight }
        if isTriad { return Theme.goldLight.opacity(0.55) }
        if isLife { return Theme.cinnabarLight.opacity(0.35) }
        return Theme.card
    }

    private func mainStarText(chart: Chart, branch: Int) -> String {
        let palace = chart.palace(at: branch)
        guard !palace.mainStars.isEmpty else {
            let opposite = chart.palace(at: Ganzhi.mod(branch + 6, 12)).mainStars.map(\.rawValue).joined(separator: "·")
            return "空宫\n借\(opposite)"
        }
        return palace.mainStars.map { star in
            let label = BrightnessCatalog.brightness(of: star, at: branch)?.label ?? ""
            return star.rawValue + label
        }.joined(separator: "·")
    }
}

// MARK: - 宫位详情

private struct PalaceDetailView: View {
    let chart: Chart
    let layer: TimeLayer
    let branch: Int
    @Environment(\.dismiss) private var dismiss

    private var palace: Palace { chart.palace(at: branch) }
    private var kind: PalaceKind { chart.palaceKind(at: branch, pivot: layer.pivotBranch) }
    private var insight: Insight { InsightEngine.palaceInsight(for: chart, layer: layer, branch: branch) }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text("\(Ganzhi.branches[branch]) · \(kind.rawValue)")
                                .font(.system(.title2, design: .serif, weight: .semibold))
                                .foregroundStyle(Theme.cinnabar)
                            if palace.branchIndex == chart.bodyBranch {
                                TagPill(text: "身宫", color: Theme.jade)
                            }
                            if branch == chart.minorLimitBranch {
                                TagPill(text: "小限", color: Theme.gold)
                            }
                            if let longevity = chart.longevitySequence[branch] {
                                TagPill(text: longevity, color: Theme.azurite)
                            }
                        }
                        Text(kind.focus).font(.subheadline).foregroundStyle(Theme.secondaryInk)
                        HStack(spacing: 10) {
                            Text("大限 \(palace.decadeText)")
                            Text("宫干 \(Ganzhi.stems[palace.stemIndex])")
                            if layer.kind != .natal {
                                Text("\(layer.kind.rawValue)层")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Theme.gold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(insight.headline)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.goldLight.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    ForEach(insight.blocks) { block in
                        detailSection(block.heading) {
                            Text(block.body)
                        }
                    }

                    flyingSection
                        .id("flying")

                    if let longevity = chart.longevitySequence[branch] {
                        detailSection("长生十二神") {
                            Text("本宫逢「\(longevity)」。\(LongevityTwelve.note(longevity))。")
                        }
                    }

                    if !palace.auxiliaryStars.isEmpty {
                        detailSection("辅曜与亮度") {
                            FlowLayout {
                                ForEach(palace.auxiliaryStars, id: \.self) { star in
                                    let brightness = BrightnessCatalog.brightness(of: star, at: branch)?.label ?? ""
                                    TagPill(
                                        text: star.rawValue + brightness,
                                        color: StarCatalog.profile(star).weight < 0 ? Theme.cinnabar : Theme.gold
                                    )
                                }
                            }
                        }
                    }

                    detailSection("三方四正") {
                        VStack(spacing: 9) {
                            ForEach(Array(chart.triad(of: branch).enumerated()), id: \.offset) { offset, item in
                                let itemKind = chart.palaceKind(at: item, pivot: layer.pivotBranch)
                                let stars = chart.palace(at: item).mainStars
                                HStack(spacing: 10) {
                                    Text(offset == 0 ? "本宫" : offset == 3 ? "对宫" : "三合")
                                        .font(.caption2)
                                        .foregroundStyle(Theme.secondaryInk)
                                        .frame(width: 30, alignment: .leading)
                                    Text(Ganzhi.branches[item])
                                        .foregroundStyle(Theme.cinnabar)
                                        .frame(width: 22, alignment: .leading)
                                    Text(itemKind.rawValue)
                                        .frame(width: 44, alignment: .leading)
                                    Text(stars.isEmpty ? "空宫" : stars.map(\.rawValue).joined(separator: "、"))
                                        .foregroundStyle(Theme.secondaryInk)
                                    Spacer()
                                }
                                .font(.subheadline)
                            }
                        }
                    }

                    CulturalDisclaimer()
                }
                .padding(20)
            }
            #if DEBUG
            .onAppear {
                if ProcessInfo.processInfo.environment["ZIWEI_DETAIL"] == "flying" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        proxy.scrollTo("flying", anchor: .top)
                    }
                }
            }
            #endif
            }
            .background(Theme.paper)
            .navigationTitle("宫位详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title).font(.headline).foregroundStyle(Theme.ink)
            content().font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    /// 宫干飞化：本宫天干飞出的四化及其落点，落回本宫标为自化。
    @ViewBuilder
    private var flyingSection: some View {
        let entries = chart.flyingTransformations(from: branch)
        detailSection("宫干飞化 · \(Ganzhi.stems[palace.stemIndex])干") {
            VStack(alignment: .leading, spacing: 9) {
                ForEach(entries) { entry in
                    let targetKind = chart.palaceKind(at: entry.targetBranch, pivot: layer.pivotBranch)
                    HStack(spacing: 8) {
                        Text(entry.kind.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.transformationColor(entry.kind))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.transformationColor(entry.kind).opacity(0.12))
                            .clipShape(Capsule())
                        Text(entry.star.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.ink)
                        Text("→ \(targetKind.rawValue) · \(Ganzhi.branches[entry.targetBranch])")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                        if entry.isSelfTransformation {
                            TagPill(text: "自化", color: Theme.cinnabar)
                        }
                        Spacer(minLength: 0)
                    }
                }
                Text("自化表示这股能量在本宫内部消化：自化禄易流失、自化忌多纠结，解读时先看落宫再看是否回本。")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
    }
}
