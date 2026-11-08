# 紫微日常 · ZiWei Daily

一个原生 SwiftUI 的紫微斗数 App：输入出生信息完成排盘，并按当天日期给出 100 分制的「今日状态评分」与一句话结论。

> 本项目为传统文化兴趣作品，所有内容仅供自我觉察与娱乐参考，不构成任何决策依据。

## 功能

| 模块 | 说明 |
| --- | --- |
| 信息录入 | 出生日期、出生时间、性别、出生地、时区、经度；支持常用城市快选、晚子时归日、真太阳时校正 |
| 排盘结果 | 命宫/身宫、十二宫天干、五行局、十四主星、辅曜、生年四化、大限、流年；传统方盘 + 列表双视图 |
| 时间层 | 本命 / 大限 / 流年 / 流月 / 流日 / 流时 六视图切换，大限、年月日时均可步进；切换后十二宫名整体旋转，并叠加该层四化 |
| 飞星自化 | 十二宫各以宫干飞四化并标注落宫；落回本宫记为自化，宫格标「自」，详情页列完整飞出路径 |
| 长生十二神 | 按五行局起长生（水二申/木三亥/金四巳/土五申/火六寅），阳男阴女顺、阴男阳女逆，逐宫标注并附简释 |
| 小限 | 按生年支三合局起一岁，男顺女逆，标注当年小限所在宫 |
| 古籍摘编 | 格局配《太微赋》《骨髓赋》公版原文摘录 + 白话，注明出处 |
| 多档案 | 为家人朋友各建一份档案，随时切换；旧版单档案数据自动迁移 |
| 长图导出 | 整盘 + 四化 + 格局 + 六维评分渲染为一张长图，经系统分享面板保存或发送 |
| 历法口径 | 闰月四口径（当本月/作下月/十五为界/中气分界）+ 1986–1991 夏令时自动回拨，均可开关 |
| 星曜亮度 | 庙旺得利平不陷七档，按《紫微斗数全书》派标注，悬停即见 |
| 辅星神煞 | 14 主星 + 28 辅星神煞，含火星铃星、天姚天刑、三台八座、恩光天贵、龙池凤阁、天哭天虚、天伤天使 |
| 命主身主 | 命主按命宫支、身主按生年支，另附博士十二神 |
| 宫位解读 | 点选宫位高亮三方四正，弹出四段式解读：宫位定性 / 主星解读 / 三方四正联动 / 四化与建议 |
| 十四维解读 | 核心六维（命格/性格/感情/事业/财运/健康）+ 贵人分析（魁钺辅弼/禄存/恩光天贵落宫与引动）+ 七宫细读（兄弟/子女/迁移/交友/田宅/福德/父母），可切换「核心六维 / 全部十四维」 |
| 经典格局 | 紫府同宫、君臣庆会、杀破狼、机月同梁、月朗天门、日照雷门、石中隐玉、七杀朝斗、雄宿朝垣、文桂文华、科权禄拱、禄马交驰、火贪/铃贪、羊陀夹忌、命无正曜、天罗地网等，按吉格/常格/留意分类 |
| 四化路径 | 禄权科忌逐条列出落宫，并判断禄忌之间的同宫/对宫/三合/邻宫关系 |
| 雷达图 | 六维强弱雷达，图形化看结构偏斜 |
| 报告导出 | 系统分享，输出命盘摘要 + 十四维 + 格局 + 四化 + 今日评分 |
| 今日评分 | 0–100 总分、状态标签、事业/财务/人际/身心四项分数、评分依据、行动建议、流日四化 |
| 输入校验 | 年份区间、未来日期、经度格式、出生地非空、称呼长度等逐字段提示 |

评分逻辑为确定性计算：同一张命盘 + 同一天，结果完全一致。

## 目录结构

