import Foundation

// MARK: - 格局摘句

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

// MARK: - 星性古义

/// 一颗星的古义条目：古籍原文 + 现代解读。
///
/// 原文多取《形性赋》，该篇以形貌写星性，是十四主星最凝练的性格描述；
/// 古书对相貌、出身的评断带有时代偏见，本条目只取「性情与取向」一层，不作评价。
public struct StarVerse: Identifiable, Codable, Equatable, Sendable {
    public let star: Star
    public let title: String
    public let original: String
    public let source: String
    public let plain: String
    /// 这颗星在实务里最常见的两种表现。
    public let traits: [String]

    public var id: String { star.rawValue }
}

// MARK: - 古籍篇章

/// 古籍中的一个段落。
public struct ClassicPassage: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    /// 段落所属小节标题，用于分段阅读。
    public let section: String
    public let original: String
    public let plain: String
    /// 「今按」：对原文中宿命论或时代偏见表述的说明，可空。
    public let note: String?

    public init(id: String, section: String, original: String, plain: String, note: String? = nil) {
        self.id = id
        self.section = section
        self.original = original
        self.plain = plain
        self.note = note
    }
}

/// 一部古籍。
public struct ClassicWork: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let title: String
    public let subtitle: String
    public let author: String
    public let era: String
    public let intro: String
    /// 收录说明（底本、删略条目、阅读提示）。
    public let note: String
    public let passages: [ClassicPassage]

    public var id: String { title }

    /// 按小节分组后的段落，保持原顺序。
    public var sections: [(title: String, passages: [ClassicPassage])] {
        var order: [String] = []
        var buckets: [String: [ClassicPassage]] = [:]
        for passage in passages {
            if buckets[passage.section] == nil { order.append(passage.section) }
            buckets[passage.section, default: []].append(passage)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }

    public var wordCount: Int {
        passages.reduce(0) { $0 + $1.original.count }
    }
}

// MARK: - 检索

/// 古籍检索命中。
public struct ClassicHit: Identifiable, Sendable {
    public let id: String
    /// 所属篇名或分类。
    public let title: String
    public let original: String
    public let plain: String
    public let source: String
}

// MARK: - 库

/// 公版古籍库。
///
/// 收录范围：
/// - 《太微赋》《斗数骨髓赋》《形性赋》三篇全文（明刊《紫微斗数全书》体系，公版）。
/// - 与格局对应的断语摘句，供格局卡直接引用。
/// - 十四主星与主要辅煞的星性古义。
///
/// 编纂原则：
/// 1. 三篇照录，只做分段与标点，不改字；异文较多的字取通行本。
/// 2. 涉及自伤方式与人身侮辱的两类句子不录，在各篇 note 里逐条列明，便于查对。
/// 3. 其余宿命论式的绝对断语照录，但紧跟「今按」说明其时代语境，供读者辨析而非采信。
public enum ClassicLibrary {

    /// 三篇全文，见 ClassicTexts。
    public static let works: [ClassicWork] = ClassicTexts.works

    /// 按格局名查摘句（无则 nil）。
    public static func quote(for patternName: String) -> ClassicQuote? {
        quotes.first { $0.patternName == patternName }
    }

    /// 按星曜查星性古义。
    public static func verse(for star: Star) -> StarVerse? {
        starVerses.first { $0.star == star }
    }

    /// 按篇名查古籍。
    public static func work(_ title: String) -> ClassicWork? {
        works.first { $0.title == title }
    }

    /// 全文检索：原文、白话、出处三处匹配。
    public static func search(_ query: String, limit: Int = 40) -> [ClassicHit] {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return [] }
        var hits: [ClassicHit] = []

        for work in works {
            for passage in work.passages
            where passage.original.contains(keyword)
                || passage.plain.contains(keyword)
                || work.title.contains(keyword) {
                hits.append(ClassicHit(
                    id: passage.id,
                    title: work.title,
                    original: passage.original,
                    plain: passage.plain,
                    source: passage.section
                ))
                if hits.count >= limit { return hits }
            }
        }

        for quote in quotes
        where quote.original.contains(keyword) || quote.plain.contains(keyword) || quote.patternName.contains(keyword) {
            hits.append(ClassicHit(
                id: "quote-\(quote.id)",
                title: "格局摘句 · \(quote.patternName)",
                original: quote.original,
                plain: quote.plain,
                source: quote.source
            ))
            if hits.count >= limit { return hits }
        }

