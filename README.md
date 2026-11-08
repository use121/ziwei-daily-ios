# 紫微日常 · ZiWei Daily

一个原生 SwiftUI 的紫微斗数 App：输入出生信息完成排盘，并按当天日期给出 100 分制的「今日状态评分」与一句话结论。

> 本项目为传统文化兴趣作品，所有内容仅供自我觉察与娱乐参考，不构成任何决策依据。

## 功能

| 模块 | 说明 |
| --- | --- |
| 信息录入 | 出生日期、出生时间、性别、出生地、时区、经度；支持常用城市快选、晚子时归日、真太阳时校正 |
| 排盘结果 | 命宫/身宫、十二宫天干、五行局、十四主星、辅曜、生年四化、大限、流年；传统方盘 + 列表双视图 |
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
Tests/ZiWeiCoreTests/             10 组单元测试
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

## 自签名安装到 iPhone

CI 产出的 IPA 是**未签名**的（无 `_CodeSignature`、无 `embedded.mobileprovision`），需要用自己的证书签一次。

### 方式 A：Sideloadly / AltStore（最省事）

1. 下载 IPA（Release 页面或 Actions Artifact）。
2. 用 Sideloadly 拖入 IPA，填 Apple ID，开始签名安装。
3. 首次运行需在「设置 → 通用 → VPN与设备管理」信任证书。
4. 免费账号签名 7 天有效，付费开发者账号 1 年有效。

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
cd stage && zip -qry ../ZiWeiDaily-signed.ipa Payload
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

## License

MIT
