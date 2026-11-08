import Foundation

public enum Gender: String, Codable, CaseIterable, Sendable {
    case male = "男"
    case female = "女"
}

public enum Element: String, Codable, CaseIterable, Sendable {
    case wood = "木"
    case fire = "火"
    case earth = "土"
    case metal = "金"
    case water = "水"

    public var bureauNumber: Int {
        switch self {
        case .water: 2
        case .wood: 3
        case .metal: 4
        case .earth: 5
        case .fire: 6
        }
    }

    public var bureauName: String { "\(rawValue)\(bureauNumber == 2 ? "二" : bureauNumber == 3 ? "三" : bureauNumber == 4 ? "四" : bureauNumber == 5 ? "五" : "六")局" }

    public func relation(to other: Element) -> ElementRelation {
        if self == other { return .same }
        let generating: [Element: Element] = [.wood: .fire, .fire: .earth, .earth: .metal, .metal: .water, .water: .wood]
        let controlling: [Element: Element] = [.wood: .earth, .earth: .water, .water: .fire, .fire: .metal, .metal: .wood]
        if generating[self] == other { return .generates }
        if generating[other] == self { return .generatedBy }
        if controlling[self] == other { return .controls }
        return .controlledBy
    }
}

public enum ElementRelation: String, Codable, Sendable {
    case same = "同气"
    case generates = "相生向外"
    case generatedBy = "相生得助"
    case controls = "相克主动"
    case controlledBy = "相克受制"
}

public enum PalaceKind: String, Codable, CaseIterable, Sendable {
    case life = "命宫"
    case siblings = "兄弟"
    case spouse = "夫妻"
    case children = "子女"
    case wealth = "财帛"
    case health = "疾厄"
    case travel = "迁移"
    case friends = "交友"
    case career = "官禄"
    case property = "田宅"
    case fortune = "福德"
    case parents = "父母"

    public var focus: String {
        switch self {
        case .life: "整体状态与自我驱动"
        case .siblings: "同辈协作与支持"
        case .spouse: "亲密关系与一对一合作"
        case .children: "创意、成果与晚辈"
        case .wealth: "资源配置与财务节奏"
        case .health: "精力、习惯与恢复"
        case .travel: "外部机会与环境变化"
        case .friends: "社交、人际与团队"
        case .career: "事业推进与责任"
        case .property: "基础、居所与长期积累"
        case .fortune: "内在感受与精神弹性"
        case .parents: "长辈、制度与学习"
        }
    }
}

public enum Star: String, Codable, CaseIterable, Sendable {
    case ziWei = "紫微"
    case tianJi = "天机"
    case taiYang = "太阳"
    case wuQu = "武曲"
    case tianTong = "天同"
    case lianZhen = "廉贞"
    case tianFu = "天府"
    case taiYin = "太阴"
    case tanLang = "贪狼"
    case juMen = "巨门"
    case tianXiang = "天相"
    case tianLiang = "天梁"
    case qiSha = "七杀"
    case poJun = "破军"
    case wenChang = "文昌"
    case wenQu = "文曲"
    case zuoFu = "左辅"
    case youBi = "右弼"
    case tianKui = "天魁"
    case tianYue = "天钺"
    case luCun = "禄存"
    case qingYang = "擎羊"
    case tuoLuo = "陀罗"
    case diKong = "地空"
    case diJie = "地劫"
    case tianMa = "天马"
    case hongLuan = "红鸾"
    case tianXi = "天喜"

    public static let mainStars: [Star] = [
        .ziWei, .tianJi, .taiYang, .wuQu, .tianTong, .lianZhen,
        .tianFu, .taiYin, .tanLang, .juMen, .tianXiang, .tianLiang, .qiSha, .poJun
    ]

    public var isMain: Bool { Self.mainStars.contains(self) }

    public var element: Element? {
        switch self {
        case .tianJi, .tianLiang, .tanLang: .wood
        case .taiYang, .lianZhen, .qiSha: .fire
        case .ziWei, .tianFu, .tianTong: .earth
        case .wuQu, .poJun: .metal
        case .taiYin, .juMen, .tianXiang: .water
        default: nil
        }
    }
}

public enum TransformationKind: String, Codable, CaseIterable, Sendable {
    case lu = "化禄"
    case quan = "化权"
    case ke = "化科"
    case ji = "化忌"
}

public enum TransformationSource: String, Codable, Sendable {
    case birth = "生年"
    case decade = "大限"
    case year = "流年"
    case day = "流日"
}

public struct Transformation: Codable, Equatable, Sendable {
    public let star: Star
    public let kind: TransformationKind
    public let source: TransformationSource

    public init(star: Star, kind: TransformationKind, source: TransformationSource) {
        self.star = star
        self.kind = kind
        self.source = source
    }
}

