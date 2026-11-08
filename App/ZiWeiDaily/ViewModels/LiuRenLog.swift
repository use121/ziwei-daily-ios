import Foundation
import ZiWeiCore

/// 一次起课的留痕，用于「一日不过三」的计数与回看。
struct LiuRenRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var question: String
    var lunarMonth: Int
    var lunarDay: Int
    var hourBranch: Int
    var monthPalace: Int
    var dayPalace: Int
    var hourPalace: Int

    var verdictPalace: LiuRenPalace {
        LiuRenPalace(rawValue: hourPalace) ?? .daAn
    }
}

@MainActor
final class LiuRenLog: ObservableObject {
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
            hourBranch: cast.hourBranch,
            monthPalace: cast.monthPalace.rawValue,
            dayPalace: cast.dayPalace.rawValue,
            hourPalace: cast.hourPalace.rawValue
        )
        records.insert(record, at: 0)
        if records.count > keepCount { records = Array(records.prefix(keepCount)) }
        persist()
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
