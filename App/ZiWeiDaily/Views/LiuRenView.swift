import SwiftUI
import UIKit
import ZiWeiCore

/// 顶栏「小六起卦」入口的外观，命盘页与今日页共用，保证两处一致。
struct LiuRenEntryLabel: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.footnote)
            Text("小六起卦")
        }
        .foregroundStyle(Theme.cinnabar)
    }
}

/// 小六壬起课。一件事，此刻起一课，看末宫落处。
struct LiuRenView: View {
    /// 从哪一页进来，只用于返回按钮的无障碍文案（可见文字统一是「返回」）。
    var origin: String = "紫微命盘"

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var log = LiuRenLog.shared

    @State private var question = ""
    @State private var cast: LiuRenCast?
    @State private var revealed = 0
    /// 调试用：直接进课簿。
    @State private var showLog = false
    @FocusState private var questionFocused: Bool

    private var moment: LiuRenCast { LiuRenEngine.cast(on: Date()) }

    /// 调试钩子：逐段隐藏前面的板块，便于脚本逐屏核对后半页。
    private var compact: Int {
        #if DEBUG
        Int(ProcessInfo.processInfo.environment["ZIWEI_LIUREN_COMPACT"] ?? "0") ?? 0
        #else
        0
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if compact < 1 {
                    momentCard
                    questionCard
                    castButton
                }

                if let cast {
                    if compact < 2 { castBoard(cast) }
                    if compact < 3 { verdictCard(cast) }
                    if compact < 4 { stepsCard(cast) }
                    if compact < 5 { palmCard(cast) }
                }

                if compact < 6 { referenceCard }
                if compact < 7 { rulesCard }
                CulturalDisclaimer(text: "小六壬是传统民俗中的一时一课之法，结果仅供自我参照，不是对未来的预测；重大决定请依据事实与专业意见。")
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.paper)
        .navigationTitle("小六壬")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left").font(.body.weight(.semibold))
                        Text("返回")
                    }
                    .foregroundStyle(Theme.cinnabar)
                }
                .accessibilityLabel("返回\(origin)")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    LiuRenLogView()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "book.closed")
                            .font(.footnote)
                        Text("课簿")
                    }
                    .foregroundStyle(Theme.cinnabar)
                }
                .accessibilityLabel("课簿")
            }
        }
        .navigationDestination(isPresented: $showLog) {
            LiuRenLogView()
        }
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.environment["ZIWEI_LIUREN_LOG"] == "1" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showLog = true }
            }
            if ProcessInfo.processInfo.environment["ZIWEI_LIUREN"] == "1" {
                question = "这周谈的合作能签下来吗"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startCast() }
            }
        }
        #endif
    }

    // MARK: - 此刻

    private var momentCard: some View {
        let current = cast ?? moment
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("此刻")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                    Text(current.lunarText)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("\(current.hourBranchName)时 · \(hourRange(current.hourBranch))")
                        .font(.caption)
                        .foregroundStyle(Theme.gold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("今日已起")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryInk)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(min(log.todayCount(), 3)))
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(log.remainingToday > 0 ? Theme.cinnabar : Theme.secondaryInk)
                        Text("/ 3")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                }
            }
            Text(cast == nil
                 ? "起课以此刻为准，用这台设备的时间。"
                 : "已按起课时刻定盘，往下重新起课会换一个新时刻。")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    // MARK: - 所问

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(title: "所问何事", subtitle: "一事一占")

            TextField("比如：这周谈的合作能签下来吗", text: $question, axis: .vertical)
                .font(.body)
                .lineLimit(2...4)
                .focused($questionFocused)
                .padding(12)
                .background(Theme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.line.opacity(0.55), lineWidth: 0.8)
                }

            Text("问得越具体，断语越落得下来。不诚不占、不疑不占、不义不占。")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    // MARK: - 起课

    private var castButton: some View {
        VStack(spacing: 8) {
            Button {
                questionFocused = false
                startCast()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "hand.point.up.left.fill")
                    Text(cast == nil ? "起一课" : "再起一课")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.cinnabar)
            .disabled(!log.canCast())

            Text(log.canCast()
                 ? "一日不过三课，今日还剩 \(log.remainingToday) 次"
                 : "今日三课已满，明日再来。传统上一日不过三，问多了反而不准。")
                .font(.caption2)
                .foregroundStyle(log.canCast() ? Theme.secondaryInk : Theme.gold)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - 三块课牌

    private func castBoard(_ cast: LiuRenCast) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(title: "三步落宫", subtitle: "月看起因 · 日看经过 · 时看结果")

            HStack(spacing: 10) {
                LiuRenCastCard(title: "月", role: "起因", palace: cast.monthPalace, isRevealed: revealed >= 1)
                LiuRenCastCard(title: "日", role: "经过", palace: cast.dayPalace, isRevealed: revealed >= 2)
                LiuRenCastCard(title: "时", role: "结果", palace: cast.hourPalace, isRevealed: revealed >= 3)
            }
        }
    }

    // MARK: - 主断

    private func verdictCard(_ cast: LiuRenCast) -> some View {
        let palace = cast.verdictPalace
        let color = palace.verdict.tint
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(palace.name)
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(color)
                Text(palace.verdict.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                Text(palace.knuckle)
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
            }

            Text(palace.gist)
                .font(.headline)
                .foregroundStyle(Theme.ink)

            HStack(spacing: 6) {
                Image(systemName: "clock")
                Text(palace.pace)
            }
            .font(.caption)
            .foregroundStyle(Theme.gold)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("所问")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
                Text(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "（未写所问，按当下之事而断）"
                     : question.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
            }

            Text(palace.counsel)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .lineSpacing(5)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(palace.classic)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(Theme.secondaryInk)
                    .lineSpacing(3)
                Text("—— 小六壬掌诀歌（历代传抄）")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    // MARK: - 推演过程

    private func stepsCard(_ cast: LiuRenCast) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "怎么数出来的", subtitle: "起点那一宫算第一位")

            ForEach(cast.steps) { step in
                HStack(alignment: .top, spacing: 10) {
                    Text(step.title)
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.cinnabar)
                        .frame(width: 22, height: 22)
                        .background(Theme.cinnabar.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.line)
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                        Text(step.note)
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                }
            }

            Text("六宫依次是大安、留连、速喜、赤口、小吉、空亡，数满一圈接着从大安续。闰月按本月数，闰六月就数六。")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    // MARK: - 掌诀

    private func palmCard(_ cast: LiuRenCast) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "掌诀", subtitle: "左手食、中、无名指")

            PalmKnuckleView(cast: cast)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)

            Text("六宫安在三指六个指节上，以拇指掐着顺数。传统起课就是这么数，不看历书。")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    // MARK: - 六宫参照

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "六宫", subtitle: "吉凶与应期")

            VStack(spacing: 0) {
                ForEach(LiuRenPalace.allCases) { palace in
                    let isCurrent = palace == cast?.verdictPalace
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(palace.name)
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(palace.verdict.tint)
                            .frame(width: 46, alignment: .leading)
                        Text(palace.verdict.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(palace.verdict.tint)
                            .frame(width: 32, alignment: .leading)
                        Text(palace.gist)
                            .font(.caption)
                            .foregroundStyle(isCurrent ? Theme.ink : Theme.secondaryInk)
                        Spacer(minLength: 0)
                        if isCurrent {
                            Image(systemName: "hand.point.up.left.fill")
                                .font(.caption2)
                                .foregroundStyle(Theme.cinnabar)
                        }
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, isCurrent ? 8 : 0)
                    .background(isCurrent ? Theme.goldLight.opacity(0.35) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    if palace != LiuRenPalace.allCases.last {
                        Divider().opacity(0.5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    // MARK: - 说明

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(title: "起课三问", subtitle: "先问自己")

            ForEach(["不诚不占：只是随口试试，就不必起。",
                     "不疑不占：心里没这个疑问，也不必起。",
                     "不义不占：问的是不该问的事，起了也不算。"], id: \.self) { line in
                HStack(alignment: .top, spacing: 8) {
                    Text("·").foregroundStyle(Theme.gold)
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                        .lineSpacing(3)
                }
            }

            Text("小六壬只问单一一件事，不拿来算命。一事一课，问完就放下。")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    // MARK: - 动作

    private func startCast() {
        guard log.canCast() else { return }
        let result = LiuRenEngine.cast(on: Date())
        revealed = 0
        withAnimation(.easeOut(duration: 0.25)) {
            cast = result
        }
        log.add(result, question: question)

        for index in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(index) * 0.3) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
                    revealed = index
                }
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// 子时 23:00–00:59，其余每两小时一时。
    private func hourRange(_ branch: Int) -> String {
        let start = branch == 0 ? 23 : branch * 2 - 1
        let end = (start + 1) % 24
        return String(format: "%02d:00–%02d:59", start, end)
    }
}

// MARK: - 课牌

private struct LiuRenCastCard: View {
    let title: String
    let role: String
    let palace: LiuRenPalace
    let isRevealed: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.card)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Theme.line.opacity(0.5), lineWidth: 0.8)
                }

            // 牌背
            VStack(spacing: 6) {
                Text("壬")
                    .font(.system(size: 26, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.gold.opacity(0.55))
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk.opacity(0.6))
            }
            .opacity(isRevealed ? 0 : 1)

            // 牌面
            VStack(spacing: 5) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
                Text(palace.name)
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundStyle(palace.verdict.tint)
                Text(role)
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk.opacity(0.85))
            }
            .opacity(isRevealed ? 1 : 0)
            .scaleEffect(isRevealed ? 1 : 0.86)
        }
        .frame(height: 112)
        .rotation3DEffect(.degrees(isRevealed ? 0 : -8), axis: (x: 0, y: 1, z: 0))
    }
}

