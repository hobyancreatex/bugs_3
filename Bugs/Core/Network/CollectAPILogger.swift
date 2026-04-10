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

    nonisolated static func logResponse(url: URL?, status: Int?, data: Data?, error: Error?) {
        var parts: [String] = []
        if let url { parts.append("url: \(url.absoluteString)") }
        if let status { parts.append("status: \(status)") }
        if let error { parts.append("error: \(error.localizedDescription)") }
        if let data, !data.isEmpty {
            if let s = String(data: data, encoding: .utf8) {
                parts.append("body: \(s)")
            } else {
                parts.append("body: <\(data.count) bytes, non-UTF8>")
            }
        }
        log("RESPONSE " + parts.joined(separator: " | "))
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
