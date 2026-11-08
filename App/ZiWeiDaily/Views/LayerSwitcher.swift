import SwiftUI
import ZiWeiCore

/// 本命 / 大限 / 流年 切换器。命盘页与解读页共用，保证两处时间层始终一致。
struct LayerSwitcher: View {
    @EnvironmentObject private var state: AppState
    var showsOverlay: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                ForEach(TimeLayerKind.allCases) { kind in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { state.selectLayer(kind) }
                    } label: {
                        Text(kind.rawValue)
                            .font(.system(size: 13, weight: state.selectedLayer == kind ? .semibold : .regular))
                            .foregroundStyle(state.selectedLayer == kind ? Theme.cinnabar : Theme.secondaryInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(state.selectedLayer == kind ? Theme.cinnabarLight.opacity(0.55) : .clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(state.selectedLayer == kind ? Theme.cinnabar.opacity(0.35) : .clear, lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Theme.paper.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            contextRow

            if showsOverlay, let layer = state.currentLayer, layer.hasTransformations {
                overlayRow(layer)
            }
        }
    }

    @ViewBuilder
    private var contextRow: some View {
        if let layer = state.currentLayer {
            HStack(spacing: 8) {
                if state.selectedLayer == .natal {
                    Text(layer.subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                } else {
                    Button { withAnimation { state.stepLayer(by: -1) } } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                            .frame(width: 26, height: 24)
                            .background(Theme.goldLight.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Text(layer.title)
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(minWidth: 108)
                        .contentTransition(.numericText())

                    Button { withAnimation { state.stepLayer(by: 1) } } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                            .frame(width: 26, height: 24)
                            .background(Theme.goldLight.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Text(layer.subtitle)
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func overlayRow(_ layer: TimeLayer) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(layer.stemName)干四化 · \(layer.kind.rawValue)层")
                .font(.system(size: 10))
                .foregroundStyle(Theme.secondaryInk)
            FlowLayout() {
                ForEach(layer.transformations, id: \.star) { item in
                    Text("\(item.star.rawValue)化\(item.kind.rawValue.replacingOccurrences(of: "化", with: ""))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.transformationColor(item.kind))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.transformationColor(item.kind).opacity(0.10))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.line.opacity(0.4), lineWidth: 0.6)
        }
    }
}
