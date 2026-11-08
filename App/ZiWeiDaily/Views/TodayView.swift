import SwiftUI
import ZiWeiCore

struct TodayView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationStack {
            if let report = state.report, let chart = state.chart {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header(report)
                        scoreHero(report, chart: chart)

                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeading(title: "四项状态", subtitle: "满分均为 100")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(report.dimensions) { dimension in
                                    DimensionCard(dimension: dimension)
                                }
                            }
                        }

                        contentCard(title: "今日状态", systemImage: "text.quote") {
                            Text(report.summary)
                                .font(.body)
                                .foregroundStyle(Theme.ink)
                                .lineSpacing(5)
                            HStack(spacing: 8) {
                                TagPill(text: "流日 \(report.dayGanzhi)", color: Theme.gold)
                                TagPill(text: "落\(report.activePalace.rawValue)")
                                TagPill(text: "\(Ganzhi.branches[report.activeBranch])宫", color: Theme.jade)
                            }
                        }

                        contentCard(title: "今日行动提示", systemImage: "checklist") {
                            ForEach(report.recommendedActions.indices, id: \.self) { index in
                                Label(report.recommendedActions[index], systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.jade)
                                    .font(.subheadline)
                                    .lineSpacing(3)
                            }
                            Divider()
                            ForEach(report.cautions.indices, id: \.self) { index in
                                Label(report.cautions[index], systemImage: "exclamationmark.circle")
                                    .foregroundStyle(Theme.gold)
                                    .font(.subheadline)
                                    .lineSpacing(3)
                            }
                        }

                        contentCard(title: "当前整体运势", systemImage: "calendar") {
                            Text(report.yearTheme)
                                .font(.subheadline)
                                .lineSpacing(4)
                            Text(report.decadeTheme)
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondaryInk)
                                .lineSpacing(4)
                        }

                        contentCard(title: "流日四化", systemImage: "sparkles") {
                            FlowLayout {
                                ForEach(report.dayTransformations.indices, id: \.self) { index in
                                    let transformation = report.dayTransformations[index]
                                    TagPill(
                                        text: "\(transformation.star.rawValue) \(transformation.kind.rawValue)",
                                        color: transformation.kind == .ji ? Theme.cinnabar : Theme.gold
                                    )
                                }
                            }
                        }

                        contentCard(title: "评分依据", systemImage: "slider.horizontal.3") {
                            Text("基础分结合流日三方四正、四化、星曜与五行关系计算；同一资料同一天结果一致。")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryInk)
                            ForEach(report.scoringNotes.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 9) {
                                    Circle().fill(Theme.gold).frame(width: 5, height: 5).padding(.top, 6)
                                    Text(report.scoringNotes[index])
                                        .font(.caption)
                                        .foregroundStyle(Theme.secondaryInk)
                                }
                            }
                        }

                        CulturalDisclaimer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                }
                .background(Theme.paper)
                .navigationTitle("紫微日常")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: state.shareText) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("分享今日评分")
                    }
                }
                .refreshable { state.refreshToday() }
            } else {
                EmptyStateView(
                    title: "先建立你的紫微命盘",
                    message: "填写出生日期、时间、性别和出生地，即可生成十二宫命盘与今日 100 分制状态。",
                    buttonTitle: "填写出生资料"
                ) {
                    state.selectedTab = .input
                }
                .navigationTitle("紫微日常")
            }
        }
    }

    private func header(_ report: DailyReport) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(report))
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text("\(report.lunarText) · \(report.dayGanzhi)日")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundStyle(Theme.gold)
        }
    }

    private func scoreHero(_ report: DailyReport, chart: Chart) -> some View {
        VStack(spacing: 18) {
            HStack(spacing: 22) {
                ScoreRing(score: report.score)
                VStack(alignment: .leading, spacing: 9) {
                    TagPill(text: report.status)
                    Text(report.headline)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("命盘：\(chart.bureau.bureauName) · \(chart.palace(.life).ganzhi)命")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                ForEach(report.highlights.indices, id: \.self) { index in
                    Label(report.highlights[index], systemImage: "smallcircle.filled.circle")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryInk)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .ziWeiCard()
    }

    private func formattedDate(_ report: DailyReport) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: state.input.timeZoneIdentifier)
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: report.date)
    }

    private func contentCard<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            content()
        }
        .ziWeiCard()
    }
}

private struct ScoreRing: View {
    let score: Int
    @State private var progress = 0.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.line.opacity(0.35), style: StrokeStyle(lineWidth: 10, lineCap: .round))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [Theme.gold, Theme.scoreColor(score)], center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 44, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.scoreColor(score))
                    .contentTransition(.numericText())
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
        .frame(width: 124, height: 124)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("今日评分 \(score) 分，满分 100 分")
        .onAppear { update() }
        .onChange(of: score) { _, _ in update() }
    }

    private func update() {
        withAnimation(.easeOut(duration: 0.8)) { progress = Double(score) / 100 }
    }
}

private struct DimensionCard: View {
    let dimension: DimensionScore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dimension.title).font(.headline).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(dimension.score)")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.scoreColor(dimension.score))
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line.opacity(0.25))
                    Capsule().fill(Theme.scoreColor(dimension.score))
                        .frame(width: geometry.size.width * Double(dimension.score) / 100)
                }
            }
            .frame(height: 5)
            Text(dimension.note)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(minHeight: 112, alignment: .top)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Theme.line.opacity(0.4)) }
    }
}

struct FlowLayout: Layout {

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var point = CGPoint.zero
        var maxHeight = 0.0
        var lineHeight = 0.0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if point.x + size.width > width, point.x > 0 {
                point.x = 0
                point.y += lineHeight + 8
                lineHeight = 0
            }
            point.x += size.width + 8
            lineHeight = max(lineHeight, size.height)
            maxHeight = max(maxHeight, point.y + lineHeight)
        }
        return CGSize(width: width, height: maxHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var point = bounds.origin
        var lineHeight = 0.0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if point.x + size.width > bounds.maxX, point.x > bounds.minX {
                point.x = bounds.minX
                point.y += lineHeight + 8
                lineHeight = 0
            }
            subview.place(at: point, proposal: ProposedViewSize(size))
            point.x += size.width + 8
            lineHeight = max(lineHeight, size.height)
        }
    }
}
