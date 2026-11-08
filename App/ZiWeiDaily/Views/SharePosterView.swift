import SwiftUI
import UIKit
import ZiWeiCore

/// 长图海报：整盘 + 排盘信息 + 四化 + 格局 + 六维评分，导出为一张图片。
struct SharePosterView: View {
    let chart: Chart
    let layer: TimeLayer

    private let posterWidth: CGFloat = 420

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            PosterGrid(chart: chart, layer: layer)
            transformationBlock
            if !patterns.isEmpty { patternBlock }
            scoreBlock
            footer
        }
        .padding(20)
        .frame(width: posterWidth)
        .background(Theme.paper)
    }

    private var patterns: [Pattern] {
        PatternEngine.patterns(for: chart, layer: layer)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("紫微日常")
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.cinnabar)
                Spacer()
                Text(layer.kind.rawValue + "盘")
                    .font(.caption)
                    .foregroundStyle(Theme.gold)
            }
            let name = chart.input.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            Text(name.isEmpty ? "我的紫微命盘" : "\(name)的紫微命盘")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("\(chart.resolvedBirth.lunarDate.displayText) · \(Ganzhi.branches[chart.resolvedBirth.hourBranch])时 · \(chart.bureau.bureauName)")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
            Text("命在\(Ganzhi.branches[chart.lifeBranch]) · 身在\(Ganzhi.branches[chart.bodyBranch]) · 命主\(chart.soulMaster.rawValue) · 身主\(chart.bodyMaster.rawValue)")
                .font(.caption2)
                .foregroundStyle(Theme.gold)
        }
    }

    private var transformationBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            posterSectionTitle(layer.kind == .natal ? "生年四化" : "\(layer.stemName)干四化（\(layer.kind.rawValue)层）")
            FlowLayout {
                ForEach(layer.transformations, id: \.star) { item in
                    let branch = chart.branch(of: item.star)
                    let name = branch.map { chart.palaceKind(at: $0, pivot: layer.pivotBranch).rawValue } ?? ""
                    Text("\(item.star.rawValue)\(item.kind.rawValue) · \(name)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.transformationColor(item.kind))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.transformationColor(item.kind).opacity(0.10))
                        .clipShape(Capsule())
                }
            }
            if !chart.selfTransformations.isEmpty {
                Text("自化：" + chart.selfTransformations.map { "\(Ganzhi.branches[$0.branch])宫\(String($0.kind.rawValue.suffix(1)))" }.joined(separator: "、"))
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
    }

    private var patternBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            posterSectionTitle("格局")
            ForEach(patterns) { pattern in
                HStack(spacing: 8) {
                    Text(pattern.name)
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(pattern.kind.rawValue)
                        .font(.caption2)
                        .foregroundStyle(pattern.kind == .caution ? Theme.cinnabar : Theme.gold)
                    Spacer()
                    if let quote = ClassicLibrary.quote(for: pattern.name) {
                        Text("「\(quote.original)」\(quote.source)")
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryInk)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var scoreBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            posterSectionTitle("六维强弱")
            let scores = Array(TopicScoreEngine.scores(chart: chart, layer: layer).prefix(6))
            ForEach(scores) { score in
                HStack(spacing: 10) {
                    Text(score.topic.rawValue)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                        .frame(width: 34, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.line.opacity(0.35))
                            Capsule().fill(Theme.cinnabar.opacity(0.75))
                                .frame(width: geo.size.width * CGFloat(score.score) / 100)
                        }
                    }
                    .frame(height: 8)
                    Text("\(score.score)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.ink)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider().overlay(Theme.line)
            HStack {
                Text("紫微日常 · 本地排盘")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
                Spacer()
                Text("传统文化参考，不构成决策依据")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
    }

    private func posterSectionTitle(_ title: String) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Theme.cinnabar)
                .frame(width: 3, height: 12)
            Text(title)
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
    }
}

/// 海报用的只读十二宫盘（不含交互）。
private struct PosterGrid: View {
    let chart: Chart
    let layer: TimeLayer

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
                center
                    .frame(width: side * 2, height: side * 2)
                    .position(x: geometry.size.width / 2, y: geometry.size.width / 2)
                ForEach(cells, id: \.branch) { cell in
                    palaceCell(branch: cell.branch)
                        .frame(width: side, height: side)
                        .position(x: (CGFloat(cell.column) + 0.5) * side, y: (CGFloat(cell.row) + 0.5) * side)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(Theme.gold, lineWidth: 1) }
    }

    private var center: some View {
        VStack(spacing: 6) {
            Text(layer.title)
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
                .padding(.horizontal, 8)
            Text(chart.bureau.bureauName)
                .font(.subheadline)
                .foregroundStyle(Theme.cinnabar)
            Text("命在\(Ganzhi.branches[layer.pivotBranch]) · 身在\(Ganzhi.branches[chart.bodyBranch])")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
        }
        .background(Theme.paper)
        .overlay { Rectangle().stroke(Theme.line, lineWidth: 0.7) }
    }

    private func palaceCell(branch: Int) -> some View {
        let palace = chart.palace(at: branch)
        let kind = chart.palaceKind(at: branch, pivot: layer.pivotBranch)
        let isLife = kind == .life
        let marks = layer.transformations.filter { chart.branch(of: $0.star) == branch }
        let selfMarks = chart.selfTransformations(at: branch)
        let longevity = chart.longevitySequence[branch]

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(kind.rawValue)
                    .font(.system(size: 10, weight: isLife ? .bold : .semibold))
                    .foregroundStyle(isLife ? Theme.cinnabar : Theme.ink)
                if palace.branchIndex == chart.bodyBranch {
                    Text("身").font(.system(size: 7)).foregroundStyle(.white)
                        .padding(1.5).background(Theme.jade).clipShape(Circle())
                }
                if branch == chart.minorLimitBranch {
                    Text("限").font(.system(size: 7)).foregroundStyle(.white)
                        .padding(1.5).background(Theme.gold).clipShape(Circle())
                }
                Spacer(minLength: 0)
                Text(Ganzhi.branches[branch]).font(.system(size: 8)).foregroundStyle(Theme.secondaryInk)
            }
            Spacer(minLength: 0)
            Text(mainStarText(branch: branch))
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundStyle(palace.mainStars.isEmpty ? Theme.secondaryInk : Theme.cinnabar)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            if !palace.auxiliaryStars.isEmpty {
                Text(palace.auxiliaryStars.prefix(3).map(\.rawValue).joined(separator: "·"))
                    .font(.system(size: 7))
                    .foregroundStyle(Theme.gold)
                    .lineLimit(1)
            }
            HStack(spacing: 2) {
                ForEach(marks, id: \.star) { item in
                    Text(item.kind.rawValue.replacingOccurrences(of: "化", with: ""))
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 12, height: 12)
                        .background(Theme.transformationColor(item.kind))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                ForEach(selfMarks) { item in
                    Text("自")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(Theme.transformationColor(item.kind))
                        .frame(width: 12, height: 12)
                        .overlay {
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Theme.transformationColor(item.kind), lineWidth: 0.8)
                        }
                }
                Spacer(minLength: 0)
                if let longevity {
                    Text(longevity).font(.system(size: 7)).foregroundStyle(Theme.gold)
                }
                Text("\(palace.decadeStart)").font(.system(size: 7)).foregroundStyle(Theme.secondaryInk)
            }
        }
        .padding(4)
        .background(isLife ? Theme.cinnabarLight.opacity(0.35) : Theme.card)
        .overlay { Rectangle().stroke(Theme.line.opacity(0.8), lineWidth: 0.5) }
    }

    private func mainStarText(branch: Int) -> String {
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

/// 系统分享面板。
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// 长图导出动作：渲染海报并弹出系统分享。
@MainActor
enum PosterExporter {
    static func render(chart: Chart, layer: TimeLayer) -> UIImage? {
        let renderer = ImageRenderer(content: SharePosterView(chart: chart, layer: layer))
        renderer.proposedSize = ProposedViewSize(width: 420, height: nil)
        renderer.scale = 3
        return renderer.uiImage
    }
}