        for verse in starVerses
        where verse.original.contains(keyword) || verse.plain.contains(keyword) || verse.star.rawValue.contains(keyword) {
            hits.append(ClassicHit(
                id: "verse-\(verse.id)",
                title: "星性古义 · \(verse.star.rawValue)",
                original: verse.original,
                plain: verse.plain,
                source: verse.source
            ))
            if hits.count >= limit { return hits }
        }

        return hits
    }

    // MARK: 格局摘句

    /// 与格局对应的古籍断语。
    ///
    /// 取句原则：只取流传最广、各家传本用字基本一致的句子；
    /// 原文若带明显宿命论，白话一栏改写为可执行的读法，不改原文。
    public static let quotes: [ClassicQuote] = [
        ClassicQuote(
            patternName: "紫府同宫",
            original: "紫府同宫，终身福厚。",
            source: "《骨髓赋》",
            plain: "紫微、天府同宫守命，主一生根基稳厚，衣食丰足。"
        ),
        ClassicQuote(
            patternName: "紫府朝垣",
            original: "紫府朝垣，食禄万钟。",
            source: "《骨髓赋》",
            plain: "紫微、天府分守三方拱命，主资源与人脉两头都有依托。"
        ),
        ClassicQuote(
            patternName: "极向离明",
            original: "紫微居午，无杀凑，位至公卿。",
            source: "《骨髓赋》",
            plain: "紫微坐午为得位，若不再逢煞星相扰，气局最正，宜承担要职。"
        ),
        ClassicQuote(
            patternName: "天府临戌",
            original: "天府临戌，有星扶，腰金衣紫。",
            source: "《骨髓赋》",
            plain: "天府在戌为得地，再得吉星扶助，主守成有法、家业稳固。"
        ),
        ClassicQuote(
            patternName: "君臣庆会",
            original: "君臣庆会，材善经邦。",
            source: "《太微赋》",
            plain: "紫微会齐辅弼魁钺等百官，主有统筹之才，能担大事。"
        ),
        ClassicQuote(
            patternName: "府相朝垣",
            original: "府相同来会命宫，全家食禄。",
            source: "《骨髓赋》",
            plain: "天府、天相拱照命宫，主衣食安定、家宅有靠。"
        ),
        ClassicQuote(
            patternName: "月朗天门",
            original: "月朗天门，进爵封侯。",
            source: "《骨髓赋》",
            plain: "太阴坐亥为得地，主清贵细腻，宜文教、财务与需要长期沉淀的事。"
        ),
        ClassicQuote(
            patternName: "日照雷门",
            original: "日照雷门，富贵荣华。",
            source: "《骨髓赋》",
            plain: "太阳坐卯，如日出东方，主光明外显，宜公开表达与担当之职。"
        ),
        ClassicQuote(
            patternName: "石中隐玉",
            original: "子午巨门，石中隐玉。",
            source: "《骨髓赋》",
            plain: "巨门坐子午，才学藏于内，早年不显，越往后越见价值。"
        ),
        ClassicQuote(
            patternName: "七杀朝斗",
            original: "七杀朝斗，爵禄荣昌。",
            source: "《骨髓赋》",
            plain: "七杀朝拱紫微，主以魄力争得地位，宜开拓与需要决断的岗位。"
        ),
        ClassicQuote(
            patternName: "日月同宫",
            original: "日月同临，官居侯伯。",
            source: "《骨髓赋》",
            plain: "太阳、太阴同宫于丑未，刚柔并存，主视角完整、能兼顾两面。"
        ),
        ClassicQuote(
            patternName: "日月夹命",
            original: "日月夹财，不权则富。",
            source: "《太微赋》",
            plain: "日月夹拱，主环境给过明确支持；夹财位则偏财禄，夹命则偏照拂。"
        ),
        ClassicQuote(
            patternName: "巨日同宫",
            original: "巨日同宫，官封三代。",
            source: "《骨髓赋》",
            plain: "巨门得太阳照亮，暗曜化明，主以口才、专业与解释力立业。"
        ),
        ClassicQuote(
            patternName: "明珠出海",
            original: "三合明珠生旺地，稳步蟾宫。",
            source: "《骨髓赋》",
            plain: "空宫得日月拱照，如珠出海，主后天借势出头，宜向外发展。"
        ),
        ClassicQuote(
            patternName: "天同天梁",
            original: "寅申最喜同梁会。",
            source: "《骨髓赋》",
            plain: "天同、天梁相会于寅申，福星与荫星同气，主厚道、宜助人之业。"
        ),
        ClassicQuote(
            patternName: "马头带箭",
            original: "马头带剑，镇卫边疆。",
            source: "《太微赋》",
            plain: "擎羊坐午，锐气最盛，主敢冲敢拼；古以镇守边疆比喻，今多应竞争性强的岗位。"
        ),
        ClassicQuote(
            patternName: "禄马交驰",
            original: "禄马最喜交驰。",
            source: "《太微赋》",
            plain: "禄存与天马同会，动静相配，主在流动与跨域中生财。"
        ),
        ClassicQuote(
            patternName: "武贪格",
            original: "先贫后富，武贪同身命之宫。",
            source: "《骨髓赋》",
            plain: "武曲、贪狼同守身命，早年资源紧、后段才把人和钱串起来，属后发结构。"
        ),
        ClassicQuote(
            patternName: "火贪成格",
            original: "贪狼火星居庙旺，名镇诸邦。",
            source: "《骨髓赋》",
            plain: "贪狼与火星同宫且贪狼庙旺，主突发性的机会与声势，来得快也去得快。"
        ),
        ClassicQuote(
            patternName: "铃贪成格",
            original: "贪铃并守，将相之名。",
            source: "《太微赋》",
            plain: "贪狼与铃星同守，力量偏内，主在不被注意处积累，条件成熟再出手。"
        ),
        ClassicQuote(
            patternName: "天马入命",
            original: "天禄天马，惊人甲第。",
            source: "《骨髓赋》",
            plain: "禄存与天马相配，主奔波中得利，宜跨区域、跨团队的机会。"
        ),
        ClassicQuote(
            patternName: "文桂文华",
            original: "文桂文华，九重贵显。",
            source: "《骨髓赋》",
            plain: "文昌、文曲会照命宫，主文才出众，利于考试、写作与文艺。"
        ),
        ClassicQuote(
            patternName: "科权禄拱",
            original: "科权禄拱，名誉昭彰。",
            source: "《骨髓赋》",
            plain: "化科、化权、化禄三方拱命，主名声与实力互相成就，属窗口期结构。"
        ),
        ClassicQuote(
            patternName: "科权双会",
            original: "科权对拱，跃三汲于禹门。",
            source: "《骨髓赋》",
            plain: "化科与化权对照拱命，主先立信再掌事，宜走专业权威路线。"
        ),
        ClassicQuote(
            patternName: "昌曲夹命",
            original: "夹昌夹曲主贵兮。",
            source: "《骨髓赋》",
            plain: "文昌、文曲分居命宫两侧，主聪明早显，读书与表达顺。"
        ),
        ClassicQuote(
            patternName: "辅弼夹命",
            original: "辅弼夹帝为上品。",
            source: "《太微赋》",
            plain: "左右夹辅帝星为上层结构，主一生有人可托，适合团队作战。"
        ),
        ClassicQuote(
            patternName: "辅弼同会",
            original: "紫微辅弼同宫，一呼百诺居上品。",
            source: "《太微赋》",
            plain: "紫微得辅弼同宫，主号召力强、能拢住人，宜组织与协调之职。"
        ),
        ClassicQuote(
            patternName: "魁钺同会",
            original: "魁钺同行，位居台辅。",
            source: "《太微赋》",
            plain: "天魁、天钺同会，主贵人提携，关键时刻容易遇到愿意指路的人。"
        ),
        ClassicQuote(
            patternName: "羊陀夹忌",
            original: "夹羊夹陀为乞丐。",
            source: "《骨髓赋》",
            plain: "羊陀夹命古以为困顿之象；今读为进退皆受制、事情容易左右掣肘，宜缩小范围、分步推进。"
        ),
        ClassicQuote(
            patternName: "羊陀夹命",
            original: "夹羊夹陀为乞丐。",
            source: "《骨髓赋》",
            plain: "擎羊、陀罗夹命，外部感受常是「不做也难受、做了也费劲」，宜把目标切小。"
        ),
        ClassicQuote(
            patternName: "空劫夹命",
            original: "夹空夹劫主贫贱。",
            source: "《骨髓赋》",
            plain: "空劫夹命古以为财不聚；今读为对物质的黏性低、计划易被打断，宜把重要的事写成流程。"
        ),
        ClassicQuote(
            patternName: "命里逢空",
            original: "命里逢空，不飘流即主疾苦。",
            source: "《骨髓赋》",
            plain: "空劫坐命古作漂泊之论；今读为得失看得开、计划易落空，宜靠流程而非靠状态。"
        ),
        ClassicQuote(
            patternName: "廉杀羊",
            original: "羊陀七杀，相杂互见则伤。",
            source: "《骨髓赋》",
            plain: "煞星与七杀混杂，主刚烈易起冲突；读法是先问争的值不值，安全与手续别省。"
        ),
        ClassicQuote(
            patternName: "巨门化忌",
            original: "巨门忌星皆不吉。",
            source: "《骨髓赋》",
            plain: "巨门化忌的重点在「说」与「被理解」的落差，重要沟通宜留下文字。"
        ),
        ClassicQuote(
            patternName: "杀破狼",
            original: "七杀破军宜出外。",
            source: "《骨髓赋》",
            plain: "七杀、破军主变动与开创，宜向外闯；守成之事反而不易发挥。"
        ),
        ClassicQuote(
            patternName: "机月同梁",
            original: "机月同梁作吏人。",
            source: "《骨髓赋》",
            plain: "天机、太阴、天同、天梁齐会，偏文职与规划，宜在既有体系里做深。"
        ),
        ClassicQuote(
            patternName: "机月同梁三星会",
            original: "机月同梁作吏人。",
            source: "《骨髓赋》",
            plain: "四星未齐时仍偏文职路线，但少了成格的加持，力量减一档。"
        ),
        ClassicQuote(
            patternName: "命无正曜",
            original: "命无正曜，夭折孤贫。",
            source: "《骨髓赋》",
            plain: "古书对空宫多有重语；今读为命宫无主星者，环境与选择的权重更大，靠借对宫之力安身。"
        )
    ]

    // MARK: 星性古义

    public static let starVerses: [StarVerse] = [
        StarVerse(
            star: .ziWei,
            title: "帝座 · 统筹",
            original: "紫微帝座，生为厚重之容。",
            source: "《形性赋》",
            plain: "紫微为帝座，古书以「厚重」写其气度。落到性子上，是在意分寸与位置、习惯从全局看事，遇事第一反应是「这件事该由谁定」。",
            traits: ["愿意担责，也容易放不下主导权", "需要有人帮衬，独木难支"]
        ),
        StarVerse(
            star: .tianJi,
            title: "善星 · 机变",
            original: "天机为不长不短之姿，情怀好善。",
            source: "《形性赋》",
            plain: "天机主谋略与变化，心思快、设想多，容易同时开好几条线。长处是方案多，短处是收口慢。",
            traits: ["擅长研究、优化与推演", "想法多时要强制落地一件"]
        ),
        StarVerse(
            star: .taiYang,
            title: "金乌 · 外显",
            original: "金乌圆满。",
            source: "《形性赋》",
            plain: "太阳为金乌，主光明与外显。表现为愿意公开、愿意负责、在群体里自然被看见；代价是容易被期待绑住。",
            traits: ["表达与担当是优势", "精力要分批释放，别一次燃尽"]
        ),
        StarVerse(
            star: .wuQu,
            title: "财星 · 果决",
            original: "武曲乃至要至紧之操，心性果决。",
            source: "《形性赋》",
            plain: "武曲主执行与数字，性子直、决定快，对「有没有用」很敏感。长处是效率，短处是容易忽略人的感受。",
            traits: ["适合明确目标与量化的事", "表达可柔和一些"]
        ),
        StarVerse(
            star: .tianTong,
            title: "福星 · 随缘",
            original: "天同肥满，目秀清奇。",
            source: "《形性赋》",
            plain: "天同主福气与舒适，性情温和、不喜冲突，遇事先找缓冲。长处是让人放松，短处是容易把该做的事往后放。",
            traits: ["擅长协调与恢复", "别用「顺其自然」替代决定"]
        ),
        StarVerse(
            star: .lianZhen,
            title: "囚星 · 原则",
            original: "廉贞眉宽，口阔面横，为人性暴，好忿好争。",
            source: "《形性赋》",
            plain: "廉贞主原则与边界，古书以「好忿好争」写其刚烈。落到今天，是对错感强、遇不公容易上头；这份劲用对地方就是担当。",
            traits: ["适合需要判断力与底线的事", "较劲之前先确认标准"]
        ),
        StarVerse(
            star: .tianFu,
            title: "库星 · 稳厚",
            original: "天府尊星，也作纯和之体。",
            source: "《形性赋》",
            plain: "天府为库，主积累与守成。表现为稳、能扛、对长期资产有感觉；课题是不轻易冒险，转身偏慢。",
            traits: ["适合经营长期事项", "别因求稳错过窗口"]
        ),
        StarVerse(
            star: .taiYin,
            title: "玉兔 · 细腻",
            original: "玉兔清奇。",
            source: "《形性赋》",
            plain: "太阴为玉兔，主感受与细致。对氛围、细节、他人情绪都敏感，适合需要耐心与审美的方向；容易内耗。",
            traits: ["适合复盘、写作、财务整理", "模糊信息要直接确认"]
        ),
        StarVerse(
            star: .tanLang,
            title: "桃花 · 多欲",
            original: "贪狼为善恶之星，入庙必应长耸，出垣必定顽嚣。",
            source: "《形性赋》",
            plain: "贪狼主欲望与才艺，兴趣广、上手快、社交有天赋。古书以「善恶之星」写其可塑性——用在哪里，就长成什么样。",
            traits: ["擅长把人和机会串起来", "机会太多时，选择比努力关键"]
        ),
        StarVerse(
            star: .juMen,
            title: "暗曜 · 辨析",
            original: "巨门乃是非之曜，在庙敦厚温良。",
            source: "《形性赋》",
            plain: "巨门主口舌与辨析，得地时敦厚，落陷时多疑。长处是能问出关键问题，短处是话容易说重。",
            traits: ["适合查证、谈判、教学", "先讲事实，再讲判断"]
        ),
        StarVerse(
            star: .tianXiang,
            title: "印星 · 协调",
            original: "天相精神。",
            source: "《形性赋》",
            plain: "天相为印，主秩序与公正。擅长在多方之间找平衡、把流程理顺；要留意为了顾全所有人而牺牲边界。",
            traits: ["适合协调、审阅、把关", "不必替所有人兜底"]
        ),
        StarVerse(
            star: .tianLiang,
            title: "荫星 · 守护",
            original: "天梁稳重，心事玉洁冰清。",
            source: "《形性赋》",
            plain: "天梁主庇护与经验，做事讲原则、愿意照看别人。长处是让人安心，短处是容易变成说教或独自承担。",
            traits: ["适合专业、医疗、教育、顾问", "别把照顾变成控制"]
        ),
        StarVerse(
            star: .qiSha,
            title: "将星 · 决断",
            original: "七杀如子路暴虎冯河。",
            source: "《形性赋》",
            plain: "七杀主决断与突破，古书以「暴虎冯河」形容其勇。表现为敢接硬仗、行动先于犹豫；要防的是硬碰硬。",
            traits: ["适合从零到一与攻坚", "推进要快，收尾要稳"]
        ),
        StarVerse(
            star: .poJun,
            title: "耗星 · 破立",
            original: "破军不仁，背重眉宽，行坐腰斜，好行惊险。",
            source: "《形性赋》",
            plain: "破军主破旧立新，古书评语偏贬，实指其不守成规、敢推倒重来。长处是能开新局，短处是容易一次性全推翻。",
            traits: ["适合重整、创新、换赛道", "重大变动前留备选方案"]
        ),
        StarVerse(
            star: .wenChang,
            title: "文星 · 条理",
            original: "俊雅文昌，眉清目秀。",
            source: "《形性赋》",
            plain: "文昌主文书与条理，善于把散乱的信息整理成结构。宜考试、写作、编纂；忌只停在「想得漂亮」。",
            traits: ["结构化表达是强项", "重要内容至少复查一次"]
        ),
        StarVerse(
            star: .wenQu,
            title: "才艺 · 口舌",
            original: "磊落文曲，口舌便佞。",
            source: "《形性赋》",
            plain: "文曲主才艺与口才，反应快、会表达，对美感敏锐。古书「便佞」是提醒：说得顺不等于说得对。",
            traits: ["适合演讲、创作、内容", "少用反问和推测"]
        ),
        StarVerse(
            star: .zuoFu,
            title: "辅星 · 助力",
            original: "左辅右弼，温良规模，端庄高士。",
            source: "《形性赋》",
            plain: "左辅主辅佐与秩序，擅长把人和事排到位。是「让团队跑起来」的那类角色。",
            traits: ["适合组织与执行统筹", "帮助要落到具体动作"]
        ),
        StarVerse(
            star: .youBi,
            title: "弼星 · 补位",
            original: "左辅右弼，温良规模，端庄高士。",
            source: "《形性赋》",
            plain: "右弼主补位与协调，常出现在别人需要搭手的地方。长处是圆融，短处是容易没有自己的主张。",
            traits: ["适合跨部门与协作", "该表态时别只做和事佬"]
        ),
        StarVerse(
            star: .tianKui,
            title: "天乙 · 提携",
            original: "天魁天钺，具足威仪。",
            source: "《形性赋》",
            plain: "天魁为天乙贵人，主被看见、被推荐。贵人不会凭空出现，前提是先把事做到值得被帮。",
            traits: ["关键节点常有人指路", "主动维护关系，别临时抱佛脚"]
        ),
        StarVerse(
            star: .tianYue,
            title: "玉堂 · 引荐",
            original: "天魁天钺，具足威仪。",
            source: "《形性赋》",
            plain: "天钺为玉堂贵人，主暗中相助与引荐。多应女性长辈或不在台面上的支持。",
            traits: ["容易得到间接的帮助", "记得把人情还回去"]
        ),
        StarVerse(
            star: .luCun,
            title: "禄存 · 守成",
            original: "性貌如春和蔼，乃是禄存之情德。",
            source: "《形性赋》",
            plain: "禄存主资源与守成，对钱和物的分寸感天生较好。长处是稳，短处是保守；古书「羊陀夹禄」也提醒要防身边人。",
            traits: ["擅长积累与保全", "别因小利影响长期安排"]
        ),
        StarVerse(
            star: .qingYang,
            title: "刑星 · 锐利",
            original: "擎羊陀罗，形丑貌粗，有矫诈体态。",
            source: "《形性赋》",
            plain: "擎羊主刑伤与锐气，古书以形貌贬语写之，今只取「锋利」一层：敢下手、也容易伤人伤己。",
            traits: ["适合需要冲劲的场合", "把锋芒对着事，别对着人"]
        ),
        StarVerse(
            star: .tuoLuo,
            title: "忌星 · 拖延",
            original: "擎羊陀罗，形丑貌粗，有矫诈体态。",
            source: "《形性赋》",
            plain: "陀罗主拖延与纠缠，事情容易反复、原地打转。长处是耐磨，短处是耗时间。",
            traits: ["适合需要长期打磨的事", "给自己设截止时间"]
        ),
        StarVerse(
            star: .huoXing,
            title: "火曜 · 爆发",
            original: "火铃似豫让吞炭装哑。",
            source: "《形性赋》",
            plain: "火星主突发与急劲，来得猛、去得也快。适合短期冲刺，不适合长期消耗。",
            traits: ["短跑型爆发力强", "别在气头上做决定"]
        ),
        StarVerse(
            star: .lingXing,
            title: "铃曜 · 暗劲",
            original: "火铃似豫让吞炭装哑。",
            source: "《形性赋》",
            plain: "铃星主隐忍与暗劲，情绪不外露，但会在心里反复。长处是能憋住做事，短处是容易积压。",
            traits: ["适合在暗处布局", "找出口释放，别只往下压"]
        ),
        StarVerse(
            star: .diKong,
            title: "空亡 · 落空",
            original: "星论庙旺，最怕空亡；杀落空亡，竟无威力。",
            source: "《形性赋》",
            plain: "地空主「想得到、抓不住」，对得失看得淡，也容易临时变卦。煞星落空反而减力，是它的另一面。",
            traits: ["适合技术、研究、创作", "把重要的事写成流程"]
        ),
        StarVerse(
            star: .diJie,
            title: "劫煞 · 断点",
            original: "星论庙旺，最怕空亡；杀落空亡，竟无威力。",
            source: "《形性赋》",
            plain: "地劫主中途生变，计划常被打断。长处是应变快，短处是难以累积。",
            traits: ["善于处理突发状况", "预留缓冲与备份"]
        )
    ]
}
