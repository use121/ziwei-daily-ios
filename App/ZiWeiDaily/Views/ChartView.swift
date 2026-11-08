import SwiftUI
import ZiWeiCore

struct ChartView: View {
    @EnvironmentObject private var state: AppState
    @State private var selectedPalace: Palace?

    var body: some View {
        NavigationStack {
            if let chart = state.chart {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(chartTitle(chart))
                                .font(.system(.title2, design: .serif, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("\(chart.resolvedBirth.lunarDate.displayText) · \(Ganzhi.branches[chart.resolvedBirth.hourBranch])时")
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondaryInk)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        PalaceGrid(chart: chart, selected: $selectedPalace)

                        HStack(spacing: 12) {
                            summaryItem("命宫", "\(chart.palace(.life).ganzhi)")
                            summaryItem("身宫", "\(chart.palace(at: chart.bodyBranch).ganzhi)")
                            summaryItem("五行局", chart.bureau.bureauName)
                        }

                        contentCard(title: "生年四化", subtitle: chart.resolvedBirth.lunarDate.yearGanzhi) {
                            FlowLayout {
                                ForEach(chart.birthTransformations.indices, id: \.self) { index in
                                    let item = chart.birthTransformations[index]
                                    let branch = chart.branch(of: item.star)
                                    TagPill(
                                        text: "\(item.star.rawValue) \(item.kind.rawValue) · \(branch.map { chart.palace(at: $0).kind.rawValue } ?? "")",
                                        color: item.kind == .ji ? Theme.cinnabar : Theme.gold
                                    )
                                }
                            }
                        }

                        contentCard(title: "排盘信息", subtitle: chart.input.birthplace) {
                            infoRow("公历", birthText(chart))
                            infoRow("农历", chart.resolvedBirth.lunarDate.displayText)
                            infoRow("时辰", "\(Ganzhi.branches[chart.resolvedBirth.hourBranch])时（\(hourText(chart))）")
                            infoRow("大限", chart.isForwardDecade ? "顺行" : "逆行")
                            if chart.input.useTrueSolarTime {
                                infoRow("真太阳时", "已校正 \(chart.resolvedBirth.correctionMinutes) 分钟")
                            }
                            if chart.resolvedBirth.lunarDate.isLeapMonth {
                                Text("闰月安紫微：以对应正一月天数加闰月日数；命身宫按闰月本月计算。")
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryInk)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeading(title: "十二宫详情", subtitle: "点按宫位查看")
                            ForEach(chart.palaces) { palace in
                                Button { selectedPalace = palace } label: {
                                    HStack(spacing: 12) {
                                        Text(palace.branchName)
                                            .font(.system(.headline, design: .serif))
                                            .foregroundStyle(Theme.cinnabar)
                                            .frame(width: 28)
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(palace.kind.rawValue).font(.headline)
                                                if palace.isBodyPalace { TagPill(text: "身宫", color: Theme.jade) }
                                            }
                                            Text(palace.mainStars.isEmpty ? "空宫 · 借对宫星曜" : palace.mainStars.map(\.rawValue).joined(separator: "、"))
                                                .font(.caption)
                                                .foregroundStyle(Theme.secondaryInk)
                                        }
                                        Spacer()
                                        Text(palace.decadeText).font(.caption2).foregroundStyle(Theme.secondaryInk)
                                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.line)
                                    }
                                    .padding(13)
                                    .background(Theme.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        CulturalDisclaimer()
                    }
                    .padding(18)
                }
                .background(Theme.paper)
                .navigationTitle("紫微命盘")
                .sheet(item: $selectedPalace) { palace in
                    PalaceDetailView(chart: chart, palace: palace)
                }
            } else {
                EmptyStateView(title: "命盘尚未生成", message: "完成出生资料录入后，这里会展示十二宫、十四主星、四化和大限。", buttonTitle: "去排盘") {
                    state.selectedTab = .input
                }
                .navigationTitle("紫微命盘")
            }
        }
    }

    private func chartTitle(_ chart: Chart) -> String {
        let name = chart.input.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "本命十二宫" : "\(name)的本命十二宫"
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

    private func contentCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeading(title: title, subtitle: subtitle)
            content()
        }
        .ziWeiCard()
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).font(.caption).foregroundStyle(Theme.secondaryInk).frame(width: 62, alignment: .leading)
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

private struct PalaceGrid: View {
    let chart: Chart
    @Binding var selected: Palace?

