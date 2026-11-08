import SwiftUI
import UIKit
import ZiWeiCore

private struct PlacePreset: Identifiable {
    let name: String
    let longitude: String
    let timeZone: String
    var id: String { name }
}

struct BirthInputView: View {
    @EnvironmentObject private var state: AppState
    @State private var showClearConfirmation = false
    @State private var showDeleteProfileConfirmation = false

    private let places = [
        PlacePreset(name: "北京", longitude: "116.4074", timeZone: "Asia/Shanghai"),
        PlacePreset(name: "上海", longitude: "121.4737", timeZone: "Asia/Shanghai"),
        PlacePreset(name: "广州", longitude: "113.2644", timeZone: "Asia/Shanghai"),
        PlacePreset(name: "深圳", longitude: "114.0579", timeZone: "Asia/Shanghai"),
        PlacePreset(name: "杭州", longitude: "120.1551", timeZone: "Asia/Shanghai"),
        PlacePreset(name: "成都", longitude: "104.0665", timeZone: "Asia/Shanghai"),
        PlacePreset(name: "西安", longitude: "108.9402", timeZone: "Asia/Shanghai"),
        PlacePreset(name: "中国香港", longitude: "114.1694", timeZone: "Asia/Hong_Kong"),
        PlacePreset(name: "中国澳门", longitude: "113.5439", timeZone: "Asia/Macau"),
        PlacePreset(name: "中国台湾·台北", longitude: "121.5654", timeZone: "Asia/Taipei"),
        PlacePreset(name: "新加坡", longitude: "103.8198", timeZone: "Asia/Singapore"),
        PlacePreset(name: "东京", longitude: "139.6917", timeZone: "Asia/Tokyo"),
        PlacePreset(name: "伦敦", longitude: "-0.1276", timeZone: "Europe/London"),
        PlacePreset(name: "纽约", longitude: "-74.0060", timeZone: "America/New_York")
    ]

    private let zones = [
        "Asia/Shanghai", "Asia/Hong_Kong", "Asia/Macau", "Asia/Taipei", "Asia/Singapore",
        "Asia/Tokyo", "Australia/Sydney", "Europe/London", "Europe/Paris",
        "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles"
    ]