// MARK: - 掌诀图

private struct PalmKnuckleView: View {
    let cast: LiuRenCast

    private let fingers: [[LiuRenPalace]] = [
        [.liuLian, .daAn],   // 食指：上节留连、下节大安
        [.suXi, .kongWang],  // 中指：上节速喜、下节空亡
        [.chiKou, .xiaoJi]   // 无名指：上节赤口、下节小吉
    ]

    private var roles: [LiuRenPalace: [String]] {
        var map: [LiuRenPalace: [String]] = [:]
        map[cast.monthPalace, default: []].append("月")
        map[cast.dayPalace, default: []].append("日")
        map[cast.hourPalace, default: []].append("时")
        return map
    }

    var body: some View {
        // 三指的上节要对齐成一行，才像一只手的指节，所以按顶部对齐、上节等高
        HStack(alignment: .top, spacing: 10) {
            ForEach(fingers.indices, id: \.self) { index in
                finger(fingers[index], height: index == 1 ? 180 : 156)
            }
        }
    }

    private func finger(_ palaces: [LiuRenPalace], height: CGFloat) -> some View {
        let topHeight: CGFloat = 74
        return VStack(spacing: 0) {
            cell(palaces[0], height: topHeight)
            Divider().opacity(0.6)
            cell(palaces[1], height: height - topHeight)
        }
        .frame(width: 62, height: height)
        .background(Theme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Theme.line.opacity(0.7), lineWidth: 0.9)
        }
    }

    private func cell(_ palace: LiuRenPalace, height: CGFloat) -> some View {
        let active = roles[palace] ?? []
        let isVerdict = palace == cast.hourPalace
        return VStack(spacing: 5) {
            Text(palace.name)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(active.isEmpty ? Theme.secondaryInk : palace.verdict.tint)
            if !active.isEmpty {
                HStack(spacing: 2) {
                    ForEach(active, id: \.self) { role in
                        Text(role)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.paper)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(isVerdict ? Theme.cinnabar : Theme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(active.isEmpty ? Color.clear : palace.verdict.tint.opacity(isVerdict ? 0.14 : 0.08))
    }
}

extension LiuRenVerdict {
    /// 吉用朱、不利用金、凶用墨，不用刺目的红绿。
    var tint: Color {
        switch self {
        case .auspicious: Theme.cinnabar
        case .stalled: Theme.gold
        case .inauspicious: Theme.ominous
        }
    }
}
