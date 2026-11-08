import SwiftUI
import ZiWeiCore

/// 课簿：起过的课按日留档，事后回来记一句应验与否。
struct LiuRenLogView: View {
    @ObservedObject private var log = LiuRenLog.shared
    @State private var filter: Filter = .all
    /// 调试用：直接推开第一条记录。
    @State private var openID: UUID?

    enum Filter: String, CaseIterable, Identifiable {
        case all = "全部"
        case pending = "待验"
        case done = "已回顾"

        var id: String { rawValue }
    }

    private var groups: [LiuRenDayGroup] {
        log.groups().compactMap { group in
            let records = group.records.filter { record in
                switch filter {
                case .all: true
                case .pending: record.outcome == nil || record.outcome == .pending
                case .done: record.outcome == .matched || record.outcome == .missed
                }
            }
            return records.isEmpty ? nil : LiuRenDayGroup(day: group.day, records: records)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard

                if log.records.isEmpty {
                    emptyCard
                } else {
                    Picker("筛选", selection: $filter) {
                        ForEach(Filter.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    if groups.isEmpty {
                        Text("这个筛选下没有记录。")
                            .font(.callout)
                            .foregroundStyle(Theme.secondaryInk)
                            .ziWeiCard()
                    } else {
                        ForEach(groups) { group in
                            section(group)
                        }
                    }
                }

                CulturalDisclaimer(text: "课簿只记录你自己的回顾，不参与任何推算。应验与否由你判断，App 不做统计性的吉凶评分。")
            }
            .padding(18)
            .padding(.bottom, 92)
        }
        .background(Theme.paper)
        .navigationTitle("课簿")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $openID) { id in
            LiuRenRecordDetailView(recordID: id)
        }
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.environment["ZIWEI_LIUREN_LOG_OPEN"] == "1",
               let first = log.records.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { openID = first.id }
            }
        }
        #endif
    }

    private var summaryCard: some View {
        let matched = log.records.filter { $0.outcome == .matched }.count
        let missed = log.records.filter { $0.outcome == .missed }.count
        let pending = log.records.count - matched - missed
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("已记 \(log.records.count) 课")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("今日还可起 \(log.remainingToday) 课")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
            }
            HStack(spacing: 8) {
                TagPill(text: "待验 \(pending)", color: Theme.gold)
                TagPill(text: "应验 \(matched)", color: Theme.jade)
                TagPill(text: "未应 \(missed)", color: Theme.secondaryInk)
            }
            Text("最多保留最近 40 课。当天第 4 课起不了，是传统「一日不过三」的规矩。")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("还没有起过课")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Theme.ink)
            Text("在小六壬页写下一件想问的事，起一课，记录会留在这里。")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func section(_ group: LiuRenDayGroup) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text(group.title)
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(group.records.count) 课")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
                Spacer()
            }
            ForEach(group.records) { record in
                NavigationLink {
                    LiuRenRecordDetailView(recordID: record.id)
                } label: {
                    row(record)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func row(_ record: LiuRenRecord) -> some View {
        let palace = record.verdictPalace
        return VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                Text(palace.name)
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(palace.verdict.tint)
                Text(palace.verdict.rawValue)
                    .font(.caption2)
                    .foregroundStyle(palace.verdict.tint)
                Spacer()
                Text(timeText(record))
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.secondaryInk.opacity(0.7))
            }

            Text(record.hasQuestion ? record.question : "未写所问")
                .font(.callout)
                .foregroundStyle(record.hasQuestion ? Theme.ink : Theme.secondaryInk)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text("\(ChineseMonthName.text(month: record.lunarMonth, isLeap: record.isLeapMonth))\(ChineseDayName.text(day: record.lunarDay))")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
                Text("·")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk.opacity(0.6))
                Text("\(Ganzhi.branches[record.hourBranch])时")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
                Spacer(minLength: 0)
                if let outcome = record.outcome {
                    Label(outcome.title, systemImage: outcome.symbol)
                        .font(.caption2)
                        .foregroundStyle(outcome == .matched ? Theme.jade : Theme.secondaryInk)
                }
            }

            if !record.note.isEmpty {
                Text("「\(record.note)」")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14).stroke(Theme.line.opacity(0.4))
        }
    }

    private func timeText(_ record: LiuRenRecord) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: record.date)
    }
}

/// 单课详情：复现当时的课盘，并可补记应验与否。
struct LiuRenRecordDetailView: View {
    let recordID: UUID

    @ObservedObject private var log = LiuRenLog.shared
    @State private var outcome: LiuRenOutcome = .pending
    @State private var note = ""
    @State private var loaded = false
    @State private var savedFlash = false