```
Package.swift                     ZiWeiCore 本地 Swift Package
Sources/ZiWeiCore/
  Models.swift                    核心数据模型
  Ganzhi.swift                    农历换算、干支、时辰、真太阳时
  InputValidator.swift            输入校验
  ChartEngine.swift               排盘：命身宫、五行局、十四主星、四化、大限
  FortuneEngine.swift             今日评分与状态结论
  StarCatalog.swift               星曜关键词与权重表
  Brightness.swift                星曜七档亮度表（全书派）
  TimeLayer.swift                 六层时间层（本命/大限/流年/流月/流日/流时）与盘面旋转
  InsightEngine.swift             十四维（含贵人分析）与单宫解读生成
  ExtendedStars.swift             辅星神煞安星、命主身主、博士十二神
  PatternEngine.swift             经典格局判定
  TransformationPath.swift       四化路径与十四维评分（贵人单列算法）
  Longevity.swift                 长生十二神、小限、飞星与自化
  Classics.swift                  公版古籍断语摘编
Tests/ZiWeiCoreTests/             42 项单元测试
App/ZiWeiDaily/                   SwiftUI 应用（含长图导出 SharePosterView）
project.yml                       XcodeGen 工程描述
Scripts/build_ipa.sh              本地构建未签名 IPA
.github/workflows/build-ipa.yml   CI：测试 + 归档 + 打包未签名 IPA
```

## 本地运行

```bash
# 1. 生成 Xcode 工程
brew install xcodegen
xcodegen generate

# 2. 跑核心测试
swift test --disable-sandbox

# 3. 打开工程
open ZiWeiDaily.xcodeproj
```

在 Xcode 中把 Signing Team 改成你自己的开发者账号，选真机运行即可。

## 构建未签名 IPA

```bash
./Scripts/build_ipa.sh
# 产物: Export/ZiWeiDaily-unsigned.ipa
```

## 下载哪个 IPA

Release 里有两个文件，内容完全相同，只是 zip 封装方式不同：

| 文件 | 封装 | 用在哪 |
| --- | --- | --- |
| `ZiWeiDaily-unsigned.ipa` | deflate + 零附加字段 | 默认用这个，Sideloadly / AltStore / Xcode 都认 |
| `ZiWeiDaily-unsigned-store.ipa` | 全 store（不压缩）+ 零附加字段 | 上面那个被签名工具报「格式不支持」时换这个 |

两个包都用 `zip -X` 打包，去掉了 Info-ZIP 默认写入的 `0x5455`（时间戳）和 `0x7875`（Unix UID/GID）附加字段。少数签名工具用「本地头顺序扫描」解析 IPA，遇到这两个字段会直接判定格式不支持。CI 里也加了结构自检（CRC、`Payload/*.app/Info.plist`、无 `__MACOSX`）。

下载后可以先核对大小与哈希，排除传输被截断：

```bash
shasum -a 256 ZiWeiDaily-unsigned.ipa
```

## 自签名安装到 iPhone

CI 产出的 IPA 是**未签名**的（无 `_CodeSignature`、无 `embedded.mobileprovision`），需要用自己的证书签一次。

### 方式 A：Sideloadly / AltStore（最省事）

1. 下载 IPA（Release 页面或 Actions Artifact）。
2. 用 Sideloadly 拖入 IPA，填 Apple ID，开始签名安装。
3. 首次运行需在「设置 → 通用 → VPN与设备管理」信任证书。
4. 免费账号签名 7 天有效，付费开发者账号 1 年有效。

### 方式 B：手机端签名工具（全能签 / 轻松签）

1. 先用「设置 → 无线传输」把 IPA 从电脑浏览器传给手机，**不要用聊天软件转发**——微信/QQ 传输会改文件名、也可能截断。
2. 在「导入文件」里选 IPA。
3. 若提示「文件格式不支持或导入失败」，按顺序排查：
   - 看文件大小是否约 450–470 KB（deflate 版）/ 1.1–1.2 MB（store 版）。偏小说明下载被截断，重新传输。
   - 换另一个变体再试一次（deflate ↔ store）。
   - 文件名里的空格和「 2」是浏览器重名后缀，建议改名成 `ZiWeiDaily.ipa` 再导入。