    private var supportedDates: ClosedRange<Date> {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = ChineseCalendarConverter.timeZone(for: state.input.timeZoneIdentifier)
        let start = calendar.date(from: DateComponents(year: 1900, month: 1, day: 1))!
        return start...Date()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Menu {
                        ForEach(state.profiles) { profile in
                            Button {
                                state.selectProfile(profile.id)
                            } label: {
                                if profile.id == state.currentProfileID {
                                    Label(profile.name, systemImage: "checkmark")
                                } else {
                                    Text(profile.name)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("当前档案")
                            Spacer()
                            Text(state.currentProfileName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button("新建档案") { state.addProfile() }
                    if state.profiles.count > 1 {
                        Button("删除当前档案", role: .destructive) {
                            showDeleteProfileConfirmation = true
                        }
                    }
                } header: {
                    Text("档案")
                } footer: {
                    Text("可以为家人朋友各建一份档案，随时切换排盘；全部数据只保存在本机。")
                }

                Section {
                    TextField("称呼（选填）", text: $state.input.displayName)
                        .textInputAutocapitalization(.never)
                    Picker("性别", selection: $state.input.gender) {
                        Text("请选择").tag(Gender?.none)
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(Gender?.some(gender))
                        }
                    }
                    DatePicker("出生日期", selection: $state.input.birthDate, in: supportedDates, displayedComponents: .date)
                    DatePicker("出生时间", selection: $state.input.birthDate, displayedComponents: .hourAndMinute)
                } header: {
                    Text("基本资料")
                } footer: {
                    Text("性别用于传统大限顺逆规则；称呼仅显示在本机，可留空。")
                }

                Section {
                    TextField("出生城市或地区", text: $state.input.birthplace)
                    Picker("出生地时区", selection: $state.input.timeZoneIdentifier) {
                        ForEach(zones, id: \.self) { zone in
                            Text(timeZoneLabel(zone)).tag(zone)
                        }
                    }
                    Menu {
                        ForEach(places) { place in
                            Button(place.name) {
                                state.input.birthplace = place.name
                                state.input.longitudeText = place.longitude
                                state.input.timeZoneIdentifier = place.timeZone
                            }
                        }
                    } label: {
                        Label("填入常用城市与经度", systemImage: "location")
                    }
                } header: {
                    Text("出生地")
                } footer: {
                    Text("出生地与时区参与历法换算；应用不会访问定位，也不会上传资料。")
                }

                Section {
                    Toggle("23:00 后按次日子时", isOn: $state.input.lateZiNextDay)
                    Toggle("使用真太阳时校正", isOn: $state.input.useTrueSolarTime.animation())
                    if state.input.useTrueSolarTime {
                        TextField("出生地经度，如 121.4737", text: $state.input.longitudeText)
                            .keyboardType(.numbersAndPunctuation)
                        Text("东经为正、西经为负。校正包含经度差与均时差，可能影响时辰甚至日期。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("时辰规则")
                } footer: {
                    Text("紫微流派对晚子时有不同处理，默认 23:00 起归入次日；可按所用流派切换。")
                }

                Section {
                    Toggle("夏令时校正（1986–1991）", isOn: $state.input.adjustForDaylightSaving)
                    Picker("闰月口径", selection: $state.input.leapMonthMode) {
                        ForEach(LeapMonthMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    Text(state.input.leapMonthMode.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("历法设置")
                } footer: {
                    Text("1986–1991 年国内实行过夏令时，此期间出生建议保持开启；闰月口径影响月建、命身宫与安星，切换后需重新排盘。")
                }

                Section {
                    Toggle("专业版已解锁", isOn: Binding(
                        get: { state.isProUnlocked },
                        set: { state.setProUnlocked($0) }
                    ))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("本期开放")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.cinnabar)
                        Text("本命 / 大限 / 流年 / 流月 / 流日 / 流时六层切换 · 星曜七档亮度 · 三方四正高亮 · 宫位四段式解读 · 十四维命理解读 · 经典格局 · 四化路径 · 六维雷达图 · 飞星自化 · 长生十二神 · 小限 · 古籍断语摘编 · 全盘报告导出")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                        Text("后续版本")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.gold)
                            .padding(.top, 2)
                        Text("多档案管理 · 长图导出")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("专业版")
                } footer: {
                    Text("自签分发没有 App Store 内购通道，专业版状态仅保存在本机，用于内容分层展示，不涉及任何支付。")
                }

                if !state.issues.isEmpty {
                    Section("请检查以下内容") {
                        ForEach(state.issues.indices, id: \.self) { index in
                            Label(state.issues[index].message, systemImage: "exclamationmark.circle.fill")
                                .foregroundStyle(Theme.cinnabar)
                                .font(.subheadline)
                        }
                    }
                }

                Section {
                    Button {
                        hideKeyboard()
                        state.generateChart()
                    } label: {
                        Text(state.chart == nil ? "生成命盘与今日评分" : "重新排盘并更新今日评分")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))

                    if state.chart != nil {
                        Button("清除全部档案与本地资料", role: .destructive) {
                            showClearConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                } footer: {
                    CulturalDisclaimer()
                        .listRowInsets(EdgeInsets())
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.paper)
            .navigationTitle("出生资料")
            .navigationBarTitleDisplayMode(.large)
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .confirmationDialog("确定清除本机保存的全部档案与命盘吗？此操作不可撤销。", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("清除资料", role: .destructive) { state.clearLocalData() }
                Button("取消", role: .cancel) {}
            }
            .confirmationDialog("删除当前档案后将切换到其他档案，此操作不可撤销。", isPresented: $showDeleteProfileConfirmation, titleVisibility: .visible) {
                Button("删除档案", role: .destructive) { state.deleteCurrentProfile() }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private func timeZoneLabel(_ identifier: String) -> String {
        guard let zone = TimeZone(identifier: identifier) else { return identifier }
        let hours = Double(zone.secondsFromGMT()) / 3600
        return "\(identifier.replacingOccurrences(of: "_", with: " "))（UTC\(hours >= 0 ? "+" : "")\(String(format: "%.1f", hours))）"
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
