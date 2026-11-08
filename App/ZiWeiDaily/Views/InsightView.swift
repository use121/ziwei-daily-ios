import SwiftUI
import ZiWeiCore

/// 六维解读页。文案由 InsightEngine 规则生成，同一命盘与同一时间层输出恒定。
struct InsightView: View {
    @EnvironmentObject private var state: AppState
    @State private var expanded: Set<String> = [InsightTopic.overview.rawValue]
    @State private var showBasis = false
    @State private var showAllTopics = ProcessInfo.processInfo.environment["ZIWEI_ALL"] == "1"
    @State private var showLifeOverview = ProcessInfo.processInfo.environment["ZIWEI_LIFE"] == "1"
    /// 从解读里的古籍原句跳转过去的篇目。
    @State private var classicWork: ClassicWork?

    var body: some View {
        NavigationStack {
            if let chart = state.chart, let layer = state.currentLayer {
                ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(chart: chart, layer: layer)

                        lifeOverviewEntry

                        LayerSwitcher()
                            .ziWeiCard(padding: 14)

                        radarCard
                        transformationPathCard
                            .id("paths")
                        topicFilter(proxy)

                        ForEach(visibleInsights) { insight in
                            InsightCard(
                                insight: insight,
                                isExpanded: expanded.contains(insight.id),
                                onToggle: { toggle(insight.id) },
                                onOpenPalace: {
                                    state.selectedTab = .chart
                                },
                                onOpenClassic: { source in
                                    guard let title = ClassicLibrary.workTitle(forSource: source),
                                          let work = ClassicLibrary.work(title) else { return }
                                    classicWork = work
                                }
                            )
                            .id(insight.id)
                        }

                        basisCard(chart: chart, layer: layer)
                        CulturalDisclaimer()
                    }
                    .padding(18)
                    .padding(.bottom, 28)
                }
                #if DEBUG
                .onAppear {
                    let environment = ProcessInfo.processInfo.environment
                    if let expand = environment["ZIWEI_EXPAND"], !expand.isEmpty {
                        expanded.insert(expand)
                    }
                    if let target = environment["ZIWEI_SCROLL"], !target.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            proxy.scrollTo(target == "paths" ? "paths" : target, anchor: .top)
                        }
                    }
                }
                #endif
                }
                .background(Theme.paper)
                .navigationTitle("命理解读")
                .navigationDestination(isPresented: $showLifeOverview) {
                    LifeOverviewView()
                }
                .navigationDestination(item: $classicWork) { work in
                    ClassicWorkView(work: work)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: state.fullReportText) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Theme.cinnabar)
                        }
                    }
                }
            } else {
                EmptyStateView(
                    title: "还没有可解读的命盘",
                    message: "先录入出生资料完成排盘，这里会按命宫、夫妻、官禄、财帛、疾厄逐宫展开。",
                    buttonTitle: "去排盘"
                ) {
                    state.selectedTab = .input
                }
                .navigationTitle("命理解读")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: state.fullReportText) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Theme.cinnabar)
                        }
                    }
                }
            }
        }
    }

    private func header(chart: Chart, layer: TimeLayer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(layer.kind.rawValue) · 十四维解读")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                if state.isProUnlocked {
                    TagPill(text: "专业版已解锁", color: Theme.gold)
                }
            }
            Text("核心六维看主线，贵人与七宫看细节；格局与四化由当前时间层推算，同一张盘同一层，结论不随刷新变化。")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var visibleInsights: [Insight] {
        showAllTopics ? state.insights : state.insights.filter { $0.topic.isCore }
    }

    /// 一生总览入口：不点进去也能看到当前这十年的定性与提醒。
    @ViewBuilder
    private var lifeOverviewEntry: some View {
        Button {
            showLifeOverview = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Text("一生总览")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    TagPill(text: "十二运程", color: Theme.gold)
                    Spacer(minLength: 0)
                    HStack(spacing: 3) {
                        Text("展开")
                            .font(.caption2)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(Theme.cinnabar)
                }

                if let overview = state.lifeOverview, let current = overview.current {
                    Text(overview.headline)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.cinnabar)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Text("眼下：\(current.title)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.ink)
                        TagPill(text: current.rangeText, color: Theme.secondaryInk)
                        TagPill(text: "\(current.score) 分", color: Theme.scoreColor(current.score))
                        Spacer(minLength: 0)
                    }

                    if let first = overview.currentFocus.first {
                        Text(first)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Text("含逐段事业 / 家庭 / 父母 / 身心 · 关键节点 · 同盘古人")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryInk)
                } else {
                    Text("正在推演十二大限…")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .ziWeiCard()
        }
        .buttonStyle(.plain)
    }

    private var radarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "六维强弱", subtitle: "本层相对结构")
            RadarChart(scores: state.topicScores)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private var transformationPathCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeading(title: "四化路径", subtitle: state.currentLayer?.kind.rawValue ?? "")
            Text(state.transformSummary)
                .font(.footnote)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(state.transformEntries) { entry in
                HStack(spacing: 8) {
                    Text(entry.kind.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.transformationColor(entry.kind))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.transformationColor(entry.kind).opacity(0.12))
                        .clipShape(Capsule())
                    Text(entry.star.rawValue)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.ink)
                    Text("→ \(entry.palaceName) · \(entry.branchName)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func topicFilter(_ proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                ForEach([false, true], id: \.self) { all in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { showAllTopics = all }
                    } label: {
                        Text(all ? "全部十四维" : "核心六维")
                            .font(.system(size: 12, weight: (showAllTopics == all) ? .semibold : .regular))
                            .foregroundStyle(showAllTopics == all ? Theme.cinnabar : Theme.secondaryInk)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(showAllTopics == all ? Theme.cinnabarLight.opacity(0.5) : Theme.card)
                            )
                            .overlay(
                                Capsule().stroke(Theme.line.opacity(showAllTopics == all ? 0.7 : 0.4), lineWidth: 0.6)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Text("\(visibleInsights.count) 项")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
            }

            // 其余维度不藏起来：核心六维之外的主题直接给一排可点入口
            if !showAllTopics {
                VStack(alignment: .leading, spacing: 6) {
                    Text("另有 \(extraTopics.count) 个维度：点开直接跳过去")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryInk)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(extraTopics) { topic in
                                Button {
                                    withAnimation(.easeOut(duration: 0.18)) { showAllTopics = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            proxy.scrollTo(topic.rawValue, anchor: .top)
                                        }
                                    }
                                } label: {
                                    TagPill(text: topic.rawValue, color: Theme.gold)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
        }
    }

    private var extraTopics: [InsightTopic] {
        InsightTopic.allCases.filter { !$0.isCore }
    }

    private func basisCard(chart: Chart, layer: TimeLayer) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { showBasis.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("解读依据")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(layer.kind.rawValue)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                    Spacer()
                    Image(systemName: showBasis ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                }
            }
            .buttonStyle(.plain)

            if showBasis {
                VStack(alignment: .leading, spacing: 8) {
                    basisRow("命宫", "\(Ganzhi.branches[layer.pivotBranch]) · \(chart.palace(at: layer.pivotBranch).mainStars.map(\.rawValue).joined(separator: "、"))")
                    basisRow("五行局", chart.bureau.bureauName)
                    basisRow("大限", chart.isForwardDecade ? "顺行" : "逆行")
                    basisRow("当前虚岁", "\(chart.nominalAge()) 岁")
                    basisRow("四化来源", layer.kind == .natal ? "生年\(chart.resolvedBirth.lunarDate.yearGanzhi)" : "\(layer.stemName)干（\(layer.kind.rawValue)层）")
                    basisRow("亮度口径", "《紫微斗数全书》七档")
                    Text("解读为规则化生成，不含随机成分；同一命盘在不同日期查看本命层，结论完全一致。格局与十二神只作结构说明，不进入评分。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                        .padding(.top, 2)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func basisRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
                .frame(width: 62, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
    }

    private func toggle(_ id: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            if expanded.contains(id) {
                expanded.remove(id)
            } else {
                expanded.insert(id)
            }
        }
    }
}

private struct InsightCard: View {
    let insight: Insight
    let isExpanded: Bool
    let onToggle: () -> Void
    let onOpenPalace: () -> Void
    let onOpenClassic: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 9) {
                        Image(systemName: insight.topic.symbol)
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Theme.cinnabar)
                            .frame(width: 22)
                        Text(insight.topic.rawValue)
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Theme.ink)
                        if insight.borrowsOpposite {
                            TagPill(text: "借对宫", color: Theme.gold)
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                    Text(insight.headline)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.cinnabar)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(insight.blocks) { block in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(block.heading)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.gold)
                            Text(block.body)
                                .font(.subheadline)
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !insight.patterns.isEmpty {
                        patternBriefs
                    }

                    if !insight.keyStars.isEmpty {
                        FlowLayout {
                            ForEach(insight.keyStars, id: \.self) { star in
                                TagPill(text: star.rawValue, color: Theme.cinnabar)
                            }
                            Button(action: onOpenPalace) {
                                Text("看盘面 →")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Theme.azurite)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Theme.azurite.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(insight.caution)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    /// 格局名 + 档位 + 古籍原句。原句可点，跳到该篇全文。
    private var patternBriefs: some View {
        VStack(alignment: .leading, spacing: 9) {
            FlowLayout {
                ForEach(insight.patterns) { brief in
                    TagPill(
                        text: brief.name,
                        color: brief.displayedKind == .auspicious ? Theme.jade : Theme.gold
                    )
                }
            }

            ForEach(insight.patterns.filter { $0.quote != nil }) { brief in
                if let quote = brief.quote {
                    Button {
                        onOpenClassic(quote.source)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("「\(quote.original)」")
                                    .font(.system(size: 12, design: .serif))
                                    .foregroundStyle(Theme.cinnabar)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                                Text(quote.source)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.secondaryInk)
                            }
                            Text(quote.plain)
                                .font(.caption2)
                                .foregroundStyle(Theme.secondaryInk)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.goldLight.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("查看古籍原文，\(quote.source)")
                }
            }
        }
    }
}