    private let cells: [(row: Int, column: Int, branch: Int)] = [
        (0, 0, 5), (0, 1, 6), (0, 2, 7), (0, 3, 8),
        (1, 0, 4), (1, 3, 9),
        (2, 0, 3), (2, 3, 10),
        (3, 0, 2), (3, 1, 1), (3, 2, 0), (3, 3, 11)
    ]

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width / 4
            ZStack {
                center.frame(width: side * 2, height: side * 2)
                    .position(x: geometry.size.width / 2, y: geometry.size.width / 2)
                ForEach(cells, id: \.branch) { cell in
                    let palace = chart.palace(at: cell.branch)
                    Button { selected = palace } label: {
                        palaceCell(palace)
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
        VStack(spacing: 8) {
            Image(systemName: "sparkles").foregroundStyle(Theme.gold)
            Text("紫微斗数").font(.system(.title3, design: .serif, weight: .semibold)).foregroundStyle(Theme.ink)
            Text(chart.resolvedBirth.lunarDate.yearGanzhi + "年").font(.caption).foregroundStyle(Theme.secondaryInk)
            Divider().padding(.horizontal, 30)
            Text(chart.bureau.bureauName).font(.headline).foregroundStyle(Theme.cinnabar)
            Text("命在\(Ganzhi.branches[chart.lifeBranch]) · 身在\(Ganzhi.branches[chart.bodyBranch])")
                .font(.caption2).foregroundStyle(Theme.secondaryInk)
        }
        .background(Theme.paper)
        .overlay { Rectangle().stroke(Theme.line, lineWidth: 0.7) }
    }

    private func palaceCell(_ palace: Palace) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Text(palace.kind.rawValue).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.ink)
                if palace.isBodyPalace {
                    Text("身").font(.system(size: 8)).foregroundStyle(.white)
                        .padding(2).background(Theme.jade).clipShape(Circle())
                }
                Spacer()
                Text(palace.ganzhi).font(.system(size: 9)).foregroundStyle(Theme.secondaryInk)
            }
            Spacer(minLength: 0)
            Text(palace.mainStars.isEmpty ? "空宫" : palace.mainStars.map(\.rawValue).joined(separator: "·"))
                .font(.system(size: palace.mainStars.count > 1 ? 12 : 14, weight: .semibold, design: .serif))
                .foregroundStyle(palace.mainStars.isEmpty ? Theme.secondaryInk : Theme.cinnabar)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if !palace.auxiliaryStars.isEmpty {
                Text(palace.auxiliaryStars.prefix(4).map(\.rawValue).joined(separator: "·"))
                    .font(.system(size: 8)).foregroundStyle(Theme.gold).lineLimit(1)
            }
            HStack {
                ForEach(palace.transformations.indices, id: \.self) { index in
                    Text(palace.transformations[index].kind.rawValue.replacingOccurrences(of: "化", with: ""))
                        .font(.system(size: 8, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 14, height: 14)
                        .background(palace.transformations[index].kind == .ji ? Theme.cinnabar : Theme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Spacer()
                Text("\(palace.decadeStart)–\(palace.decadeEnd)").font(.system(size: 8)).foregroundStyle(Theme.secondaryInk)
            }
        }
        .padding(6)
        .background(palace.branchIndex == chart.lifeBranch ? Theme.cinnabarLight.opacity(0.48) : Theme.card)
        .overlay { Rectangle().stroke(Theme.line.opacity(0.8), lineWidth: 0.55) }
    }
}

private struct PalaceDetailView: View {
    let chart: Chart
    let palace: Palace
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(palace.ganzhi).font(.title).foregroundStyle(Theme.cinnabar)
                            if palace.isBodyPalace { TagPill(text: "身宫", color: Theme.jade) }
                        }
                        Text(palace.kind.focus).font(.subheadline).foregroundStyle(Theme.secondaryInk)
                        Text("大限 \(palace.decadeText)").font(.caption).foregroundStyle(Theme.gold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if palace.mainStars.isEmpty {
                        let opposite = chart.palace(at: palace.branchIndex + 6)
                        detailSection("空宫与借星") {
                            Text("本宫无十四主星，可借对宫 \(opposite.ganzhi)·\(opposite.kind.rawValue) 的 \(opposite.mainStars.map(\.rawValue).joined(separator: "、")) 观察，但仍需结合全盘。")
                        }
                    } else {
                        detailSection("主星") {
                            ForEach(palace.mainStars, id: \.self) { star in
                                let profile = StarCatalog.profile(star)
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(star.rawValue).font(.headline).foregroundStyle(Theme.cinnabar)
                                        Text(profile.keyword).font(.caption).foregroundStyle(Theme.gold)
                                        if let transformation = palace.transformations.first(where: { $0.star == star }) {
                                            TagPill(text: transformation.kind.rawValue)
                                        }
                                    }
                                    Text(profile.action).font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    if !palace.auxiliaryStars.isEmpty {
                        detailSection("辅曜") {
                            FlowLayout {
                                ForEach(palace.auxiliaryStars, id: \.self) { star in
                                    TagPill(text: star.rawValue, color: StarCatalog.profile(star).weight < 0 ? Theme.cinnabar : Theme.gold)
                                }
                            }
                        }
                    }

                    detailSection("三方四正") {
                        let branches = [palace.branchIndex, palace.branchIndex + 4, palace.branchIndex + 8, palace.branchIndex + 6]
                        ForEach(branches, id: \.self) { branch in
                            let item = chart.palace(at: branch)
                            HStack {
                                Text(item.ganzhi).foregroundStyle(Theme.cinnabar).frame(width: 45, alignment: .leading)
                                Text(item.kind.rawValue).frame(width: 45, alignment: .leading)
                                Text(item.mainStars.isEmpty ? "空宫" : item.mainStars.map(\.rawValue).joined(separator: "、"))
                                    .foregroundStyle(Theme.secondaryInk)
                                Spacer()
                            }
                        }
                    }
                    CulturalDisclaimer()
                }
                .padding(20)
            }
            .background(Theme.paper)
            .navigationTitle("\(palace.kind.rawValue)详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundStyle(Theme.ink)
            content().font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }
}