    private var record: LiuRenRecord? { log.record(id: recordID) }

    var body: some View {
        ScrollView {
            if let record {
                VStack(alignment: .leading, spacing: 16) {
                    momentCard(record)
                    castBoard(record.cast)
                    verdictCard(record.cast)
                    stepsCard(record.cast)
                    reviewCard(record)
                    CulturalDisclaimer(text: "课盘按当时的农历日与时辰复现，不会随今天的时间变化。")
                }
                .padding(18)
                .padding(.bottom, 92)
            } else {
                Text("这条记录已经不在了。")
                    .font(.callout)
                    .foregroundStyle(Theme.secondaryInk)
                    .padding(18)
            }
        }
        .background(Theme.paper)
        #if DEBUG
        .defaultScrollAnchor(ProcessInfo.processInfo.environment["ZIWEI_SCROLL_BOTTOM"] == "1" ? .bottom : .top)
        #endif
        .navigationTitle("这一课")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onAppear(perform: load)
        .onDisappear(perform: save)
    }

    // MARK: - 各段

    private func momentCard(_ record: LiuRenRecord) -> some View {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE HH:mm"
        return VStack(alignment: .leading, spacing: 6) {
            Text("起课时刻")
                .font(.caption)
                .foregroundStyle(Theme.secondaryInk)
            Text(formatter.string(from: record.date))
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("农历\(ChineseMonthName.text(month: record.lunarMonth, isLeap: record.isLeapMonth))\(ChineseDayName.text(day: record.lunarDay)) · \(Ganzhi.branches[record.hourBranch])时")
                .font(.caption)
                .foregroundStyle(Theme.gold)
            Text(record.hasQuestion ? record.question : "这一课没有写下所问。")
                .font(.callout)
                .foregroundStyle(record.hasQuestion ? Theme.ink : Theme.secondaryInk)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func castBoard(_ cast: LiuRenCast) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(title: "三宫", subtitle: "月 → 日 → 时")
            HStack(spacing: 9) {
                boardCell("月", cast.monthPalace)
                boardCell("日", cast.dayPalace)
                boardCell("时", cast.hourPalace)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func boardCell(_ title: String, _ palace: LiuRenPalace) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
            Text(palace.name)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(palace.verdict.tint)
            Text(palace.verdict.rawValue)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Theme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12).stroke(Theme.line.opacity(0.4))
        }
    }

    private func verdictCard(_ cast: LiuRenCast) -> some View {
        let palace = cast.verdictPalace
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(palace.name)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(palace.verdict.tint)
                Text(palace.verdict.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palace.verdict.tint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(palace.verdict.tint.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                Text(palace.knuckle)
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryInk)
            }
            Text(palace.gist)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Text(palace.counsel)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Text("「\(palace.classic)」")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(Theme.cinnabar)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func stepsCard(_ cast: LiuRenCast) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionHeading(title: "怎么数出来的", subtitle: "起点那一宫算第一位")
            ForEach(cast.steps) { step in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(step.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.cinnabar)
                        .frame(width: 20, height: 20)
                        .background(Theme.cinnabar.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text(step.line)
                        .font(.footnote)
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    // MARK: - 回顾

    private func reviewCard(_ record: LiuRenRecord) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeading(title: "事后回顾", subtitle: "只给自己看")

            HStack(spacing: 8) {
                ForEach(LiuRenOutcome.allCases) { option in
                    Button {
                        outcome = option
                        save()
                    } label: {
                        Text(option.title)
                            .font(.system(size: 12, weight: outcome == option ? .semibold : .regular))
                            .foregroundStyle(outcome == option ? Theme.cinnabar : Theme.secondaryInk)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(outcome == option ? Theme.cinnabarLight.opacity(0.5) : Theme.paper)
                            )
                            .overlay(
                                Capsule().stroke(Theme.line.opacity(outcome == option ? 0.7 : 0.4), lineWidth: 0.6)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }

            TextField("后来怎么样了？写一句，下次回看时更清楚", text: $note, axis: .vertical)
                .lineLimit(2...5)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .padding(10)
                .background(Theme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onSubmit(save)

            if savedFlash {
                Text("已记下")
                    .font(.caption2)
                    .foregroundStyle(Theme.jade)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ziWeiCard()
    }

    private func load() {
        guard !loaded, let record else { return }
        outcome = record.outcome ?? .pending
        note = record.note
        loaded = true
    }

    private func save() {
        let value: LiuRenOutcome? = outcome == .pending ? nil : outcome
        log.mark(id: recordID, outcome: value, note: note)
        withAnimation(.easeOut(duration: 0.2)) { savedFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) { savedFlash = false }
        }
    }
}
