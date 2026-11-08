import SwiftUI
import ZiWeiCore

enum Theme {
    /// 浅色 / 深色双值。用 UIColor 的动态色，跟随系统外观自动切换，
    /// 调用处仍然写 Theme.paper，不需要改任何视图代码。
    private static func dyn(_ light: (Int, Int, Int), _ dark: (Int, Int, Int)) -> Color {
        Color(uiColor: UIColor { trait in
            let c = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat(c.0) / 255, green: CGFloat(c.1) / 255,
                           blue: CGFloat(c.2) / 255, alpha: 1)
        })
    }

    // 纸与墨：白天是宣纸，夜里是墨底
    static let paper = dyn((249, 244, 233), (20, 17, 15))
    static let card = dyn((255, 253, 247), (35, 30, 26))
    static let ink = dyn((41, 37, 34), (237, 231, 221))
    static let secondaryInk = dyn((110, 102, 92), (167, 156, 142))

    // 朱砂：深底上要提亮，否则发闷
    static let cinnabar = dyn((169, 41, 31), (210, 86, 74))
    static let cinnabarLight = dyn((242, 224, 209), (58, 33, 28))

    static let gold = dyn((166, 115, 48), (210, 164, 95))
    static let goldLight = dyn((240, 227, 191), (51, 40, 26))
    static let jade = dyn((51, 110, 87), (111, 178, 149))
    static let line = dyn((212, 197, 171), (68, 59, 51))
    static let azurite = dyn((56, 84, 120), (127, 163, 201))

    /// 卡片投影：深色下必须用真黑，不能拿 ink 当底色
    static let shadow = dyn((0, 0, 0), (0, 0, 0))

    /// 四化配色：禄（玉）、权（石青）、科（金）、忌（朱砂）
    static func transformationColor(_ kind: TransformationKind) -> Color {
        switch kind {
        case .lu: Theme.jade
        case .quan: Theme.azurite
        case .ke: Theme.gold
        case .ji: Theme.cinnabar
        }
    }

    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: Theme.cinnabar
        case 65..<80: Theme.gold
        case 50..<65: Theme.gold.opacity(0.85)
        default: Theme.secondaryInk
        }
    }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.line.opacity(0.45), lineWidth: 0.7)
            }
            .shadow(color: Theme.shadow.opacity(0.05), radius: 12, y: 5)
    }
}

extension View {
    func ziWeiCard(padding: CGFloat = 18) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
    }
}

struct TagPill: View {
    let text: String
    var color: Color = Theme.cinnabar

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle().fill(Theme.cinnabarLight).frame(width: 110, height: 110)
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.cinnabar)
            }
            VStack(spacing: 8) {
                Text(title).font(.system(.title2, design: .serif, weight: .semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryInk)
                    .multilineTextAlignment(.center)
            }
            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
    }
}

struct CulturalDisclaimer: View {
    var body: some View {
        Label("排盘与评分基于传统文化规则，仅作自我观察与娱乐参考，不是科学测评；请勿替代医疗、投资、法律等专业意见。", systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(Theme.secondaryInk)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.goldLight.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
