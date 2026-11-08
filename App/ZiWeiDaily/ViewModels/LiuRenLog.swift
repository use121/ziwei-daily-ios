import Foundation
import ZiWeiCore

/// 一次起课后来到底应没应。只是给自己留个记录，不参与任何计算。
enum LiuRenOutcome: String, Codable, CaseIterable, Identifiable {
    case pending
    case matched
    case missed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: "待验"
        case .matched: "已应验"
        case .missed: "未应验"
        }
    }

    var symbol: String {
        switch self {
        case .pending: "clock"
        case .matched: "checkmark.circle"
        case .missed: "xmark.circle"
        }
    }
}

/// 一次起课的留痕，用于「一日不过三」的计数与回看。
struct LiuRenRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var question: String
    var lunarMonth: Int
    var lunarDay: Int
    var isLeapMonth: Bool = false
    var hourBranch: Int
    var monthPalace: Int
    var dayPalace: Int
    var hourPalace: Int
    /// 事后回顾：应验与否 + 一句说明。旧记录没有这两项，解码时给默认值。
    var outcome: LiuRenOutcome? = nil
    var note: String = ""

    var verdictPalace: LiuRenPalace {
        LiuRenPalace(rawValue: hourPalace) ?? .daAn
    }

    /// 用记录里的月日时把当时的课盘复现出来，与起课时逐字一致。
    var cast: LiuRenCast {
        LiuRenEngine.replay(
            lunarMonth: lunarMonth,
            lunarDay: lunarDay,
            isLeapMonth: isLeapMonth,
            hourBranch: hourBranch,
            moment: date
        )
    }

    var hasQuestion: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension LiuRenRecord {
    /// 手写解码：v1.7.0 / v1.8.x 存下来的记录没有 isLeapMonth、outcome、note，
    /// 缺字段时用默认值补上，而不是让整批记录解码失败。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        question = try container.decodeIfPresent(String.self, forKey: .question) ?? ""
        lunarMonth = try container.decode(Int.self, forKey: .lunarMonth)
        lunarDay = try container.decode(Int.self, forKey: .lunarDay)
        isLeapMonth = try container.decodeIfPresent(Bool.self, forKey: .isLeapMonth) ?? false
        hourBranch = try container.decode(Int.self, forKey: .hourBranch)
        monthPalace = try container.decode(Int.self, forKey: .monthPalace)
        dayPalace = try container.decode(Int.self, forKey: .dayPalace)
        hourPalace = try container.decode(Int.self, forKey: .hourPalace)
        outcome = try container.decodeIfPresent(LiuRenOutcome.self, forKey: .outcome)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}

@MainActor
final class LiuRenLog: ObservableObject {
    /// 起课页与课簿共用一个实例，避免两边各持一份、后写入的把先写入的覆盖掉。
    static let shared = LiuRenLog()

    @Published private(set) var records: [LiuRenRecord] = []

    private let storageKey = "ziwei.daily.liuren.v1"
    private let dailyLimit = 3
    private let keepCount = 40

    init() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        records = (try? decoder.decode([LiuRenRecord].self, from: data)) ?? []
    }

    /// 传统上一日不过三课，这里按设备的自然日计。
    func todayCount(on date: Date = Date()) -> Int {
        let key = ChineseCalendarConverter.localDateKey(date, timeZone: .current)
        return records.filter {
            ChineseCalendarConverter.localDateKey($0.date, timeZone: .current) == key
        }.count
    }

    var remainingToday: Int {
        max(0, dailyLimit - todayCount())
    }

    func canCast(on date: Date = Date()) -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.environment["ZIWEI_LIUREN_UNLIMITED"] == "1" { return true }
        #endif
        return todayCount(on: date) < dailyLimit
    }

    func add(_ cast: LiuRenCast, question: String) {
        let record = LiuRenRecord(
            date: cast.moment,
            question: question.trimmingCharacters(in: .whitespacesAndNewlines),
            lunarMonth: cast.lunarMonth,
            lunarDay: cast.lunarDay,
            isLeapMonth: cast.isLeapMonth,
            hourBranch: cast.hourBranch,
            monthPalace: cast.monthPalace.rawValue,
            dayPalace: cast.dayPalace.rawValue,
            hourPalace: cast.hourPalace.rawValue
        )
        records.insert(record, at: 0)
        if records.count > keepCount { records = Array(records.prefix(keepCount)) }
        persist()
    }

    func record(id: UUID) -> LiuRenRecord? {
        records.first { $0.id == id }
    }

    /// 记下应验与否和一句后记。字段没变就不写盘。
    func mark(id: UUID, outcome: LiuRenOutcome?, note: String) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard records[index].outcome != outcome || records[index].note != trimmed else { return }
        records[index].outcome = outcome
        records[index].note = trimmed
        persist()
    }

    /// 按自然日分组，最新的一天在前。
    func groups(calendar: Calendar = .current) -> [LiuRenDayGroup] {
        var order: [Date] = []
        var buckets: [Date: [LiuRenRecord]] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.date)
            if buckets[day] == nil { order.append(day) }
            buckets[day, default: []].append(record)
        }
        return order
            .sorted(by: >)
            .map { LiuRenDayGroup(day: $0, records: buckets[$0] ?? []) }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

struct LiuRenDayGroup: Identifiable {
    let day: Date
    let records: [LiuRenRecord]

    var id: Date { day }

    /// 「今天 / 昨天 / 11月6日 星期四」
    var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "今天" }
        if calendar.isDateInYesterday(day) { return "昨天" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: day)
    }
}
