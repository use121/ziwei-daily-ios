import SwiftUI
import ZiWeiCore

/// 六维解读页。文案由 InsightEngine 规则生成，同一命盘与同一时间层输出恒定。
struct InsightView: View {
    @EnvironmentObject private var state: AppState
    @State private var expanded: Set<String> = [InsightTopic.overview.rawValue]
    @State private var showBasis = false

    var body: some View {
        NavigationStack {
            if let chart = state.chart, let layer = state.currentLayer {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(chart: chart, layer: layer)

                        LayerSwitcher()
                            .ziWeiCard(padding: 14)

                        ForEach(state.insights) { insight in
                            InsightCard(
                                insight: insight,
                                isExpanded: expanded.contains(insight.id),
                                onToggle: { toggle(insight.id) },
                                onOpenPalace: {
                                    state.selectedTab = .chart
                                }
                            )
                        }

                        basisCard(chart: chart, layer: layer)
                        CulturalDisclaimer()
                    }
                    .padding(18)
                    .padding(.bottom, 28)
                }
                .background(Theme.paper)
                .navigationTitle("命理解读")
            } else {
                EmptyStateView(
                    title: "还没有可解读的命盘",
                    message: "先录入出生资料完成排盘，这里会按命宫、夫妻、官禄、财帛、疾厄逐宫展开。",
                    buttonTitle: "去排盘"
                ) {
                    state.selectedTab = .input
                }
                .navigationTitle("命理解读")
            }
        }
    }

    private func header(chart: Chart, layer: TimeLayer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(layer.kind.rawValue) · 六维解读")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                if state.isProUnlocked {
                    TagPill(text: "专业版已解锁", color: Theme.gold)
                }
            }
            Text("命宫、夫妻、官禄、财帛、疾厄五宫联动，按传统规则生成；同一张盘同一时间层，结论不随刷新变化。")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    Text("解读为规则化生成，不含随机成分；同一命盘在不同日期查看本命层，结论完全一致。")
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
}
