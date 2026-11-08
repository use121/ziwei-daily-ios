import Foundation

/// 三部公版古籍的全文段落。
///
/// 底本：明刊《紫微斗数全书》体系（太微赋、斗数骨髓赋、形性赋）。
/// 只做分段与标点，不改字；传本异文取通行写法。
/// 涉及自伤方式与人身侮辱的句子不录，在各篇 note 中列明，便于与原书对照。
enum ClassicTexts {

    static let works: [ClassicWork] = [taiWeiFu, guSuiFu, xingXingFu]

    // MARK: - 太微赋

    static let taiWeiFu = ClassicWork(
        title: "太微赋",
        subtitle: "全书首篇 · 论格局总纲",
        author: "旧题白玉蟾",
        era: "宋代（明刊本）",
        intro: "《紫微斗数全书》开篇。先立「身命为福德之本」的总则，再以对句逐条点出成格与破格，是全书格局名的来源。",
        note: "底本依明刊《紫微斗数全书》卷一，参校诸通行本。原文多绝对化断语（如「必定死亡」「须当刑戮」），系明代术数语境，本版照录并逐段加「今按」，供辨析而非采信。全篇无删略。",
        passages: [
            ClassicPassage(
                id: "tw-1", section: "总纲",
                original: "斗数至玄至微，理旨难明。虽设问于各篇之中，犹有言而未尽。",
                plain: "斗数这门学问极细，义理不易讲透；即便各篇已设问答，仍有些话没能说尽。"
            ),
            ClassicPassage(
                id: "tw-2", section: "总纲",
                original: "至如星之分野，各有所属；寿夭贤愚，富贵贫贱，不可一概论议。",
                plain: "星各有其所主之事，人的寿夭、贤愚、贫富、贵贱，不能用一个标准一概而论。"
            ),
            ClassicPassage(
                id: "tw-3", section: "总纲",
                original: "其星分布一十二垣，数定乎三十六位，入庙为奇，失度为虚。",
                plain: "诸星分布在十二宫垣，位置共三十六处；星得地（入庙）才显其力，失位（失度）便虚而不实。"
            ),
            ClassicPassage(
                id: "tw-4", section: "总纲",
                original: "大抵以身命为福德之本，加以根源为穷通之资。",
                plain: "大体上以命宫、身宫为一生福禄的根本，再看根基（生年干支、五行局）来判断通塞。"
            ),
            ClassicPassage(
                id: "tw-5", section: "总纲",
                original: "星有同躔，数有分定。须明其生克之要，必详乎得垣失度之分。",
                plain: "众星会聚一宫有其定数。要弄清彼此生克的要点，也要细辨得位与失位的差别。"
            ),
            ClassicPassage(
                id: "tw-6", section: "总纲",
                original: "观乎紫微舍躔，司一天仪之象，率列宿而成垣。",
                plain: "看紫微所处的位置：它像天球的枢纽，带领诸星排成十二宫垣。"
            ),
            ClassicPassage(
                id: "tw-7", section: "总纲",
                original: "土星苟居其垣，若可移动；金星专司财库，最怕空亡。",
                plain: "土星（紫微、天府一类）所在之宫可以随局推移；金星（武曲一类）主财库，最怕落空亡之位。"
            ),
            ClassicPassage(
                id: "tw-8", section: "总纲",
                original: "帝星动则列宿奔驰，令守空而财源不聚。",
                plain: "帝星一动，诸星随之奔走；若主事之星落空，财源就聚不起来。"
            ),
            ClassicPassage(
                id: "tw-9", section: "总纲",
                original: "各司其职，不可参差。苟或不察其机，更忘其变，则数之造化远矣。",
                plain: "各星各守其职，不能错位。若不明其中的机变，就离斗数真正的作用很远了。"
            ),
            ClassicPassage(
                id: "tw-10", section: "例曰 · 吉凶之机",
                original: "例曰：禄逢冲破，吉处藏凶。马遇空亡，终身奔走。",
                plain: "举例说：化禄被冲破，看似吉处其实藏着凶；天马落空亡，主一生奔波而难有落点。"
            ),
            ClassicPassage(
                id: "tw-11", section: "例曰 · 吉凶之机",
                original: "生逢败地，发也虚花。绝处逢生，花而不败。",
                plain: "生在败绝之地，发起来也是虚花一场；若在绝地得救，反倒能开而不谢。"
            ),
            ClassicPassage(
                id: "tw-12", section: "例曰 · 吉凶之机",
                original: "星临庙旺，再观生克之机。命坐强宫，细察制化之理。",
                plain: "星虽庙旺，还要看生克；命宫虽强，也要细察制化的关系。"
            ),
            ClassicPassage(
                id: "tw-13", section: "例曰 · 吉凶之机",
                original: "日月最嫌反背，禄马最喜交驰。",
                plain: "太阳太阴最怕双双落陷（反背），禄存与天马最喜同会（交驰）。"
            ),
            ClassicPassage(
                id: "tw-14", section: "例曰 · 吉凶之机",
                original: "倘居空亡，得失最为要紧。若逢败地，扶持大有奇功。",
                plain: "若落空亡，得失之间最见分晓；若逢败地，一点扶助就能起大作用。"
            ),
            ClassicPassage(
                id: "tw-15", section: "格局断语",
                original: "紫微天府全依辅弼之功，七杀破军专依羊铃之虐。",
                plain: "紫微、天府要靠辅弼才成气候；七杀、破军则要靠羊铃的激烈才显力。"
            ),
            ClassicPassage(
                id: "tw-16", section: "格局断语",
                original: "诸星吉，逢凶也吉。诸星凶，逢吉也凶。",
                plain: "整体结构吉，遇到凶星也还能转吉；整体结构凶，遇到吉星也难全吉。"
            ),
            ClassicPassage(
                id: "tw-17", section: "格局断语",
                original: "辅弼夹帝为上品，桃花犯主为至淫。",
                plain: "辅弼夹辅帝星是上等结构；桃花星犯主则主情欲牵累。",
                note: "「至淫」是明代对情欲的道德评判，今不作人身评价，只保留「感情易牵动判断」这一层提醒。"
            ),
            ClassicPassage(
                id: "tw-18", section: "格局断语",
                original: "君臣庆会，材善经邦。魁钺同行，位居台辅。",
                plain: "紫微会齐百官为君臣庆会，主有治国之才；魁钺同行为贵人夹辅，主位居机要。"
            ),
            ClassicPassage(
                id: "tw-19", section: "格局断语",
                original: "禄文拱命，贵而且贤。日月夹财，不权则富。",
                plain: "禄存与昌曲拱命，主贵而有才；日月夹财位，不成权贵也主富足。"
            ),
            ClassicPassage(
                id: "tw-20", section: "格局断语",
                original: "马头带剑，镇卫边疆。刑囚夹印，刑杖惟司。",
                plain: "擎羊坐午为马头带剑，主威镇一方；刑囚夹印，主与刑罚、纠葛之事相关。"
            ),
            ClassicPassage(
                id: "tw-21", section: "格局断语",
                original: "善荫朝纲，仁慈之长。贵入贵乡，逢之富贵。财居财位，遇者富奢。",
                plain: "天梁朝命主仁厚；贵星入贵地，主富贵；财星居财位，主富足。"
            ),
            ClassicPassage(
                id: "tw-22", section: "格局断语",
                original: "太阳居午，谓之日丽中天，有专权之贵，敌国之富。",
                plain: "太阳坐午为日丽中天，主掌权之贵、极盛之富——这是古人形容「正午最亮」的比喻。"
            ),
            ClassicPassage(
                id: "tw-23", section: "格局断语",
                original: "太阴居子，号曰水澄桂萼，得清要之职，忠谏之材。",
                plain: "太阴坐子为水澄桂萼，主清贵机要之职，宜谏言、审慎一类的位置。"
            ),
            ClassicPassage(
                id: "tw-24", section: "格局断语",
                original: "紫微辅弼同宫，一呼百诺居上品。文耗居寅卯，谓之众水朝东。",
                plain: "紫微与辅弼同宫，号召力强；昌曲与破军居寅卯，称众水朝东，主才气奔涌。"
            ),
            ClassicPassage(
                id: "tw-25", section: "格局断语",
                original: "日月守不如照合，荫福聚不怕凶危。",
                plain: "日月同守不如三方照合来得有力；荫星与福星聚在一处，遇凶险也较能化解。"
            ),
            ClassicPassage(
                id: "tw-26", section: "格局断语",
                original: "贪居亥子，名为犯水桃花。刑遇贪狼，号曰风流彩杖。",
                plain: "贪狼坐亥子为犯水桃花，主情缘牵动；天刑遇贪狼，称风流彩杖，主才情与约束并存。"
            ),
            ClassicPassage(
                id: "tw-27", section: "格局断语",
                original: "七杀廉贞同位，路上埋尸。破军暗曜同乡，水中作冢。",
                plain: "七杀与廉贞同宫、破军与暗曜同宫，古人视为极险之象。",
                note: "「路上埋尸」「水中作冢」是明代对意外伤亡的形象化描述，属宿命论表述，不作现实判断。今读为：此二组星性刚烈，宜留意安全、避免逞强。"
            ),
            ClassicPassage(
                id: "tw-28", section: "格局断语",
                original: "禄居奴仆纵有官也奔驰，帝遇凶徒虽获吉而无道。",
                plain: "禄落交友宫，虽居官也难免奔忙；帝星遇煞，纵有吉助也难行其道。"
            ),
            ClassicPassage(
                id: "tw-29", section: "格局断语",
                original: "帝坐金车则曰金舆捧栉，福安文曜谓之玉袖天香。",
                plain: "帝星坐于得助之宫，如金舆捧栉；福星安于文曜之宫，如袖染天香——都是形容气局清贵的意象。"
            ),
            ClassicPassage(
                id: "tw-30", section: "格局断语",
                original: "太阳会文昌于官禄，皇殿朝班，富贵全美。太阴会文曲于妻宫，蟾宫折桂，文章全盛。",
                plain: "太阳会文昌于官禄，主在体制内得位；太阴会文曲于夫妻宫，主文章与名声俱盛。"
            ),
            ClassicPassage(
                id: "tw-31", section: "格局断语",
                original: "禄存守于田财，堆金积玉。财荫坐于迁移，巨商高贾。",
                plain: "禄存守田宅、财帛，主积财；财星与荫星坐迁移，主在外经商有成。"
            ),
            ClassicPassage(
                id: "tw-32", section: "格局断语",
                original: "耗居禄位，沿途乞食。贪会旺宫，终身鼠窃。",
                plain: "耗星占禄位、贪狼会旺宫，古人以乞食、鼠窃形容其耗散。",
                note: "这是明代对贫贱的道德化描述，带有身份歧视。今读为：耗星占财位时容易漏财，宜控制现金流与零碎支出。"
            ),
            ClassicPassage(
                id: "tw-33", section: "格局断语",
                original: "杀居绝地，天年夭似颜回。贪坐生乡，寿考永如彭祖。",
                plain: "七杀落绝地、贪狼坐生乡，古人以颜回早逝、彭祖长寿作比。",
                note: "以寿命作绝对判断是古代术数的典型表述，现代不应据此推断健康。真正与健康相关的，是作息、体检与就医。"
            ),
            ClassicPassage(
                id: "tw-34", section: "格局断语",
                original: "忌暗同居身命疾厄，沉困尪羸。凶星会于父母迁移，刑伤破祖。",
                plain: "化忌与暗曜同处身命或疾厄，主长期困顿、体力偏弱；凶星会于父母、迁移，主早年离家或与长辈缘薄。"
            ),
            ClassicPassage(
                id: "tw-35", section: "格局断语",
                original: "刑杀同廉贞于官禄，枷扭难逃。官符加刑杀于迁移，离乡遭配。",
                plain: "刑杀与廉贞同落官禄，主易涉纠纷；官符加刑杀于迁移，主在外多是非。"
            ),
            ClassicPassage(
                id: "tw-36", section: "格局断语",
                original: "善福居空位，天竺生涯。辅弼单守命宫，离宗庶出。",
                plain: "善星福星落空位，主志在清虚；辅弼单守命宫，主早年离乡或自立门户。"
            ),
            ClassicPassage(
                id: "tw-37", section: "格局断语",
                original: "七杀临于身命加恶杀，必定死亡。铃羊合于命宫遇白虎，须当刑戮。",
                plain: "七杀临身命又逢恶煞、铃羊合命宫又遇白虎，古人视为生死之厄。",
                note: "此二句是全篇最重的断语，属明代术数的绝对化表达，不作任何现实推断，也不宜据此自我暗示。今读为：煞星密集时，宜留意安全、避免高危行为与冲动决策。"
            ),
            ClassicPassage(
                id: "tw-38", section: "流年与流曜",
                original: "官府发于吉曜，流杀怕逢破军。羊陀凭太岁以引行，病符官符皆作祸。",
                plain: "官符得吉星则轻，流煞遇破军则重；羊陀随太岁而起，病符、官符都主是非。"
            ),
            ClassicPassage(
                id: "tw-39", section: "流年与流曜",
                original: "奏书博士与流禄，尽作吉祥。力士将军同青龙，显其权势。",
                plain: "奏书、博士与流禄一类神煞偏吉；力士、将军、青龙则显其势。"
            ),
            ClassicPassage(
                id: "tw-40", section: "流年与流曜",
                original: "童子限如水上泡沤，老人限似风中燃烛。",
                plain: "童限如水面浮泡，老限似风中残烛——极言幼年与晚年的运限最须小心呵护。"
            ),
            ClassicPassage(
                id: "tw-41", section: "流年与流曜",
                original: "遇杀无制乃流年最忌。",
                plain: "流年遇煞而无制化，是最该留意的一种情形。"
            ),
            ClassicPassage(
                id: "tw-42", section: "收束",
                original: "人生荣辱限元必有休咎，处世孤贫数中逢乎驳杂，学至此诚玄微矣。",
                plain: "一生的荣辱在限运里自有起伏，处境的孤贫顺逆都在命数的驳杂之中；学到这一层，才算摸到斗数的细微处。"
            )
        ]
    )

