import Foundation

public struct StarProfile: Sendable {
    public let keyword: String
    public let action: String
    public let caution: String
    public let weight: Int
}

public enum StarCatalog {
    public static func profile(_ star: Star) -> StarProfile {
        switch star {
        case .ziWei: .init(keyword: "统筹与主见", action: "抓住关键决策，把复杂事项排出优先级", caution: "避免只发号施令，留出倾听空间", weight: 2)
        case .tianJi: .init(keyword: "思考与变化", action: "适合研究方案、优化流程，再小步验证", caution: "想法过多时先落地一件，避免反复改向", weight: 0)
        case .taiYang: .init(keyword: "表达与担当", action: "主动沟通、公开进度，适合处理需要影响力的事", caution: "留意消耗，别把所有责任都揽在身上", weight: 1)
        case .wuQu: .init(keyword: "执行与务实", action: "处理数字、预算和明确目标，宜快速收尾", caution: "表达可柔和一些，避免过度直接", weight: 1)
        case .tianTong: .init(keyword: "协调与恢复", action: "先找回舒适节奏，再推进协作与日常事务", caution: "不要因为追求轻松而拖延必要事项", weight: 2)
        case .lianZhen: .init(keyword: "原则与边界", action: "理清规则和边界，适合处理需要判断力的事", caution: "避免情绪化较劲，重要决定多核对一次", weight: 0)
        case .tianFu: .init(keyword: "稳定与积累", action: "整理资源、稳健推进，适合经营长期事项", caution: "别因求稳错过需要回应的时间窗口", weight: 2)
        case .taiYin: .init(keyword: "感受与细致", action: "适合复盘、写作、财务整理和安静交流", caution: "减少内耗，模糊信息要直接确认", weight: 1)
        case .tanLang: .init(keyword: "活力与连接", action: "适合社交、创意和探索新机会", caution: "控制冲动消费与过度安排", weight: 0)
        case .juMen: .init(keyword: "辨析与表达", action: "把问题讲清楚，适合查证、讨论与解决误会", caution: "少用反问和推测，避免言语造成摩擦", weight: -1)
        case .tianXiang: .init(keyword: "合作与秩序", action: "推进协作、审阅细节，适合扮演协调者", caution: "不必为了顾全所有人而牺牲边界", weight: 1)
        case .tianLiang: .init(keyword: "保护与经验", action: "请教经验、处理保障和长期规划", caution: "避免说教，也别独自承担过多", weight: 2)
        case .qiSha: .init(keyword: "决断与突破", action: "处理最棘手的一件事，行动后及时复盘", caution: "节奏宜快不宜急，避免冒险和硬碰硬", weight: -1)
        case .poJun: .init(keyword: "更新与重组", action: "清理低效事项，尝试新的解决路径", caution: "重大变动保留备选方案，避免一次性推倒重来", weight: -2)
        case .wenChang, .wenQu: .init(keyword: "文书与表达", action: "整理文字、学习或核对资料", caution: "重要内容至少复查一次", weight: 1)
        case .zuoFu, .youBi, .tianKui, .tianYue: .init(keyword: "助力与支持", action: "主动寻求协助，也回应他人的需要", caution: "帮助需要落实到具体行动", weight: 1)
        case .luCun: .init(keyword: "资源与守成", action: "盘点可用资源，守住已有成果", caution: "避免因小利影响长期安排", weight: 1)
        case .qingYang, .tuoLuo: .init(keyword: "阻力与磨合", action: "把阻力拆小，预留更多处理时间", caution: "减少争执，注意安全与细节", weight: -2)
        case .diKong, .diJie: .init(keyword: "变动与落空", action: "先验证再投入，保留弹性", caution: "避免凭空预期和冲动承诺", weight: -2)
        case .tianMa: .init(keyword: "行动与流动", action: "适合出行、走动与处理外部事务", caution: "行程预留缓冲", weight: 0)
        case .hongLuan, .tianXi: .init(keyword: "愉悦与联结", action: "真诚表达善意，安排轻松互动", caution: "不把短暂情绪当作长期承诺", weight: 1)
        }
    }
}
