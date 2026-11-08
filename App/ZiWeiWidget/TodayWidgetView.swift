import SwiftUI
import WidgetKit
import ZiWeiCore

// MARK: - 配色（跟 App 的 Theme 保持一致，但只保留组件用得到的几个）

enum WidgetTheme {
    private static func dyn(_ light: (Int, Int, Int), _ dark: (Int, Int, Int)) -> Color {
        Color(uiColor: UIColor { trait in
            let c = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat(c.0) / 255, green: CGFloat(c.1) / 255,
                           blue: CGFloat(c.2) / 255, alpha: 1)
        })
    }

    static let ink = dyn((41, 37, 34), (237, 231, 221))
    static let secondaryInk = dyn((110, 102, 92), (167, 156, 142))
    static let cinnabar = dyn((169, 41, 31), (210, 86, 74))
    static let gold = dyn((166, 115, 48), (210, 164, 95))
    static let track = dyn((228, 219, 203), (58, 50, 43))

    static var background: LinearGradient {
        LinearGradient(
            colors: [dyn((252, 248, 238), (30, 25, 22)), dyn((243, 234, 216), (16, 13, 11))],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 入口

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let report = entry.report {
            switch family {
            case .systemSmall:
                SmallView(report: report)
            case .systemMedium:
                MediumView(report: report, name: entry.profileName)
            case .accessoryRectangular:
                LockRectView(report: report)
            case .accessoryCircular:
                LockCircleView(report: report)
            case .accessoryInline:
                Text("\(report.score) 分 · \(report.status)")
            default:
                SmallView(report: report)
            }
        } else {
            EmptyHintView(family: family)
        }
    }
}

// MARK: - 小号

private struct SmallView: View {
    let report: DailyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("紫微日常")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(WidgetTheme.secondaryInk)
                Spacer(minLength: 4)
                Text(report.dayGanzhi)
                    .font(.system(size: 9))
                    .foregroundStyle(WidgetTheme.gold)
            }

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                ScoreRing(score: report.score, size: 62, lineWidth: 7)
                VStack(alignment: .leading, spacing: 3) {
                    Text(report.status)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(WidgetTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("落\(report.activePalace.rawValue)")
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetTheme.secondaryInk)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            Text(report.headline)
                .font(.system(size: 10))
                .foregroundStyle(WidgetTheme.secondaryInk)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }
}

// MARK: - 中号

private struct MediumView: View {
    let report: DailyReport
    let name: String

    private var title: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "今日状态" : "\(trimmed) · 今日"
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                ScoreRing(score: report.score, size: 74, lineWidth: 8)
                Text(report.status)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(WidgetTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 84)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetTheme.ink)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(report.dayGanzhi)
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetTheme.gold)
                }

                ForEach(report.dimensions.prefix(4)) { dimension in
                    DimensionBar(dimension: dimension)
                }

                Text(report.headline)
                    .font(.system(size: 9.5))
                    .foregroundStyle(WidgetTheme.secondaryInk)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 1)
            }
        }
    }
}

// MARK: - 锁屏

private struct LockRectView: View {
    let report: DailyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text("紫微日常")
                    .font(.system(size: 11, weight: .semibold))
                Spacer(minLength: 2)
                Text("\(report.score)")
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .widgetAccentable()
            }
            Text(report.status)
                .font(.system(size: 11))
                .widgetAccentable()
            Text(report.headline)
                .font(.system(size: 10))
                .opacity(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LockCircleView: View {
    let report: DailyReport

    var body: some View {
        Gauge(value: Double(report.score), in: 0...100) {
            Text("分")
        } currentValueLabel: {
            Text("\(report.score)")
                .font(.system(size: 15, weight: .semibold, design: .serif))
        }
        .gaugeStyle(.accessoryCircular)
        .widgetAccentable()
    }
}

// MARK: - 未配置

private struct EmptyHintView: View {
    let family: WidgetFamily

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(WidgetTheme.cinnabar)
            Text(family == .systemSmall ? "先打开紫微日常\n排一次盘" : "打开「紫微日常」完成一次排盘，这里就会显示今日状态")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundStyle(WidgetTheme.secondaryInk)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 零件

private struct ScoreRing: View {
    let score: Int
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(WidgetTheme.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, min(1, Double(score) / 100)))
                .stroke(WidgetTheme.cinnabar, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: -1) {
                Text("\(score)")
                    .font(.system(size: size * 0.42, weight: .semibold, design: .serif))
                    .foregroundStyle(WidgetTheme.ink)
                Text("/100")
                    .font(.system(size: size * 0.13))
                    .foregroundStyle(WidgetTheme.secondaryInk)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct DimensionBar: View {
    let dimension: DimensionScore

    var body: some View {
        HStack(spacing: 6) {
            Text(String(dimension.title.prefix(2)))
                .font(.system(size: 9))
                .foregroundStyle(WidgetTheme.secondaryInk)
                .frame(width: 22, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(WidgetTheme.track)
                    Capsule()
                        .fill(WidgetTheme.gold)
                        .frame(width: geo.size.width * CGFloat(dimension.score) / 100)
                }
            }
            .frame(height: 4)
            Text("\(dimension.score)")
                .font(.system(size: 9, weight: .medium).monospacedDigit())
                .foregroundStyle(WidgetTheme.ink)
                .frame(width: 18, alignment: .trailing)
        }
    }
}
