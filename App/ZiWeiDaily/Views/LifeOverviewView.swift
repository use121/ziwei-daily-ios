import SwiftUI
import ZiWeiCore

/// 一生运程：十二大限逐段综述 + 关键节点 + 同盘古人。
struct LifeOverviewView: View {
    @EnvironmentObject private var state: AppState
    @State private var expanded: Set<Int> = []
    @State private var didPrepare = false

    var body: some View {
        Group {
            if let overview = state.lifeOverview {
                content(overview)
            } else {
                EmptyStateView(
                    title: "还没有可推演的命盘",
                    message: "先录入出生资料完成排盘，这里会按十二大限逐段展开一生运程。",
                    buttonTitle: "去排盘"
                ) {
                    state.selectedTab = .input
                }
            }
        }
        .background(Theme.paper)
        .navigationTitle("一生运程")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: state.lifeReportText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Theme.cinnabar)
                }
            }
        }
        .onAppear(perform: prepare)
    }

    private func prepare() {
        guard !didPrepare, let overview = state.lifeOverview else { return }
        didPrepare = true
        expanded = [overview.currentStageIndex]
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["ZIWEI_LIFE_STAGE"], let index = Int(raw) {
            expanded.insert(index)
        }
        #endif
    }

    private func content(_ overview: LifeOverview) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if compactLevel < 1 {
                    summaryCard(overview)
                    currentCard(overview)
                }
                if compactLevel < 2 {
                    timelineCard(overview)
                }
                if compactLevel < 3 {
                    keyNodeCard(overview)
                }

                figuresCard

                Text(HistoricalFigures.disclaimer)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.goldLight.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                CulturalDisclaimer()
            }
            .padding(18)
            .padding(.bottom, 28)
        }
    }

    // MARK: - 总述

    private func summaryCard(_ overview: LifeOverview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "一生总览", subtitle: "十二运程")
            Text(overview.headline)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Theme.cinnabar)
                .fixedSize(horizontal: false, vertical: true)

            Text(overview.arc)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

            scoreStrip(overview)

            Text("柱高为该十年运势评分，朱色为当前所处大限。")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func scoreStrip(_ overview: LifeOverview) -> some View {
        let scores = overview.stages.map(\.score)
        let low = scores.min() ?? 50
        let high = scores.max() ?? 90
        let span = max(1, high - low)
        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(overview.stages) { stage in
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(stage.isCurrent ? Theme.cinnabar.opacity(0.85) : Theme.gold.opacity(0.42))
                        .frame(height: 10 + CGFloat(stage.score - low) / CGFloat(span) * 38)
                    Text("\(stage.index + 1)")
                        .font(.system(size: 8, weight: stage.isCurrent ? .bold : .regular))
                        .foregroundStyle(stage.isCurrent ? Theme.cinnabar : Theme.secondaryInk)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 62, alignment: .bottom)
        .padding(.top, 4)
    }

    // MARK: - 当前阶段

    private func currentCard(_ overview: LifeOverview) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                SectionHeading(title: "眼下这一段", subtitle: overview.current?.rangeText)
                Spacer(minLength: 0)
            }

            if let stage = overview.current {
                HStack(spacing: 7) {
                    Text("「\(stage.title)」")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    TagPill(text: stage.tone.rawValue, color: toneColor(stage.tone))
                    TagPill(text: "\(stage.score) 分", color: Theme.scoreColor(stage.score))
                    Spacer(minLength: 0)
                }
                Text("\(stage.yearText) · 本命\(kindName(stage.natalKind)) · 大限\(stage.ganzhi)")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }

            VStack(alignment: .leading, spacing: 9) {
                ForEach(Array(overview.currentFocus.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.cinnabar)
                            .frame(width: 16, height: 16)
                            .background(Theme.cinnabarLight.opacity(0.7))
                            .clipShape(Circle())
                        Text(line)
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    // MARK: - 十二运程

    private func timelineCard(_ overview: LifeOverview) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeading(title: "十二运程", subtitle: "点开看细节")
            Text("每一限十年，宫位旋转后命宫落在本命哪一宫，就决定了这十年的主题；事业、家庭、父母、身心四条线都从这一限的盘面读出。")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(overview.stages) { stage in
                stageRow(stage)
                    .id(stage.index)
                if stage.id != overview.stages.last?.id {
                    Divider().overlay(Theme.line.opacity(0.4))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func stageRow(_ stage: LifeStage) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    if expanded.contains(stage.index) {
                        expanded.remove(stage.index)
                    } else {
                        expanded.insert(stage.index)
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 9) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(String(format: "%02d", stage.index + 1))
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Theme.line)
                                Text(stage.title)
                                    .font(.system(.headline, design: .serif))
                                    .foregroundStyle(stage.isExtended ? Theme.secondaryInk : Theme.ink)
                                TagPill(text: stage.tone.rawValue, color: toneColor(stage.tone))
                                if stage.isCurrent {
                                    TagPill(text: "当前", color: Theme.cinnabar)
                                }
                                if stage.isExtended {
                                    TagPill(text: "理论延续", color: Theme.secondaryInk)
                                }
                            }
                            Text("\(stage.rangeText) · \(stage.yearText) · 本命\(kindName(stage.natalKind))")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryInk)
                        }
                        Spacer(minLength: 0)
                        HStack(spacing: 6) {
                            Text(String(stage.score))
                                .font(.system(size: 19, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.scoreColor(stage.score))
                            Image(systemName: expanded.contains(stage.index) ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.secondaryInk)
                        }
                    }

                    scoreBar(stage)
                }
            }
            .buttonStyle(.plain)

            if expanded.contains(stage.index) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(stage.themeLine)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Theme.cinnabar)
                        .fixedSize(horizontal: false, vertical: true)

                    lineRow("事业", stage.career)
                    lineRow("家庭", stage.family)
                    lineRow("父母", stage.parents)
                    lineRow("身心", stage.health)

                    if !stage.milestones.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("这十年的节点")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.gold)
                            ForEach(stage.milestones, id: \.self) { item in
                                Text("· \(item)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func scoreBar(_ stage: LifeStage) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line.opacity(0.22))
                Capsule()
                    .fill(Theme.scoreColor(stage.score).opacity(0.7))
                    .frame(width: max(4, geo.size.width * CGFloat(stage.score) / 100))
            }
        }
        .frame(height: 3)
    }

    private func lineRow(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.gold)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.goldLight.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            Text(body)
                .font(.footnote)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - 关键节点

    private func keyNodeCard(_ overview: LifeOverview) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeading(title: "关键节点", subtitle: "什么时候该动、什么时候该守")
            Text("近期的节点按流年四化与本限的关系挑出：化禄入本限适合推进，化忌冲本限适合保守。末尾两条是一生里条件最好与最紧的十年。")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(overview.nearNodes) { node in
                nodeRow(node)
            }

            if !overview.lifeNodes.isEmpty {
                Divider().overlay(Theme.line.opacity(0.4))
                ForEach(overview.lifeNodes) { node in
                    nodeRow(node)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func nodeRow(_ node: KeyNode) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 1) {
                Text(String(node.year))
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text(node.ageText)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.secondaryInk)
            }
            .frame(width: 46, alignment: .leading)

            Circle()
                .fill(nodeColor(node.kind))
                .frame(width: 7, height: 7)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    TagPill(text: node.kind.rawValue, color: nodeColor(node.kind))
                    Text(node.title)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                }
                Text(node.detail)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - 同盘古人

    private var figuresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "同盘意象", subtitle: "同主星组合的古人")

            if state.figureMatches.isEmpty {
                Text("命宫主星组合暂时没有对应的古人样本。")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryInk)
            } else {
                Text("按命宫主星组合找的参照，不是生辰相同。看的是「同一组星在不同人生里怎么显形」，好坏都收。")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(state.figureMatches) { match in
                    figureBlock(match)
                    if match.id != state.figureMatches.last?.id {
                        Divider().overlay(Theme.line.opacity(0.4))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func figureBlock(_ match: FigureMatch) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(match.figure.name)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(match.figure.era) · \(match.figure.title)")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
                    .lineLimit(2)
                Spacer(minLength: 0)
                TagPill(
                    text: match.kind.rawValue,
                    color: match.kind == .sameCombo ? Theme.cinnabar : Theme.gold
                )
            }

            HStack(spacing: 5) {
                ForEach(match.figure.stars, id: \.self) { star in
                    TagPill(
                        text: star.rawValue,
                        color: match.sharedStars.contains(star) ? Theme.cinnabar : Theme.secondaryInk
                    )
                }
                if match.borrowed {
                    TagPill(text: "命宫空宫·借对宫", color: Theme.secondaryInk)
                }
                Spacer(minLength: 0)
            }

            if match.kind == .sameStar {
                Text("朱色标出的是与你命宫相同的主星，其余是该古人命宫的另一颗。")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.secondaryInk)
            }

            Text(match.figure.story)
                .font(.footnote)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("像在哪")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Text(match.figure.resonance)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.cinnabar)
                    .padding(.top, 3)
                Text(match.figure.lesson)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 小工具

    /// 调试：1 隐藏总述与当前卡，2 再隐藏十二运程，方便直接看后面的板块。
    private var compactLevel: Int {
        #if DEBUG
        Int(ProcessInfo.processInfo.environment["ZIWEI_LIFE_COMPACT"] ?? "") ?? 0
        #else
        0
        #endif
    }

    private func kindName(_ kind: PalaceKind) -> String {
        kind == .life ? "命宫" : "\(kind.rawValue)宫"
    }

    private func toneColor(_ tone: StageTone) -> Color {
        switch tone {
        case .rising: Theme.cinnabar
        case .steady: Theme.gold
        case .turning: Theme.azurite
        case .straining: Theme.secondaryInk
        }
    }

    private func nodeColor(_ kind: KeyNodeKind) -> Color {
        switch kind {
        case .opening: Theme.cinnabar
        case .caution: Theme.azurite
        case .turning: Theme.gold
        }
    }
}
