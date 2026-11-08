# 紫微日常 · ZiWei Daily

一个原生 SwiftUI 的紫微斗数 App：输入出生信息完成排盘，并按当天日期给出 100 分制的「今日状态评分」与一句话结论。

> 本项目为传统文化兴趣作品，所有内容仅供自我觉察与娱乐参考，不构成任何决策依据。

## 功能

| 模块 | 说明 |
| --- | --- |
| 信息录入 | 出生日期、出生时间、性别、出生地、时区、经度；支持常用城市快选、晚子时归日、真太阳时校正 |
| 排盘结果 | 命宫/身宫、十二宫天干、五行局、十四主星、辅曜、生年四化、大限、流年；传统方盘 + 列表双视图 |
| 时间层 | 本命 / 大限 / 流年 三视图切换，大限与年份可步进；切换后十二宫名整体旋转，并叠加该层四化 |
| 星曜亮度 | 庙旺得利平不陷七档，按《紫微斗数全书》派标注，悬停即见 |
| 宫位解读 | 点选宫位高亮三方四正，弹出四段式解读：宫位定性 / 主星解读 / 三方四正联动 / 四化与建议 |
| 六维解读 | 命格、性格、感情、事业、财运、健康六张卡，规则确定性生成 |
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
  TimeLayer.swift                 本命/大限/流年时间层与盘面旋转
  InsightEngine.swift             六维与单宫解读生成
Tests/ZiWeiCoreTests/             20 项单元测试
App/ZiWeiDaily/                   SwiftUI 应用
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
   - 看文件大小是否为 297,585 字节（deflate 版）/ 808,332 字节（store 版）。偏小说明下载被截断，重新传输。
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

## 数据来源

星曜七档亮度表参考 [Renhuai123/ziwei-doushu](https://github.com/Renhuai123/ziwei-doushu)（MIT License）整理的全星亮度数据，按其金标准盘核对口径收录。排盘与解读逻辑为本项目独立实现的 Swift 版本。

## License

MIT