    // MARK: - 斗数骨髓赋

    static let guSuiFu = ClassicWork(
        title: "斗数骨髓赋",
        subtitle: "格局与性情总汇",
        author: "旧题陈抟（明刊本）",
        era: "宋代（明刊本）",
        intro: "以对句密集罗列星曜组合的成败，是紫微斗数流传最广的一篇赋。今日排盘软件里的格局名，大半出自这里。",
        note: "底本依明刊《紫微斗数全书》，参校诸通行本。原文有「巨火擎羊，终身缢死」「铃昌陀武，限至投河」二句，涉及自伤方式，本版不录；另有「贪狼入命必为娼」一句含人身侮辱，亦不录。其余照录，宿命论表述附「今按」。",
        passages: [
            ClassicPassage(
                id: "gs-1", section: "总纲",
                original: "太极星曜，乃群宿众星之主；天门运限，即扶身助命之源。",
                plain: "诸星以太极统之，是众星之主；运限自天门而起，是扶身助命的根源。"
            ),
            ClassicPassage(
                id: "gs-2", section: "总纲",
                original: "在天则运用无常，在人则命有格局。先明格局，次看吉凶。",
                plain: "天道运行无常，落到人身上就有了格局。看盘先定格局，再论吉凶。"
            ),
            ClassicPassage(
                id: "gs-3", section: "总纲",
                original: "或有同年同月同日同时而生，则有贫贱富贵寿夭之异：或在恶限积百万之金银，或在旺乡遭连年之困苦。",
                plain: "同一天同一时辰出生的人，际遇仍可能相差很大：有人在坏运里反而积财，有人在好运里却连年受困。"
            ),
            ClassicPassage(
                id: "gs-4", section: "总纲",
                original: "祸福不可一途而推，吉凶不可一例而断。",
                plain: "祸福不能只用一条路去推，吉凶也不能用一个例子去断——这句是全篇最要紧的方法论。"
            ),
            ClassicPassage(
                id: "gs-5", section: "总纲",
                original: "要知一世之荣枯，定看五行之宫位。立命可知贵贱，安身便晓根基。",
                plain: "要看一生的荣枯，先定五行局与宫位；命宫定下便知大体，身宫安好便知根基。"
            ),
            ClassicPassage(
                id: "gs-6", section: "总纲",
                original: "第一先看福德，再三细考迁移，分对宫之体用，定三合之源流。",
                plain: "先看福德宫（内在感受），再细看迁移宫（外部环境），分清对宫的体用，理清三合的源流。"
            ),
            ClassicPassage(
                id: "gs-7", section: "总纲",
                original: "命无正曜，夭折孤贫。吉有凶星，美玉瑕玷。",
                plain: "命宫无主星、又无吉星拱照，古人视为孤弱之象；吉星里混着凶星，如美玉带瑕。",
                note: "「夭折孤贫」是绝对化断语。命无正曜的实际含义是：本命色彩淡，环境与选择的权重更大，借对宫之力安身。"
            ),
            ClassicPassage(
                id: "gs-8", section: "总纲",
                original: "既得根源坚固，须知合局相生；坚固则富贵延寿，相生则财官昭著。",
                plain: "根基既稳，还要看局与局是否相生：稳则长久，相生则财与官都显。"
            ),
            ClassicPassage(
                id: "gs-9", section: "总纲",
                original: "命好身好限好，到老荣昌；命衰身衰限衰，终身乞丐。",
                plain: "命、身、限三者都好，晚年仍顺；三者都弱，古人便以困顿论。",
                note: "「终身乞丐」是身份化的重语，不作现实判断。可读为：命身限同时偏弱时，宜借外力与制度，别单靠个人硬撑。"
            ),
            ClassicPassage(
                id: "gs-10", section: "夹拱与身命",
                original: "夹贵夹禄少人知，夹权夹科世所宜。",
                plain: "被贵星、禄星夹拱的情形少有人识得；被权星、科星夹拱则是世人称许的好结构。"
            ),
            ClassicPassage(
                id: "gs-11", section: "夹拱与身命",
                original: "夹日夹月谁能遇，夹昌夹曲主贵兮。",
                plain: "日月夹命难得；昌曲夹命主贵，读书与表达都顺。"
            ),
            ClassicPassage(
                id: "gs-12", section: "夹拱与身命",
                original: "夹空夹劫主贫贱，夹羊夹陀为乞丐。",
                plain: "空劫夹命、羊陀夹命，古人皆以困顿论。",
                note: "两句都是身份化的重语。空劫夹命今读为「对物质黏性低、计划易被打断」；羊陀夹命今读为「进退皆受制」。"
            ),
            ClassicPassage(
                id: "gs-13", section: "夹拱与身命",
                original: "廉贞七杀，反为积富之人；天梁太阴，却作飘蓬之客。",
                plain: "廉贞七杀本主刚烈，反而常出积富之人；天梁太阴本主清高，倒容易四处漂泊。此为「反差」之论，提醒不可单看星性。"
            ),
            ClassicPassage(
                id: "gs-14", section: "夹拱与身命",
                original: "廉贞主下贱之孤寒，太阴主一生之快乐。",
                plain: "古人以廉贞主孤寒、太阴主安乐。",
                note: "「下贱」是身份歧视语，今不采。廉贞的实际表现是原则感强、易较劲；太阴是感受细腻、重安稳。"
            ),
            ClassicPassage(
                id: "gs-15", section: "夹拱与身命",
                original: "先贫后富，武贪同身命之宫；先富后贫，只为运逢劫杀。",
                plain: "武曲贪狼同守身命，多先苦后甜；先富后贫，则常因运限逢劫煞。"
            ),
            ClassicPassage(
                id: "gs-16", section: "夹拱与身命",
                original: "出世荣华，权禄守财福之位；生来贫贱，劫空临财福之乡。",
                plain: "权禄守财帛福德，主早年顺遂；劫空临财福，主早年资源紧。"
            ),
            ClassicPassage(
                id: "gs-17", section: "星曜会照 · 上",
                original: "文昌文曲，为人多学多能；左辅右弼，秉性克宽克厚。",
                plain: "昌曲主多才多艺；辅弼主宽厚能容。"
            ),
            ClassicPassage(
                id: "gs-18", section: "星曜会照 · 上",
                original: "天府天相，乃为衣禄之神，为仕为官，定主亨通之兆。",
                plain: "天府、天相是管衣食的星，入仕为官多主顺遂。"
            ),
            ClassicPassage(
                id: "gs-19", section: "星曜会照 · 上",
                original: "苗而不秀，科名陷于凶神；发不主财，禄主躔于弱地。",
                plain: "有才却不成名，是科星落于凶位；能发却不聚财，是禄星处于弱地。"
            ),
            ClassicPassage(
                id: "gs-20", section: "星曜会照 · 上",
                original: "七杀朝斗，爵禄荣昌。紫府同宫，终身福厚。",
                plain: "七杀朝拱紫微主地位；紫微天府同宫主一生厚福。"
            ),
            ClassicPassage(
                id: "gs-21", section: "星曜会照 · 上",
                original: "紫微居午，无杀凑，位至公卿。天府临戌，有星扶，腰金衣紫。",
                plain: "紫微坐午无煞相扰，气局最正；天府坐戌得吉星扶助，守成有法。"
            ),
            ClassicPassage(
                id: "gs-22", section: "星曜会照 · 上",
                original: "科权禄拱，名誉昭彰。武曲庙垣，威名赫奕。",
                plain: "三奇拱命主名声；武曲庙旺主威名与实绩。"
            ),
            ClassicPassage(
                id: "gs-23", section: "星曜会照 · 上",
                original: "科明禄暗，位列三台。日月同临，官居侯伯。",
                plain: "科星显、禄星藏，主位列高班；日月同宫，主位居要职。"
            ),
            ClassicPassage(
                id: "gs-24", section: "星曜会照 · 上",
                original: "巨机同宫，公卿之位。贪铃并守，将相之名。",
                plain: "巨门天机同宫主高位；贪狼铃星同守主威名。"
            ),
            ClassicPassage(
                id: "gs-25", section: "星曜会照 · 上",
                original: "天魁天钺，盖世文章。天禄天马，惊人甲第。",
                plain: "魁钺主文章出众；禄马主功名显达。"
            ),
            ClassicPassage(
                id: "gs-26", section: "星曜会照 · 上",
                original: "左辅文昌会吉星，尊居八座。贪狼火星居庙旺，名镇诸邦。",
                plain: "辅弼昌曲会吉，主居高位；贪狼火星庙旺，主一时声势。"
            ),
            ClassicPassage(
                id: "gs-27", section: "星曜会照 · 上",
                original: "巨日同宫，官封三代。紫府朝垣，食禄万钟。",
                plain: "巨门得太阳照亮，主以口才专业立业；紫府分守三方，主资源丰厚。"
            ),
            ClassicPassage(
                id: "gs-28", section: "星曜会照 · 上",
                original: "科权对拱，跃三汲于禹门。日月并明，佐九重于尧殿。",
                plain: "科权对照拱命，如鱼跃龙门；日月并明，主辅佐之才。"
            ),
            ClassicPassage(
                id: "gs-29", section: "星曜会照 · 上",
                original: "府相同来会命宫，全家食禄。三合明珠生旺地，稳步蟾宫。",
                plain: "府相会命主家宅安定；空宫得日月拱照，主稳步成名。"
            ),
            ClassicPassage(
                id: "gs-30", section: "星曜会照 · 下",
                original: "七杀破军宜出外，机月同梁作吏人。",
                plain: "七杀破军宜向外闯，机月同梁宜在体制内做文职。"
            ),
            ClassicPassage(
                id: "gs-31", section: "星曜会照 · 下",
                original: "紫府日月居旺地，断定公侯器。日月科禄丑未中，定是方伯公。",
                plain: "紫府日月皆居旺地，气局不凡；日月与科禄同处丑未，主一方之任。"
            ),
            ClassicPassage(
                id: "gs-32", section: "星曜会照 · 下",
                original: "天梁天马陷，飘荡无疑。廉贞杀不加，声名远播。",
                plain: "天梁天马落陷主漂泊；廉贞不见煞，反主名声清正。"
            ),
            ClassicPassage(
                id: "gs-33", section: "星曜会照 · 下",
                original: "日照雷门，富贵荣华。月朗天门，进爵封侯。",
                plain: "太阳坐卯、太阴坐亥，皆为得位，主显达。"
            ),
            ClassicPassage(
                id: "gs-34", section: "星曜会照 · 下",
                original: "寅逢府相，位登一品之荣。墓逢左右，尊居八座之贵。",
                plain: "寅宫得府相，辰戌得辅弼，都是古人称许的贵格。"
            ),
            ClassicPassage(
                id: "gs-35", section: "星曜会照 · 下",
                original: "梁居午位，官资清显。曲遇梁星，位至台纲。",
                plain: "天梁坐午主官声清正；文曲会天梁主位居台纲。"
            ),
            ClassicPassage(
                id: "gs-36", section: "星曜会照 · 下",
                original: "科禄巡逢，周勃欣然入相。文星暗拱，贾谊允矣登科。",
                plain: "科禄相继而来，如周勃入相；文星暗拱，如贾谊登科——皆以史事作比。"
            ),
            ClassicPassage(
                id: "gs-37", section: "星曜会照 · 下",
                original: "擎羊火星，威权出众；同行贪武，威压边夷。",
                plain: "擎羊火星主威权；与贪狼武曲同行，主镇守一方之势。"
            ),
            ClassicPassage(
                id: "gs-38", section: "星曜会照 · 下",
                original: "李广不封，擎羊逢于力士。颜回夭折，文昌陷于天伤。",
                plain: "李广难封、颜回早逝，古人以之喻擎羊逢力士、文昌陷天伤的情形。",
                note: "以历史人物的结局比附命盘，是古代常用的修辞，不是对具体人的预测。"
            ),
            ClassicPassage(
                id: "gs-39", section: "星曜会照 · 下",
                original: "仲由猛烈，廉贞入庙遇将军。子羽才能，巨宿同梁冲且合。",
                plain: "子路之猛、子羽之才，分别对应廉贞入庙遇将军、巨门与同梁冲合的结构。"
            ),
            ClassicPassage(
                id: "gs-40", section: "星曜会照 · 下",
                original: "寅申最喜同梁会，辰戌应嫌陷巨门。",
                plain: "寅申得同梁相会最佳；辰戌则忌巨门落陷。"
            ),
            ClassicPassage(
                id: "gs-41", section: "煞忌与限运",
                original: "禄倒马倒，忌太岁之合劫空。运衰限衰，喜紫微之解凶厄。",
                plain: "禄马倒陷，怕太岁再合劫空；运限衰弱时，得紫微则有转圜之力。"
            ),
            ClassicPassage(
                id: "gs-42", section: "煞忌与限运",
                original: "孤贫多有寿，富贵每夭亡。",
                plain: "处境清苦者往往寿长，富贵者反倒常不永年。",
                note: "这是古人对世事的感慨，不是规律。健康取决于作息、体检与就医，与贫富无必然关系。"
            ),
            ClassicPassage(
                id: "gs-43", section: "煞忌与限运",
                original: "吊客丧门，绿珠有堕楼之厄。官符太岁，公冶有缧绁之忧。",
                plain: "吊客丧门主哀伤之事，官符太岁主是非缠身——以绿珠、公冶长作比。"
            ),
            ClassicPassage(
                id: "gs-44", section: "煞忌与限运",
                original: "限至天罗地网，屈原溺水而亡。运遇地劫天空，阮籍有途穷之苦。",
                plain: "限入辰戌天罗地网、运逢空劫，古人以屈原、阮籍的困境作比。",
                note: "「溺水而亡」是古人的比附说法，不作现实推断。今读为：限入辰戌时空劫易生阻滞，宜守成、少冒进。"
            ),
            ClassicPassage(
                id: "gs-45", section: "煞忌与限运",
                original: "生逢天空，犹如半天折翅；命中遇劫，恰如浪里行船。",
                plain: "生逢空亡如半空折翅，命遇劫煞如浪里行船——都是形容做事缺少着力点。"
            ),
            ClassicPassage(
                id: "gs-46", section: "煞忌与限运",
                original: "项羽英雄，限至天空而丧国；石崇豪富，限行劫地以亡家。",
                plain: "项羽、石崇的败亡，古人归因于限逢空劫。此为借史喻理，非定论。"
            ),
            ClassicPassage(
                id: "gs-47", section: "煞忌与限运",
                original: "吕后专权，两重天禄天马；杨妃好色，三合文曲文昌。",
                plain: "吕后之权、杨妃之艳，古人分别以禄马重叠、昌曲三合作解。"
            ),
            ClassicPassage(
                id: "gs-48", section: "煞忌与限运",
                original: "极居卯酉，多为脱俗僧人；贞居卯酉，定是公胥吏辈。",
                plain: "紫微坐卯酉，多主志趣脱俗；廉贞坐卯酉，多主从事公职文书。"
            ),
            ClassicPassage(
                id: "gs-49", section: "煞忌与限运",
                original: "左府同宫，尊居万乘；廉贞七杀，流荡天涯。",
                plain: "左辅与天府同宫主位高；廉贞七杀则主四处奔忙。"
            ),
            ClassicPassage(
                id: "gs-50", section: "煞忌与限运",
                original: "邓通饿死，运逢大耗之乡；夫子绝粮，限到天伤之内。",
                plain: "邓通之贫、孔子绝粮，古人以运逢大耗、限到天伤作解。"
            ),
            ClassicPassage(
                id: "gs-51", section: "煞忌与限运",
                original: "命里逢空，不飘流即主疾苦；马头带箭，非夭折则主刑伤。",
                plain: "空劫坐命、擎羊坐午，古人皆以辛苦论。",
                note: "「疾苦」「夭折」是绝对化推断，不作现实判断。今读为：空劫坐命宜靠流程而非靠状态；擎羊坐午宜留意安全、避免逞强。"
            ),
            ClassicPassage(
                id: "gs-52", section: "煞忌与限运",
                original: "子午破军，加官进禄；昌贪居命，粉骨碎尸。",
                plain: "破军坐子午主升迁；昌曲与贪狼同守命，古人视为劳碌之极。",
                note: "「粉骨碎尸」为夸张的文学化表达，不作现实推断。今读为：才气外露而欲望又强，宜防过度消耗。"
            ),
            ClassicPassage(
                id: "gs-53", section: "论性情",
                original: "朝斗仰斗，爵禄荣昌；文桂文华，九重贵显。",
                plain: "七杀朝斗、仰斗主地位；文昌文曲会照主显达。"
            ),
            ClassicPassage(
                id: "gs-54", section: "论性情",
                original: "丹墀桂墀，早遂青云之志；合禄拱禄，定为巨擘之臣。",
                plain: "日月得位、禄星合拱，都是少年得志、堪当大任的结构。"
            ),
            ClassicPassage(
                id: "gs-55", section: "论性情",
                original: "阴阳会昌曲，出世荣华；辅弼遇财官，衣绯着紫。",
                plain: "日月会昌曲主名声；辅弼遇财官主位显。"
            ),
            ClassicPassage(
                id: "gs-56", section: "论性情",
                original: "巨梁相会廉贞并，合禄鸳鸯一世荣。",
                plain: "巨门、天梁、廉贞相会又合禄，主一生衣禄不缺。"
            ),
            ClassicPassage(
                id: "gs-57", section: "论性情",
                original: "武曲闲宫多手艺，贪狼陷地作屠人。",
                plain: "武曲落闲宫，多靠一技之长谋生；贪狼落陷，古人以屠户作比。",
                note: "「作屠人」带职业歧视，今不采。可读为：贪狼落陷时，才华需要具体手艺来承接，光有想法不足以成事。"
            ),
            ClassicPassage(
                id: "gs-58", section: "论性情",
                original: "天禄朝垣，身荣贵显；魁星临命，位列三台。",
                plain: "禄星朝命主荣显；魁星临命主位居高位。"
            ),
            ClassicPassage(
                id: "gs-59", section: "论性情",
                original: "武曲居干戌亥上，最怕太阴逢贪狼。化禄还为好，休向墓中藏。",
                plain: "武曲坐戌亥，怕与太阴贪狼同处；有化禄为好，但不喜落入墓库。"
            ),
            ClassicPassage(
                id: "gs-60", section: "论性情",
                original: "子午巨门，石中隐玉；明禄暗禄，锦上添花。",
                plain: "巨门坐子午为石中隐玉，才学需时间显；明禄暗禄同会，则锦上添花。"
            ),
            ClassicPassage(
                id: "gs-61", section: "论性情",
                original: "紫微辰戌遇破军，富而不贵有虚名。",
                plain: "紫微在辰戌遇破军，主有钱却难副名望。"
            ),
            ClassicPassage(
                id: "gs-62", section: "论性情",
                original: "昌曲破军逢，刑克多劳碌；贪武墓中居，三十才发福。",
                plain: "昌曲遇破军，多劳少成；贪武落墓库，三十岁后才渐入佳境。"
            ),
            ClassicPassage(
                id: "gs-63", section: "论性情",
                original: "天同戌宫为反背，丁人化吉主大贵。巨门辰戌为陷地，辛人化吉禄峥嵘。机梁酉上化吉者，纵遇财官也不荣。",
                plain: "天同在戌、巨门在辰戌、机梁在酉，都属落陷；若生年干能化吉则可转，否则纵有财官也难显。"
            ),
            ClassicPassage(
                id: "gs-64", section: "论性情",
                original: "日月最嫌反背，乃为失辉；命身定要精求，恐差分数。",
                plain: "日月反背便失光辉；命宫身宫要仔细推求，差一位结果就不同。"
            ),
            ClassicPassage(
                id: "gs-65", section: "论性情",
                original: "阴骘延年增百福，至于陷地不遭伤。",
                plain: "积德行善可延年添福，纵落陷地也不至于受伤——这是全篇唯一把「人为」写进命理的一句。"
            ),
            ClassicPassage(
                id: "gs-66", section: "论性情",
                original: "命实运坚，稿田得雨；命衰限弱，嫩草遭霜。",
                plain: "命实运坚如旱田得雨；命衰限弱如嫩草遇霜——讲的是「底子与时机」的配合。"
            ),
            ClassicPassage(
                id: "gs-67", section: "论性情",
                original: "论命必推星善恶：巨破擎羊性必刚，府相同梁性必好，火劫空贪性不常，昌曲禄机清秀巧，阴阳左右最慈祥。",
                plain: "论性情要看星的性质：巨门破军擎羊性刚，府相同梁性善，火铃空劫贪狼性不定，昌曲禄机清秀灵巧，日月辅弼最为温和。"
            ),
            ClassicPassage(
                id: "gs-68", section: "论性情",
                original: "武破贞贪，冲合曲全固贵；羊陀七杀，相杂互见则伤。",
                plain: "武曲破军廉贞贪狼，得昌曲调候则贵；羊陀七杀混杂，则主损耗。"
            ),
            ClassicPassage(
                id: "gs-69", section: "论性情",
                original: "贪狼廉贞破军恶，七杀擎羊陀罗凶。火星铃星专作祸，劫空伤使祸重重。",
                plain: "贪狼、廉贞、破军、七杀、羊陀、火铃、空劫，古人统称为凶曜。",
                note: "把星曜分「善恶」是古代的分类法。现代读法：这些星代表强度高、摩擦大的能量，重点是用法与节奏，不是好坏。"
            ),
            ClassicPassage(
                id: "gs-70", section: "论性情",
                original: "巨门忌星皆不吉，运身命限忌相逢。更兼太岁官符至，官非口舌决不空；吊客丧门又相遇，管教灾病两相攻。",
                plain: "巨门与化忌同会本就不吉，若再逢太岁、官符、吊客、丧门，主口舌与病痛接连而来。"
            ),
            ClassicPassage(
                id: "gs-71", section: "收束",
                original: "心好命微亦主寿，心毒命固亦夭亡。今人命有千金贵，运去之时岂久长。",
                plain: "心善而命弱也能长寿，心恶而命强也会早衰；今日纵有千金之贵，运去时也难长久。"
            ),
            ClassicPassage(
                id: "gs-72", section: "收束",
                original: "数内包藏多少理，学者须当仔细详。",
                plain: "这套数术里藏着的道理很多，学的人应当仔细推详。"
            )
        ]
    )