public struct BirthInput: Codable, Equatable, Sendable {
    public var displayName: String
    public var birthDate: Date
    public var gender: Gender?
    public var birthplace: String
    public var timeZoneIdentifier: String
    public var longitudeText: String
    public var useTrueSolarTime: Bool
    public var lateZiNextDay: Bool

    public init(
        displayName: String = "",
        birthDate: Date,
        gender: Gender? = nil,
        birthplace: String = "",
        timeZoneIdentifier: String = "Asia/Shanghai",
        longitudeText: String = "",
        useTrueSolarTime: Bool = false,
        lateZiNextDay: Bool = true
    ) {
        self.displayName = displayName
        self.birthDate = birthDate
        self.gender = gender
        self.birthplace = birthplace
        self.timeZoneIdentifier = timeZoneIdentifier
        self.longitudeText = longitudeText
        self.useTrueSolarTime = useTrueSolarTime
        self.lateZiNextDay = lateZiNextDay
    }
}

public struct InputIssue: Error, Equatable, Identifiable, Sendable {
    public let field: String
    public let message: String
    public var id: String { field }

    public init(field: String, message: String) {
        self.field = field
        self.message = message
    }
}

public struct InputValidationError: Error, Sendable {
    public let issues: [InputIssue]
    public init(issues: [InputIssue]) { self.issues = issues }
}

public struct LunarDate: Codable, Equatable, Sendable {
    public let gregorianYear: Int
    public let sexagenaryYear: Int
    public let month: Int
    public let day: Int
    public let isLeapMonth: Bool

    public var yearStem: Int { (sexagenaryYear - 1) % 10 }
    public var yearBranch: Int { (sexagenaryYear - 1) % 12 }
    public var yearGanzhi: String { Ganzhi.string(sexagenaryYear - 1) }
    public var monthName: String {
        let names = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
        return "\(isLeapMonth ? "闰" : "")\(names[max(0, min(11, month - 1))])月"
    }
    public var dayName: String {
        let prefixes = ["初", "十", "廿", "卅"]
        let digits = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        if day == 10 { return "初十" }
        if day == 20 { return "二十" }
        if day == 30 { return "三十" }
        return "\(prefixes[(day - 1) / 10])\(digits[(day - 1) % 10])"
    }
    public var displayText: String { "\(yearGanzhi)年 \(monthName)\(dayName)" }
}

public struct ResolvedBirth: Codable, Equatable, Sendable {
    public let adjustedDate: Date
    public let lunarDate: LunarDate
    public let hourBranch: Int
    public let correctionMinutes: Int
}

public struct Palace: Codable, Equatable, Identifiable, Sendable {
    public let kind: PalaceKind
    public let branchIndex: Int
    public let stemIndex: Int
    public let mainStars: [Star]
    public let auxiliaryStars: [Star]
    public let transformations: [Transformation]
    public let isBodyPalace: Bool
    public let decadeStart: Int
    public let decadeEnd: Int

    public var id: Int { branchIndex }
    public var ganzhi: String { "\(Ganzhi.stems[stemIndex])\(Ganzhi.branches[branchIndex])" }
    public var branchName: String { Ganzhi.branches[branchIndex] }
    public var decadeText: String { "\(decadeStart)–\(decadeEnd) 岁" }
}

public struct Chart: Codable, Equatable, Sendable {
    public let input: BirthInput
    public let resolvedBirth: ResolvedBirth
    public let palaces: [Palace]
    public let lifeBranch: Int
    public let bodyBranch: Int
    public let bureau: Element
    public let birthTransformations: [Transformation]
    public let isForwardDecade: Bool

    public func palace(at branch: Int) -> Palace {
        palaces[Ganzhi.mod(branch, 12)]
    }

    public func palace(_ kind: PalaceKind) -> Palace {
        palaces.first { $0.kind == kind }!
    }

    public func branch(of star: Star) -> Int? {
        palaces.first { $0.mainStars.contains(star) || $0.auxiliaryStars.contains(star) }?.branchIndex
    }

    public func stars(at branch: Int) -> [Star] {
        let palace = palace(at: branch)
        return palace.mainStars + palace.auxiliaryStars
    }
}

public struct DimensionScore: Codable, Equatable, Identifiable, Sendable {
    public let title: String
    public let score: Int
    public let note: String
    public var id: String { title }

    public init(title: String, score: Int, note: String) {
        self.title = title
        self.score = score
        self.note = note
    }
}

public struct DailyReport: Codable, Equatable, Sendable {
    public let date: Date
    public let dateKey: String
    public let lunarText: String
    public let dayGanzhi: String
    public let yearGanzhi: String
    public let score: Int
    public let status: String
    public let headline: String
    public let summary: String
    public let activePalace: PalaceKind
    public let activeBranch: Int
    public let dimensions: [DimensionScore]
    public let highlights: [String]
    public let scoringNotes: [String]
    public let recommendedActions: [String]
    public let cautions: [String]
    public let yearTheme: String
    public let decadeTheme: String
    public let dayTransformations: [Transformation]
}
