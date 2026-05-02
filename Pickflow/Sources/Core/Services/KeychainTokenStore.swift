import Foundation
import Security

enum TokenStoreError: LocalizedError {
    case unexpectedStatus(OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case let .unexpectedStatus(status):
            "토큰 저장소 처리 중 오류가 발생했어요. (\(status))"
        case .invalidData:
            "저장된 토큰 데이터가 올바르지 않아요."
        }
    }
}

final class KeychainTokenStore: TokenStoreProtocol, @unchecked Sendable {
    private let service = "com.pickflow.auth"
    private let account = "auth-token"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save(_ token: AuthToken) throws {
        let data = try encoder.encode(token)

        let query = baseQuery.merging([
            kSecValueData as String: data,
        ]) { _, new in new }

        let status = SecItemCopyMatching(baseQuery as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            let attributes = [kSecValueData as String: data] as CFDictionary
            let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes)
            guard updateStatus == errSecSuccess else {
                throw TokenStoreError.unexpectedStatus(updateStatus)
            }
        case errSecItemNotFound:
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw TokenStoreError.unexpectedStatus(addStatus)
            }
        default:
            throw TokenStoreError.unexpectedStatus(status)
        }
    }

    func load() throws -> AuthToken? {
        let query = baseQuery.merging([
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]) { _, new in new }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                throw TokenStoreError.invalidData
            }
            return try decoder.decode(AuthToken.self, from: data)
        case errSecItemNotFound:
            return nil
        default:
            throw TokenStoreError.unexpectedStatus(status)
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStoreError.unexpectedStatus(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
