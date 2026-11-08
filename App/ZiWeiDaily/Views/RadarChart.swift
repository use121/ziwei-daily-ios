import SwiftUI
import ZiWeiCore

/// 六维雷达图：把核心六维的强弱画成一张图，一眼看出结构偏斜。
struct RadarChart: View {
    let scores: [TopicScore]

    private var core: [TopicScore] {
        scores.filter { $0.topic.isCore }
    }

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)
                let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                let radius = size / 2 - 26

                ZStack {
                    // 网格
                    ForEach(1...4, id: \.self) { ring in
                        polygon(center: center, radius: radius * CGFloat(ring) / 4, count: core.count)
                            .stroke(Theme.line.opacity(ring == 4 ? 0.65 : 0.3), lineWidth: 0.6)
                    }
                    // 轴线
                    ForEach(0..<core.count, id: \.self) { index in
                        Path { path in
                            path.move(to: center)
                            path.addLine(to: point(index: index, center: center, radius: radius, count: core.count))
                        }
                        .stroke(Theme.line.opacity(0.35), lineWidth: 0.6)
                    }
                    // 数据面
                    polygon(
                        center: center,
                        radius: radius,
                        count: core.count,
                        values: core.map { CGFloat($0.score) / 100 }
                    )
                    .fill(Theme.cinnabar.opacity(0.16))
                    polygon(
                        center: center,
                        radius: radius,
                        count: core.count,
                        values: core.map { CGFloat($0.score) / 100 }
                    )
                    .stroke(Theme.cinnabar.opacity(0.7), lineWidth: 1.4)
                    // 顶点
                    ForEach(Array(core.enumerated()), id: \.element.id) { index, item in
                        Circle()
                            .fill(Theme.cinnabar)
                            .frame(width: 4, height: 4)
                            .position(point(index: index, center: center, radius: radius * CGFloat(item.score) / 100, count: core.count))
                    }
                    // 标签
                    ForEach(Array(core.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 1) {
                            Text(item.topic.rawValue)
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.ink)
                            Text("\(item.score)")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.secondaryInk)
                        }
                        .position(point(index: index, center: center, radius: radius + 17, count: core.count))
                    }
                }
            }
            .frame(height: 218)

            Text("评分为规则化推算的相对强弱，用于比较自身各维度，不用于人与人之间比较。")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func point(index: Int, center: CGPoint, radius: CGFloat, count: Int) -> CGPoint {
        guard count > 0 else { return center }
        let angle = -CGFloat.pi / 2 + CGFloat(index) * 2 * CGFloat.pi / CGFloat(count)
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }

    private func polygon(
        center: CGPoint,
        radius: CGFloat,
        count: Int,
        values: [CGFloat]? = nil
    ) -> Path {
        Path { path in
            guard count > 0 else { return }
            for index in 0..<count {
                let ratio = values?[index] ?? 1
                let current = point(index: index, center: center, radius: radius * ratio, count: count)
                if index == 0 {
                    path.move(to: current)
                } else {
                    path.addLine(to: current)
                }
            }
            path.closeSubpath()
        }
    }
}
