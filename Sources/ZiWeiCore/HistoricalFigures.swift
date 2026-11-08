import Foundation

/// 一位可作参照的历史人物。
///
/// 说明：这里的「同盘」指命宫主星组合相同（同一组星曜落在命宫），
/// 是类型上的相似，并非生辰相同、命盘完全一致。古人生平按正史与通行传记概述。
public struct HistoricalFigure: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let era: String
    public let title: String
    /// 该人物的命宫主星组合。
    public let stars: [Star]
    /// 生平梗概。
    public let story: String
    /// 这组星在这人身上怎么显形，也是与你相似的地方。
    public let resonance: String
    /// 可借鉴之处。
    public let lesson: String
}

public enum FigureMatchKind: String, Codable, Sendable {
    case sameCombo = "同宫"
    case sameStar = "同星"
}

public struct FigureMatch: Identifiable, Codable, Equatable, Sendable {
    public let figure: HistoricalFigure
    public let kind: FigureMatchKind
    public let sharedStars: [Star]
    /// 命宫空宫、借对宫主星判断时为 true。
    public let borrowed: Bool

    public var id: String { figure.id }
}

public enum HistoricalFigures {
    public static let disclaimer = "对照只按命宫主星组合取「同盘意象」，并非生辰相同、命盘完全一致；古人生平按正史与通行传记概述，仅作参照，不作命理定论。"

    public static func matches(for chart: Chart) -> [FigureMatch] {
        let palace = chart.palace(at: chart.lifeBranch)
        let borrowed = palace.mainStars.isEmpty
        var stars = borrowed ? chart.palace(at: Ganzhi.mod(chart.lifeBranch + 6, 12)).mainStars : palace.mainStars

        // 命宫与对宫同时空宫时，退一步取三方的第一组主星
        if stars.isEmpty {
            for branch in chart.triad(of: chart.lifeBranch) where !chart.palace(at: branch).mainStars.isEmpty {
                stars = chart.palace(at: branch).mainStars
                break
            }
        }

        let target = Set(stars)
        guard !target.isEmpty else { return [] }
        let exactEligible = !borrowed

        let exact = all.filter { Set($0.stars) == target }
        var result: [FigureMatch] = exact.map {
            FigureMatch(figure: $0, kind: exactEligible ? .sameCombo : .sameStar, sharedStars: $0.stars, borrowed: borrowed)
        }

        if result.count < 2 {
            let partial = all
                .filter { figure in
                    !exact.contains(where: { $0.id == figure.id })
                        && !Set(figure.stars).isDisjoint(with: target)
                }
                .sorted { lhs, rhs in
                    let left = Set(lhs.stars).intersection(target).count
                    let right = Set(rhs.stars).intersection(target).count
                    if left != right { return left > right }
                    if lhs.stars.count != rhs.stars.count { return lhs.stars.count < rhs.stars.count }
                    return lhs.id < rhs.id
                }
                .prefix(2 - result.count)
            result += partial.map {
                FigureMatch(
                    figure: $0,
                    kind: .sameStar,
                    sharedStars: target.intersection($0.stars).sorted { $0.rawValue < $1.rawValue },
                    borrowed: borrowed
                )
            }
        }
        return result
    }