    // MARK: - 形性赋

    static let xingXingFu = ClassicWork(
        title: "形性赋",
        subtitle: "以形写性 · 十四主星性情",
        author: "旧题陈抟",
        era: "宋代（明刊本）",
        intro: "以形貌与神态写各星性情，是十四主星最凝练的性格速写。读它不必照字面看相貌，取「性情与取向」即可。",
        note: "底本依明刊《紫微斗数全书》卷一。原文对相貌、身份的评断带有时代偏见（如「形丑貌粗」「奸诈」），本版照录并加「今按」，只取性情一层。全篇无删略。",
        passages: [
            ClassicPassage(
                id: "xx-1", section: "十四主星",
                original: "原夫紫微帝座，生为厚重之容。天府尊星，也作纯和之体。",
                plain: "紫微是帝座，气象厚重；天府同为尊星，体性纯和。",
                note: "「厚重」「纯和」是气度描写，不是长相标准。"
            ),
            ClassicPassage(
                id: "xx-2", section: "十四主星",
                original: "金乌圆满，玉兔清奇。",
                plain: "太阳（金乌）主圆满外放，太阴（玉兔）主清秀内敛。"
            ),
            ClassicPassage(
                id: "xx-3", section: "十四主星",
                original: "天机为不长不短之姿，情怀好善。",
                plain: "天机身形适中，心性向善，喜欢琢磨事理。"
            ),
            ClassicPassage(
                id: "xx-4", section: "十四主星",
                original: "武曲乃至要至紧之操，心性果决。",
                plain: "武曲自持严谨，做事干脆，讲求效率与实用。"
            ),
            ClassicPassage(
                id: "xx-5", section: "十四主星",
                original: "天同肥满，目秀清奇。",
                plain: "天同体态丰腴、眼神清秀，性子和缓，重舒适。"
            ),
            ClassicPassage(
                id: "xx-6", section: "十四主星",
                original: "廉贞眉宽，口阔面横，为人性暴，好忿好争。",
                plain: "廉贞眉目开阔，性子刚烈，遇不平容易上头。",
                note: "古书以面貌断性情，今不采其相貌部分；「好忿好争」可读为原则感强、对错分明。"
            ),
            ClassicPassage(
                id: "xx-7", section: "十四主星",
                original: "贪狼为善恶之星，入庙必应长耸，出垣必定顽嚣。",
                plain: "贪狼是可善可恶的星：得地则挺拔出众，失位则任性难驯。"
            ),
            ClassicPassage(
                id: "xx-8", section: "十四主星",
                original: "巨门乃是非之曜，在庙敦厚温良。",
                plain: "巨门主口舌是非，但得地时反而敦厚温和——关键在有没有光来照。"
            ),
            ClassicPassage(
                id: "xx-9", section: "十四主星",
                original: "天相精神，天梁稳重，心事玉洁冰清。",
                plain: "天相神采外显，天梁沉稳持重，内里讲原则、重清白。"
            ),
            ClassicPassage(
                id: "xx-10", section: "十四主星",
                original: "七杀如子路暴虎冯河，火铃似豫让吞炭装哑。",
                plain: "七杀如子路徒手搏虎，勇而少谋；火铃如豫让吞炭装哑，忍而蓄势。"
            ),
            ClassicPassage(
                id: "xx-11", section: "十四主星",
                original: "暴虎冯河兮目太凶狠，吞炭装哑兮暗狼声沉。",
                plain: "搏虎者眼神凶狠，装哑者声气低沉——都是写「劲」往哪里使。"
            ),
            ClassicPassage(
                id: "xx-12", section: "十四主星",
                original: "俊雅文昌眉清目秀，磊落文曲口舌便佞，在庙定生异痣，失陷必有斑痕。",
                plain: "文昌俊雅、长于条理；文曲磊落、长于口才。得地则显其秀，失位则留其瑕。",
                note: "「异痣」「斑痕」属古代相法，不作依据；可取的是「得地则秀、失位则瑕」。"
            ),
            ClassicPassage(
                id: "xx-13", section: "辅佐与煞曜",
                original: "左辅右弼温良规模，端庄高士。天魁天钺具足威仪，重合三台则十全模范。",
                plain: "辅弼温良有格局，魁钺威仪得体；再合三台，便是周全的典范。"
            ),
            ClassicPassage(
                id: "xx-14", section: "辅佐与煞曜",
                original: "擎羊陀罗，形丑貌粗，有矫诈体态。",
                plain: "擎羊、陀罗古书以形貌贬语写之，指其性急而多阻。",
                note: "「形丑貌粗」「矫诈」是人身贬抑，本版只取「性急、多阻、耐磨」一层，不作评价。"
            ),
            ClassicPassage(
                id: "xx-15", section: "辅佐与煞曜",
                original: "破军不仁，背重眉宽，行坐腰斜，奸诈好行惊险。",
                plain: "破军不守成规，行事偏险。",
                note: "「不仁」「奸诈」是道德评判，今不采。破军的实际表现是敢推倒重来、不喜旧法。"
            ),
            ClassicPassage(
                id: "xx-16", section: "辅佐与煞曜",
                original: "性貌如春和蔼，乃是禄存之情德。情怀似火锋冲，此诚破耗之威权。",
                plain: "禄存性子和煦；破军耗星则情急气盛，有威权之势。"
            ),
            ClassicPassage(
                id: "xx-17", section: "辅佐与煞曜",
                original: "星论庙旺，最怕空亡；杀落空亡，竟无威力。",
                plain: "论星先看庙旺，最怕落空亡；煞星落空，反倒失了威力。"
            ),
            ClassicPassage(
                id: "xx-18", section: "辅佐与煞曜",
                original: "权禄乃九窍之奇，耗积散平生之福。",
                plain: "权禄是灵通之资，耗星则耗散一生的积累。"
            ),
            ClassicPassage(
                id: "xx-19", section: "论格局与取舍",
                original: "禄逢梁荫，抱私财益与他人；耗遇贪狼，逞淫情于井底。",
                plain: "禄逢梁荫，主替人管财；耗遇贪狼，主情欲难收。",
                note: "「逞淫情」是道德评判，今读为「欲望与消耗叠在一起时，容易失控」。"
            ),
            ClassicPassage(
                id: "xx-20", section: "论格局与取舍",
                original: "贪星入于马垣，易善易恶；恶曜扶同善曜，禀性不常。",
                plain: "贪狼入马位，善恶易变；凶吉混杂，性情就不稳定。"
            ),
            ClassicPassage(
                id: "xx-21", section: "论格局与取舍",
                original: "财居空亡，巴三览四；文曲旺宫，闻一知十。",
                plain: "财落空亡，主意不定、样样想沾；文曲得地，闻一知十。"
            ),
            ClassicPassage(
                id: "xx-22", section: "论格局与取舍",
                original: "善禄定是奇高之艺细巧，伶俐之人。",
                plain: "善星与禄星相配，多在精细手艺与灵巧之事上出众。"
            ),
            ClassicPassage(
                id: "xx-23", section: "论格局与取舍",
                original: "男居生旺最要得地，女居死绝专看福德。",
                plain: "古人看男命重得地、女命重福德。",
                note: "男女分论是旧时代的分工观念，本版照录但不再沿用；今按同一标准看命身与福德。"
            ),
            ClassicPassage(
                id: "xx-24", section: "论格局与取舍",
                original: "命最嫌立于败位，财源却怕逢空亡。",
                plain: "命宫最忌落败绝之地，财源最怕逢空亡。"
            ),
            ClassicPassage(
                id: "xx-25", section: "论格局与取舍",
                original: "机刑杀荫孤星论嗣续之宫，加恶星忌耗，不为奇特。陀耗囚之星守父母之缠，决然破祖刑伤。",
                plain: "子女宫见机刑杀荫等孤星，再逢恶曜，主缘分偏薄；父母宫见陀耗囚，主早年离祖。"
            ),
            ClassicPassage(
                id: "xx-26", section: "总收",
                original: "紫微肥满，天府精神，禄存禄主也应厚重。日月曲相同梁机昌，皆为美俊之姿，乃是清奇之格，上长下短，目秀眉清。",
                plain: "紫微、天府、禄存气度厚重；日月、昌曲、天相、天同、天梁、天机则多清秀俊朗。"
            ),
            ClassicPassage(
                id: "xx-27", section: "总收",
                original: "贪狼同武曲，形小声高而量大；天同加陀忌，肥满而目渺。",
                plain: "贪狼与武曲同宫，身形不大而声气足、气量大；天同遇陀忌，体丰而神气偏弱。"
            ),
            ClassicPassage(
                id: "xx-28", section: "总收",
                original: "擎羊身体遭伤，若遇火铃巨暗必生异痣，又值耗杀定主形丑貌粗。",
                plain: "擎羊主身体易受伤；再遇火铃巨门暗曜，则多留痕迹。",
                note: "「形丑貌粗」不作评价。可取的是「擎羊主伤」，即注意安全与运动损伤。"
            ),
            ClassicPassage(
                id: "xx-29", section: "总收",
                original: "若居死绝之限，童子乳哺徒劳其力，老者亦然寿终。",
                plain: "限运走到死绝之地，幼者难养、老者难支——古人以此提醒幼年与晚年最须护持。"
            ),
            ClassicPassage(
                id: "xx-30", section: "总收",
                original: "此数中之纲领，乃为星纬之机关。玩味专精，以参玄妙。",
                plain: "以上是斗数的纲领，也是诸星运转的关键；反复玩味、专精下去，才能体会其中的细微。"
            ),
            ClassicPassage(
                id: "xx-31", section: "总收",
                original: "限有高低，星寻喜怒，假如运限驳杂，终有浮沉。如逢杀地，更要推详；倘遇空亡，必须细察。精研于此，不患不神。",
                plain: "运限有高有低，星性有喜有怒；运限驳杂时必有起伏。遇煞地要细推，逢空亡要细察。钻研到这一层，自然有得。"
            )
        ]
    )
}
