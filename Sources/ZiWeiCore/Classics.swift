import Foundation

/// 一条古籍断语摘录：原文 + 出处 + 白话。
public struct ClassicQuote: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    /// 关联的格局名（与 PatternEngine 的 name 对应）。
    public let patternName: String
    public let original: String
    public let source: String
    public let plain: String

    public init(patternName: String, original: String, source: String, plain: String) {
        self.id = patternName
        self.patternName = patternName
        self.original = original
        self.source = source
        self.plain = plain
    }
}

/// 公版古籍断语摘编。
///
/// 收录原则：仅取《紫微斗数全书》体系（含《太微赋》《骨髓赋》）中
/// 流传最广、各家传本用字基本一致的句子；传本异文较多的条目不收。
public enum ClassicLibrary {
    public static let quotes: [ClassicQuote] = [
        ClassicQuote(
            patternName: "紫府同宫",
            original: "紫府同宫，终身福厚。",
            source: "《骨髓赋》",
            plain: "紫微、天府同宫守命，主一生根基稳厚，衣食丰足。"
        ),
        ClassicQuote(
            patternName: "君臣庆会",
            original: "君臣庆会，才善经邦。",
            source: "《太微赋》",
            plain: "紫微会齐天府、天相与辅弼昌曲等百官，主有大才、堪当大任。"
        ),
        ClassicQuote(
            patternName: "机月同梁",
            original: "机月同梁，作吏人。",
            source: "《骨髓赋》",
            plain: "天机、太阴、天同、天梁四星会齐，主适合按部就班的文职与专业路线。"
        ),
        ClassicQuote(
            patternName: "府相朝垣",
            original: "府相朝垣，食禄千钟。",
            source: "《骨髓赋》",
            plain: "天府、天相拱照命宫，主俸禄丰厚、生活安定。"
        ),
        ClassicQuote(
            patternName: "七杀朝斗",
            original: "七杀朝斗，爵禄荣昌。",
            source: "《骨髓赋》",
            plain: "七杀朝拱紫微，主以魄力争得地位，武职、开拓性岗位尤佳。"
        ),
        ClassicQuote(
            patternName: "文桂文华",
            original: "文桂文华，九重贵显。",
            source: "《太微赋》",
            plain: "文昌、文曲会照命宫，主文才出众，利于考试、写作与文艺。"
        ),
        ClassicQuote(
            patternName: "科权禄拱",
            original: "科权禄拱，名誉昭彰。",
            source: "《太微赋》",
            plain: "化科、化权、化禄三方拱命，主名声与实力互相成就。"
        ),
        ClassicQuote(
            patternName: "火贪成格",
            original: "贪铃并守，将相之名。",
            source: "《太微赋》",
            plain: "贪狼与火星、铃星同守，主爆发性的机遇与成就；古以将相比喻，今多应突然抬升的财运与声势。"
        ),
        ClassicQuote(
            patternName: "铃贪成格",
            original: "贪铃并守，将相之名。",
            source: "《太微赋》",
            plain: "贪狼与火星、铃星同守，主爆发性的机遇与成就；古以将相比喻，今多应突然抬升的财运与声势。"
        ),
        ClassicQuote(
            patternName: "羊陀夹忌",
            original: "羊陀夹忌，为败局。",
            source: "《太微赋》",
            plain: "擎羊、陀罗夹着化忌之星，主局势受制、易生破败；遇之宜守不宜攻，凡事留余地。"
        )
    ]

    /// 按格局名查摘编（无则 nil）。
    public static func quote(for patternName: String) -> ClassicQuote? {
        quotes.first { $0.patternName == patternName }
    }
}