    public static let all: [HistoricalFigure] = [
        HistoricalFigure(
            id: "wuzetian", name: "武则天", era: "唐", title: "中国历史上唯一的女皇帝",
            stars: [.ziWei],
            story: "十四岁入宫为才人，历经太宗、高宗两朝，六十七岁称帝改国号为周，在位十五年，晚年还政李唐。",
            resonance: "紫微独坐的人习惯自己拿主意，位置越高越孤。她的一生几乎就是「要不要坐到那个位置上」的反复回答。",
            lesson: "权力能解决外部问题，解决不了身边人的心；越到高处越要留几个敢说真话的人。"
        ),
        HistoricalFigure(
            id: "kangxi", name: "康熙", era: "清", title: "在位六十一年的皇帝",
            stars: [.ziWei, .tianFu],
            story: "八岁登基，平三藩、收台湾、御沙俄，在位六十一年，是清代在位最久的皇帝。",
            resonance: "紫府同宫讲的是「守得住又拓得开」：底盘稳，才敢在关键处一次出手。",
            lesson: "稳不是不动，是把资源攒到能一次做成一件事的时候再用。"
        ),
        HistoricalFigure(
            id: "zhangjuzheng", name: "张居正", era: "明", title: "万历首辅、一条鞭法主持者",
            stars: [.ziWei, .tianXiang],
            story: "隆庆、万历两朝首辅，推行一条鞭法与考成法，十年间国库充盈；死后被抄家，子弟流放。",
            resonance: "紫相是宰相格局：擅长在体制内做事，也容易把权力用得过满。",
            lesson: "做事可以强势，收尾要留余地；功劳太集中，账迟早有人来算。"
        ),
        HistoricalFigure(
            id: "caocao", name: "曹操", era: "东汉末", title: "魏武帝（追尊）",
            stars: [.ziWei, .qiSha],
            story: "起兵讨董卓，迎献帝都许，统一北方，终其一生未称帝，自称「若天命在吾，吾为周文王」。",
            resonance: "紫杀敢下决断，也背得起争议，一生都在「做还是不做」的临界点上。",
            lesson: "决断力是稀缺品，但每一次强推都在消耗人心，要算总账。"
        ),
        HistoricalFigure(
            id: "zhuyuanzhang", name: "朱元璋", era: "明", title: "明太祖",
            stars: [.ziWei, .poJun],
            story: "出身佃农、少时做过和尚，元末投红巾军，1368 年建明，重典治吏，屡兴大狱。",
            resonance: "紫破是破旧立新的格局：不破不立，一生都在重建秩序。",
            lesson: "把旧的全推倒很快，把新的立稳很慢；重建期最忌再折腾。"
        ),
        HistoricalFigure(
            id: "tangxuanzong", name: "唐玄宗", era: "唐", title: "开元盛世与天宝之乱的当事人",
            stars: [.ziWei, .tanLang],
            story: "前期任姚崇、宋璟，开开元盛世；后期宠信李林甫、杨国忠，安史之乱后失位西走。",
            resonance: "紫贪才华与享受并存，盛极而转；前半程的顺，常常掩盖了后半程的松懈。",
            lesson: "最好的时候最该检查制度，而不是检查运气。"
        ),
        HistoricalFigure(
            id: "shenkuo", name: "沈括", era: "北宋", title: "《梦溪笔谈》作者",
            stars: [.tianJi],
            story: "博通天文、地理、数学与医药，晚年著《梦溪笔谈》，记录活字印刷、指南针等大量技术细节。",
            resonance: "天机独坐脑子快、兴趣广，成果常来自跨界的连接。",
            lesson: "想法多不是问题，问题是把哪一个做完；给自己留一本「已完成」的账。"
        ),
        HistoricalFigure(
            id: "zhangliang", name: "张良", era: "西汉", title: "汉初三杰之一",
            stars: [.tianJi, .taiYin],
            story: "佐刘邦定天下，鸿门宴上周旋脱身，功成后称病退隐，学辟谷导引。",
            resonance: "机阴善谋而不外露，看得清局势，也看得清自己该在什么时候退。",
            lesson: "退不是输，是把已经拿到的东西保住。"
        ),
        HistoricalFigure(
            id: "suqin", name: "苏秦", era: "战国", title: "纵横家、佩六国相印",
            stars: [.tianJi, .juMen],
            story: "以合纵之说佩六国相印，使秦十五年不敢窥函谷关；联盟瓦解后入齐，遇刺而死。",
            resonance: "机巨靠口舌与谋略起家，成也言辞，险也言辞。",
            lesson: "靠说服得来的位置，需要靠兑现来维持。"
        ),
        HistoricalFigure(
            id: "shaoyong", name: "邵雍", era: "北宋", title: "易学家、安乐先生",
            stars: [.tianJi, .tianLiang],
            story: "隐居洛阳近三十年，以《皇极经世》推演世运，讲学不仕，司马光等皆敬其人。",
            resonance: "机梁好推演、重义理，适合做需要长期钻研的学问。",
            lesson: "看得远是长处，别用它替别人做决定。"
        ),
        HistoricalFigure(
            id: "hairui", name: "海瑞", era: "明", title: "以清廉刚直闻名的官员",
            stars: [.taiYang],
            story: "任淳安知县、应天巡抚，清廉刚直，上《治安疏》直斥嘉靖，下狱论死，嘉靖死后获释。",
            resonance: "太阳独坐外放刚直，敢把话说到明面上，也因此树敌。",
            lesson: "原则要守，方式可以换；硬碰硬赢一次，未必赢第二次。"
        ),
        HistoricalFigure(
            id: "weizheng", name: "魏征", era: "唐", title: "唐太宗朝的谏臣",
            stars: [.taiYang, .juMen],
            story: "原为李建成谋臣，后为太宗所用，前后陈谏二百余事，死后太宗叹「以人为镜」。",
            resonance: "日巨直言善辩，价值在「敢说」和「说得准」。",
            lesson: "提意见的人要挑时机，听意见的人要挑气量。"
        ),
        HistoricalFigure(
            id: "fanzhongyan", name: "范仲淹", era: "北宋", title: "庆历新政主持者",
            stars: [.taiYang, .tianLiang],
            story: "经略陕西边事，主持庆历新政，作《岳阳楼记》，「先天下之忧而忧」一句传世。",
            resonance: "阳梁走的是「阳梁昌禄」的路子：靠担当与名声立身，责任越大越显价值。",
            lesson: "担子可以挑，但要挑得长久；别把身体也算进成本里。"
        ),
        HistoricalFigure(
            id: "baijuyi", name: "白居易", era: "唐", title: "诗人",
            stars: [.taiYang, .taiYin],
            story: "元和年间任谏官，因言事被贬江州，后历任杭州、苏州刺史，晚年闲居洛阳香山。",
            resonance: "日月同宫的人身上有两套逻辑：一面要出头，一面想退回去。",
            lesson: "两套逻辑不必分出胜负，分场合用就好。"
        ),
        HistoricalFigure(
            id: "wangjian", name: "王翦", era: "秦", title: "灭楚名将",
            stars: [.wuQu],
            story: "率六十万大军灭楚，出征前反复向秦王请赐田宅以自安，功成而不被猜忌。",
            resonance: "武曲独坐务实认结果，也懂得替自己算退路。",
            lesson: "会打仗的人多，会收场的人少；功劳越大越要示弱。"
        ),
        HistoricalFigure(
            id: "shenwansan", name: "沈万三", era: "明初", title: "江南巨富（其人其事迹带传说色彩）",
            stars: [.wuQu, .tianFu],
            story: "元末明初江南富商，相传助筑南京城墙三分之一，后又请犒军，触怒朱元璋，家产被没、流放云南。",
            resonance: "武府财库丰盈，善经营而不善藏；富到显眼处，麻烦就来了。",
            lesson: "钱要放在看不见的地方，风头要留给别人。"
        ),
        HistoricalFigure(
            id: "jiangziya", name: "姜子牙", era: "西周", title: "齐太公、周初功臣",
            stars: [.wuQu, .tanLang],
            story: "相传五十余岁屠牛于朝歌、卖饭于孟津，七十余岁钓于渭水遇周文王，后佐武王灭商。",
            resonance: "武贪不发少年人：早年多磨，中年以后才真正用得上力气。",
            lesson: "晚成不是不成，是前面那些年都在攒本钱。"
        ),
        HistoricalFigure(
            id: "sanghongyang", name: "桑弘羊", era: "西汉", title: "汉武帝朝的理财家",
            stars: [.wuQu, .tianXiang],
            story: "出身商人之家，主持盐铁官营、均输平准，为武帝一朝筹措军费，后卷入政争被杀。",
            resonance: "武相精于算计，长于在既定规则里调度资源。",
            lesson: "会算账的人最容易只算账；数字之外还有人心。"
        ),
        HistoricalFigure(
            id: "weiqing", name: "卫青", era: "西汉", title: "大将军、长平侯",
            stars: [.wuQu, .qiSha],
            story: "骑奴出身，七战匈奴，官至大将军，为人退让，不养门客，得善终。",
            resonance: "武杀刚毅能战，也懂得以退让换安全。",
            lesson: "能力越强，姿态越要低；这不是委屈，是护身。"
        ),
        HistoricalFigure(
            id: "hanxin", name: "韩信", era: "西汉", title: "淮阴侯、兵家四圣之一",
            stars: [.wuQu, .poJun],
            story: "早年受胯下之辱，后为刘邦破魏、灭赵、下齐，垓下围项羽，终被吕后诱杀于长乐宫。",
            resonance: "武破在战场上是奇才，处理关系上却容易低估风险。",
            lesson: "能打赢的人，往往输在看不懂人心。"
        ),
        HistoricalFigure(
            id: "taoyuanming", name: "陶渊明", era: "东晋", title: "田园诗人",
            stars: [.tianTong],
            story: "四仕四隐，最后任彭泽令八十余日，不为五斗米折腰，归园田居，饮酒赋诗以终。",
            resonance: "天同独坐求和气、怕内耗，宁可降低条件也不愿违心。",
            lesson: "退一步能换来安稳，但要先想清楚代价由谁承担。"
        ),
        HistoricalFigure(
            id: "liyu", name: "李煜", era: "南唐", title: "南唐后主、词人",
            stars: [.tianTong, .taiYin],
            story: "二十五岁继位，国势日衰，三十九岁降宋，被囚汴京近三年后去世；词作冠绝一代。",
            resonance: "同阴敏感多情，感受力极强，处理硬事却容易回避。",
            lesson: "擅长的事会救你，也会困住你；该硬的时候要练硬。"
        ),
        HistoricalFigure(
            id: "liuyong", name: "柳永", era: "北宋", title: "词人",
            stars: [.tianTong, .juMen],
            story: "屡试不第，自称「奉旨填词柳三变」，混迹市井教坊，晚年才中进士，任屯田员外郎。",
            resonance: "同巨才情与口舌并存，在体制里常常吃不开，在民间却很吃得开。",
            lesson: "被一个圈子拒绝，不代表你没有位置，换一个圈子看看。"
        ),
        HistoricalFigure(
            id: "sushi", name: "苏轼", era: "北宋", title: "文学家、书画家",
            stars: [.tianTong, .tianLiang],
            story: "乌台诗案下狱，此后贬黄州、惠州、儋州，一路南迁，仍在贬所写出大量豁达之作。",
            resonance: "同梁达观、福厚，越到逆境越显出韧性。",
            lesson: "遭遇不能选，解释权可以自己留着。"
        ),
        HistoricalFigure(
            id: "quyuan", name: "屈原", era: "战国", title: "楚国左徒、《离骚》作者",
            stars: [.lianZhen],
            story: "任左徒，主张联齐抗秦、举贤授能，遭谗被逐，作《离骚》；秦将白起破郢都后投汨罗江。",
            resonance: "廉贞独坐重原则、有洁癖，容不下含糊，也不肯同流。",
            lesson: "守住底线的方式不止一种，不一定要用命去证明。"
        ),
        HistoricalFigure(
            id: "libai", name: "李白", era: "唐", title: "诗人",
            stars: [.lianZhen, .tanLang],
            story: "天宝初供奉翰林，年余即被赐金放还，此后漫游天下；晚年因永王李璘事流放夜郎，中途遇赦。",
            resonance: "廉贪才华横溢、活得张扬，才华与任性是一体两面。",
            lesson: "天赋可以任性几年，长跑还是要靠自律。"
        ),
        HistoricalFigure(
            id: "direnjie", name: "狄仁杰", era: "唐", title: "武周与中宗朝宰相",
            stars: [.lianZhen, .tianXiang],
            story: "任大理丞时一年断案涉及万七千人，后遭来俊臣诬陷下狱，设法自保，终复相位。",
            resonance: "廉相刚正而不失手腕，能在复杂局面里既守原则又活下来。",
            lesson: "守原则不等于硬撞，绕过去也是一种守。"
        ),
        HistoricalFigure(
            id: "yuefei", name: "岳飞", era: "南宋", title: "抗金名将",
            stars: [.lianZhen, .qiSha],
            story: "四次北伐，郾城、颍昌大捷，后被十二道金牌召回，以「莫须有」下狱，风波亭遇害，年三十九。",
            resonance: "廉杀忠烈刚猛，认准的事九头牛拉不回，也因此难避暗箭。",
            lesson: "把事做对还不够，要看清是谁在定规则。"
        ),
        HistoricalFigure(
            id: "wuqi", name: "吴起", era: "战国", title: "兵家、楚国令尹",
            stars: [.lianZhen, .poJun],
            story: "仕鲁时杀妻求将，仕魏创武卒制，后入楚主持变法，触怒贵族，悼王死后被射杀。",
            resonance: "廉破狠绝善战，做事不留后路，也常把自己送上绝路。",
            lesson: "极端的手段能短期见效，长期会把桥全部烧掉。"
        ),
        HistoricalFigure(
            id: "xiaohe", name: "萧何", era: "西汉", title: "汉丞相、汉初三杰之一",
            stars: [.tianFu],
            story: "刘邦入咸阳，众人争金帛，独收秦律令图书；楚汉相争时守关中供粮，后定汉律九章。",
            resonance: "天府独坐善守、善经营，价值在「后方不出事」。",
            lesson: "不显眼的稳定，往往是最难替代的能力。"
        ),
        HistoricalFigure(
            id: "zhangsun", name: "长孙皇后", era: "唐", title: "唐太宗皇后",
            stars: [.taiYin],
            story: "十三岁嫁李世民，玄武门之变时亲慰将士，常以「朝政不预」自守，三十六岁崩于立政殿。",
            resonance: "太阴独坐柔中持重，擅长在关系里做那个不抢话的人。",
            lesson: "不站到台前，也是一种影响力，前提是心里有准绳。"
        ),
        HistoricalFigure(
            id: "dongfangshuo", name: "东方朔", era: "西汉", title: "辞赋家、太中大夫",
            stars: [.tanLang],
            story: "以三千奏牍自荐入仕，滑稽多智，常以诙谐进谏，后世附会出偷桃、窥仙一类传说。",
            resonance: "贪狼独坐机敏多才，靠灵活与趣味打开局面。",
            lesson: "聪明外露能换来机会，也容易只被当成有趣的人。"
        ),
        HistoricalFigure(
            id: "shangyang", name: "商鞅", era: "战国", title: "秦国变法主持者",
            stars: [.juMen],
            story: "以《法经》入秦，两次变法，徙木立信，秦从此强；孝公死后被诬谋反，车裂于彤。",
            resonance: "巨门独坐善辩、能立法，锋利到让人记住，也让人记恨。",
            lesson: "制度能改，人心要慢慢磨；只靠刀锋推的规则，人一倒就废。"
        ),
        HistoricalFigure(
            id: "fangxuanling", name: "房玄龄", era: "唐", title: "贞观宰相",
            stars: [.tianXiang],
            story: "秦王幕府核心，贞观年间任宰相十五年，与杜如晦并称「房谋杜断」，善协调、能容人。",
            resonance: "天相独坐重秩序、善协调，是那种把流程走顺的人。",
            lesson: "会协调的人容易被当成没有立场，关键处要表一次态。"
        ),
        HistoricalFigure(
            id: "taohongjing", name: "陶弘景", era: "南朝", title: "「山中宰相」、医药学家",
            stars: [.tianLiang],
            story: "隐居茅山四十余年，整理《本草经集注》，梁武帝每有大事遣使咨询，时人称山中宰相。",
            resonance: "天梁独坐重经验、有保护欲，越老越有价值。",
            lesson: "不进场也能有用，但要让别人知道你在。"
        ),
        HistoricalFigure(
            id: "xiangyu", name: "项羽", era: "秦末", title: "西楚霸王",
            stars: [.qiSha],
            story: "巨鹿之战破釜沉舟大破秦军，鸿门宴放走刘邦，垓下兵败，乌江自刎，年三十一。",
            resonance: "七杀独坐勇猛果断，赢在气势，输在不肯转弯。",
            lesson: "过江不是认输，是给自己留第二次机会。"
        ),
        HistoricalFigure(
            id: "chongzhen", name: "崇祯", era: "明末", title: "明思宗",
            stars: [.poJun],
            story: "十七岁即位，诛魏忠贤、勤于政事，十七年间换了五十余位内阁大学士，1644 年李自成破京，自缢煤山。",
            resonance: "破军独坐敢推倒重来，但重建需要时间，频繁推翻只会耗尽国力。",
            lesson: "换人换制度都不难，难的是给新东西留出长成的时间。"
        )
    ]
}
