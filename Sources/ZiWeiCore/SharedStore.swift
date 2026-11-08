import Foundation
#if canImport(Security)
import Security
#endif

/// App 与小组件之间共享「当前档案」的小仓库。
///
/// 为什么不用 App Group：App Groups 属于需要付费开发者账号的能力，
/// 免费个人团队声明后会让真机签名直接失败。而 keychain-access-groups
/// 在免费证书里是有的（`TEAMID.*` 通配），所以用 Keychain 做跨进程共享。
/// 读不到时返回 nil，调用方降级处理，不会抛错。
public enum SharedStore {
    private static let service = "com.ziweidaily.shared"
    private static let account = "current-profile"

    /// 共享载荷：当前档案的输入 + 称呼 + 写入时间。
    public struct Payload: Codable, Equatable, Sendable {
        public var name: String
        public var input: BirthInput
        public var updatedAt: Date

        public init(name: String, input: BirthInput, updatedAt: Date = Date()) {
            self.name = name
            self.input = input
            self.updatedAt = updatedAt
        }
    }

    /// 与 entitlements 里声明的一致：`$(AppIdentifierPrefix)com.ziweidaily.shared`
    /// iOS 上没有公开 API 能读出自己的 entitlements（SecTask 只在 macOS 有），
    /// 所以这里显式写死 team 前缀；换了开发者账号需要同步改这一处。
    private static let sharedGroup = "5Y7JPFB56Q.com.ziweidaily.shared"

    private static func baseQuery(group: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let group {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

    public static func save(_ payload: Payload) {
        #if canImport(Security)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return }

        // 先清掉两个分组里的旧数据，再写共享分组
        for group in [sharedGroup, nil] as [String?] {
            SecItemDelete(baseQuery(group: group) as CFDictionary)
        }
        var query = baseQuery(group: sharedGroup)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(query as CFDictionary, nil)
        #if DEBUG
        print("[SharedStore] add(group=\(sharedGroup)) status=\(status)")
        #endif
        if status != errSecSuccess {
            // 共享分组不可用时退回默认分组：App 自己还能读，组件读不到就走引导
            var fallback = baseQuery(group: nil)
            fallback[kSecValueData as String] = data
            fallback[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(fallback as CFDictionary, nil)
        }
        #endif
    }

    public static func load() -> Payload? {
        #if canImport(Security)
        for group in [sharedGroup, nil] as [String?] {
            var query = baseQuery(group: group)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            var item: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
                  let data = item as? Data else { continue }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let payload = try? decoder.decode(Payload.self, from: data) {
                return payload
            }
        }
        return nil
        #else
        return nil
        #endif
    }

    public static func clear() {
        #if canImport(Security)
        for group in [sharedGroup, nil] as [String?] {
            SecItemDelete(baseQuery(group: group) as CFDictionary)
        }
        #endif
    }
}
