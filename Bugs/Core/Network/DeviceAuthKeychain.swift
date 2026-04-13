//
//  DeviceAuthKeychain.swift
//  Bugs
//

import Foundation
import Security

/// Учётные данные устройства и флаг регистрации в Keychain.
enum DeviceAuthKeychain {
    private static let service: String = {
        let id = Bundle(for: KeychainBundleAnchor.self).bundleIdentifier ?? "bugs.identifier"
        return "\(id).collect.device.auth"
    }()

    private final class KeychainBundleAnchor {}

    private enum Account {
        static let registered = "device.registered"
        static let username = "device.username"
        static let password = "device.password"
        static let token = "auth.token"
        static let chatId = "collect.chat.id"
    }

    static var isDeviceRegistered: Bool {
        (try? string(for: Account.registered)) == "1"
    }

    static func setDeviceRegistered(_ value: Bool) throws {
        try setString(value ? "1" : "0", for: Account.registered)
    }

    static var storedUsername: String? {
        try? string(for: Account.username)
    }

    static var storedPassword: String? {
        try? string(for: Account.password)
    }

    static var storedToken: String? {
        try? string(for: Account.token)
    }

    static func saveCredentials(username: String, password: String) throws {
        try setString(username, for: Account.username)
        try setString(password, for: Account.password)
    }

    static func saveToken(_ token: String) throws {
        try setString(token, for: Account.token)
    }

    /// Один чат на пользователя: id с бэкенда после `POST chats/` или из списка `GET chats/`.
    static var storedChatId: String? {
        try? string(for: Account.chatId)
    }

    static func saveChatId(_ id: Int) throws {
        try setString(String(id), for: Account.chatId)
    }

    static func clearChatId() throws {
        try deleteItem(account: Account.chatId)
    }

    // MARK: - Low level

    private static func string(for account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
        guard let data = result as? Data, let s = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return s
    }

    private static func setString(_ value: String, for account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item.merge(attributes) { _, new in new }
            status = SecItemAdd(item as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    private static func deleteItem(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
    }

    enum KeychainError: Error {
        case itemNotFound
        case invalidData
        case unhandledStatus(OSStatus)
    }
}
