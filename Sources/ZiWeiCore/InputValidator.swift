import Foundation

public enum InputValidator {
    public static func validate(_ input: BirthInput, referenceDate: Date = Date()) throws {
        var issues: [InputIssue] = []
        if input.displayName.trimmingCharacters(in: .whitespacesAndNewlines).count > 20 {
            issues.append(InputIssue(field: "displayName", message: "称呼请控制在 20 个字符以内"))
        }
        if input.gender == nil {
            issues.append(InputIssue(field: "gender", message: "请选择性别，以确定大限顺逆"))
        }
        let birthplace = input.birthplace.trimmingCharacters(in: .whitespacesAndNewlines)
        if birthplace.isEmpty {
            issues.append(InputIssue(field: "birthplace", message: "请填写出生城市或地区"))
        } else if birthplace.count > 40 {
            issues.append(InputIssue(field: "birthplace", message: "出生地请控制在 40 个字符以内"))
        }
        guard let timeZone = TimeZone(identifier: input.timeZoneIdentifier) else {
            issues.append(InputIssue(field: "timeZone", message: "请选择有效的出生地时区"))
            throw InputValidationError(issues: issues)
        }
        let components = ChineseCalendarConverter.gregorianComponents(input.birthDate, timeZone: timeZone)
        let year = components.year ?? 0
        if !(1900...2100).contains(year) {
            issues.append(InputIssue(field: "birthDate", message: "当前支持 1900—2100 年出生的日期"))
        }
        if input.birthDate > referenceDate.addingTimeInterval(300) {
            issues.append(InputIssue(field: "birthDate", message: "出生日期和时间不能晚于现在"))
        }
        let longitude = input.longitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if input.useTrueSolarTime && longitude.isEmpty {
            issues.append(InputIssue(field: "longitude", message: "启用真太阳时时，请填写出生地经度"))
        }
        if !longitude.isEmpty {
            guard let value = Double(longitude), (-180...180).contains(value) else {
                issues.append(InputIssue(field: "longitude", message: "经度应为 -180 至 180 之间的数字，东经为正"))
                throw InputValidationError(issues: issues)
            }
        }
        if !issues.isEmpty { throw InputValidationError(issues: issues) }
    }
}