### 方式 B：Xcode 手动签名

```bash
# 1. 解包
unzip ZiWeiDaily-unsigned.ipa -d stage

# 2. 用你的描述文件签名（把文件名换成自己的）
codesign -f -s "Apple Development: you@example.com (XXXXXXXXXX)" \
  --entitlements your.mobileprovision entitlements.plist \
  stage/Payload/ZiWeiDaily.app

# 3. 塞入描述文件并重新打包
cp your.mobileprovision stage/Payload/ZiWeiDaily.app/embedded.mobileprovision
cd stage && zip -qryX ../ZiWeiDaily-signed.ipa Payload
```

更稳妥的做法是直接 `xcodegen generate` 后用 Xcode `Product → Archive → Distribute App → Development` 导出，Xcode 会自动处理描述文件与权限。

## GitHub Actions

推送到 `main` 或打 tag 时自动执行：`swift test` → `xcodegen generate` → 未签名 Release archive → 打包 IPA。

- 日常构建产物在 Actions 页面的 Artifacts 中
- 打 `v*` tag 会自动创建 Release 并附上 IPA

## 技术要点

- **农历换算**：基于 Foundation `Calendar(identifier: .chinese)`，配合干支纪年、纪日与五虎遁推月干。
- **紫微定位**：五行局定紫微落宫，采用「生日补数整除 + 单数逆、双数顺」规则；闰月按对应正月天数 + 闰月日数处理。
- **真太阳时**：经度时差（每度 4 分钟）+ 均时差（年内日序正弦拟合），可选开关。
- **今日评分**：基础分 + 流日命宫三方四正星曜权重 + 流日四化 + 本命四化 + 日干与五行局生克，最后叠加基于日期键与命盘种子的稳定哈希偏移。
- **时间层（活盘）**：星曜位置固定，改变的是以哪一宫为命宫。大限以宫干起四化，流年以年干起四化，十二宫名按 `命宫 → 兄弟 → 夫妻…` 逆时针整体旋转。
- **解读生成**：由宫位、主星、亮度、四化、三方四正组合成句，纯规则、无随机。同一命盘同一时间层，输出逐字一致。
- **格局判定**：以当前层命宫三方四正内出现的星曜组合、四化落点、羊陀夹忌等条件逐条匹配，不做概率打分。
- **四化路径**：按宫位差值 0/6/4·8/1·11 判定同宫、对宫、三合、邻宫，对应不同推进方式的提示。
- **流月/流日/流时**：月干、时干均由五虎遁、五鼠遁推出；流月命宫由流年命宫起正月顺数，流日由流月命宫起初一顺数，流时由流日命宫起子时顺数。
- **飞星与自化**：十二宫各以宫干飞四化（共 48 条），落回本宫即自化；自化表示这股能量在本宫内部消化，先看落宫再看是否回本。
- **长生十二神**：五行局定长生起宫，方向与大限顺逆一致，十二神按序布十二宫。
- **贵人分析**：不按单宫看，而是看魁钺（明/暗贵人）、左辅右弼（同辈助力）、禄存（衣食之助）、恩光天贵（声誉提携）七颗星各坐哪一宫，判断助力从哪个领域来；再叠当前层的四化，看贵人位是否被引动。
- **小限**：寅午戌起辰、申子辰起戌、巳酉丑起未、亥卯未起丑，男顺女逆，一年一宫。
- **闰月四口径**：默认闰月视同本月且安紫微累计上一月天数；另有作下月、十五为界、中气分界三种可切。
- **夏令时**：1986–1991 年国内夏令时窗口内出生，自动回拨 60 分钟后再定时辰，可在资料页关闭。

## 数据来源

星曜七档亮度表参考 [Renhuai123/ziwei-doushu](https://github.com/Renhuai123/ziwei-doushu)（MIT License）整理的全星亮度数据，按其金标准盘核对口径收录。排盘与解读逻辑为本项目独立实现的 Swift 版本。

## License

MIT
