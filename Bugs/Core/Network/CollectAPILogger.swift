//
//  CollectAPILogger.swift
//  Bugs
//

import Foundation

enum CollectAPILogger {
    static let prefix = "[BugsCollectAPI]"

    nonisolated static func log(_ message: String) {
        print("\(prefix) \(message)")
    }

    nonisolated static func logRequest(method: String, url: URL, headers: [String: String]?, body: Data?) {
        var parts = ["REQUEST \(method) \(url.absoluteString)"]
        if let headers, !headers.isEmpty {
            parts.append("headers: \(headers)")
        }
        if let body, !body.isEmpty, let s = String(data: body, encoding: .utf8) {
            parts.append("body: \(s)")
        }
        log(parts.joined(separator: " | "))
    }

    /// Только для отладки деталки жука (`GET insects/{id}/`).
    nonisolated static func logInsectDetailResponse(_ data: Data) {
        let body: String
        if let s = String(data: data, encoding: .utf8) {
            body = s
        } else {
            body = "<\(data.count) bytes, non-UTF8>"
        }
        log("insects/{id}/ RESPONSE body: \(body)")
    }

    /// Для логов: не светим токен в `Authorization`.
    nonisolated static func redactedHTTPHeaders(_ headers: [String: String]?) -> [String: String]? {
        guard var h = headers, !h.isEmpty else { return headers }
        if h["Authorization"] != nil {
            h["Authorization"] = "Token <redacted>"
        }
        return h
    }

    nonisolated static func logAuthSuccess(_ operation: String) {
        log("auth \(operation) OK")
    }

    nonisolated static func logAuthFailure(_ operation: String, error: Error) {
        log("auth \(operation) failed: \(error.localizedDescription)")
    }
}
