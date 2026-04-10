//
//  CollectAPIAuthState.swift
//  Bugs
//

import Foundation

/// Текущий токен для последующих запросов к Collect API (обновляется после bootstrap).
enum CollectAPIAuthState {
    private static let lock = NSLock()
    private static var _token: String?

    nonisolated static var token: String? {
        lock.lock()
        defer { lock.unlock() }
        return _token ?? DeviceAuthKeychain.storedToken
    }

    nonisolated static func setToken(_ token: String?) {
        lock.lock()
        _token = token
        lock.unlock()
    }
}
