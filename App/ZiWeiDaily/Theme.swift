import SwiftUI

enum Theme {
    static let paper = Color(red: 0.975, green: 0.957, blue: 0.914)
    static let card = Color(red: 1.0, green: 0.992, blue: 0.969)
    static let ink = Color(red: 0.16, green: 0.145, blue: 0.13)
    static let secondaryInk = Color(red: 0.43, green: 0.40, blue: 0.36)
    static let cinnabar = Color(red: 0.66, green: 0.16, blue: 0.12)
    static let cinnabarLight = Color(red: 0.95, green: 0.88, blue: 0.82)
    static let gold = Color(red: 0.65, green: 0.45, blue: 0.18)
    static let goldLight = Color(red: 0.94, green: 0.89, blue: 0.75)
    static let jade = Color(red: 0.20, green: 0.43, blue: 0.34)
    static let line = Color(red: 0.83, green: 0.77, blue: 0.67)

    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: Theme.cinnabar
        case 65..<80: Theme.gold
        case 50..<65: Color(red: 0.65, green: 0.48, blue: 0.28)
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
            .shadow(color: Theme.ink.opacity(0.045), radius: 12, y: 5)
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
