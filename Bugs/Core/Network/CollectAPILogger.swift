//
//  CollectAPILogger.swift
//  Bugs
//

import Foundation

enum CollectAPILogger {
    /// Не используйте в схеме `OS_ACTIVITY_MODE=disable` — оно глушит NSLog/os_log в консоли Xcode.
    nonisolated static func log(_ message: String) {
        let line = "[BugsCollectAPI] \(message)"
        NSLog("%@", line)
        // Дубль в stdout: видно в панели Debug даже при странных настройках логов.
        fputs(line + "\n", stdout)
        fflush(stdout)
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

    // MARK: - Article detail

    nonisolated static func logArticleDetailSuccess(articleId: String, data: Data) {
        let body = responseBodyPreview(data, maxLen: 12_000)
        log("article detail RESPONSE id=\(articleId) bytes=\(data.count) body: \(body)")
    }

    nonisolated static func logArticleDetailFailure(articleId: String, error: Error) {
        log("article detail FAILED id=\(articleId) error: \(error.localizedDescription)")
    }

    nonisolated private static func responseBodyPreview(_ data: Data, maxLen: Int) -> String {
        if data.isEmpty { return "<empty>" }
        if let s = String(data: data, encoding: .utf8) {
            if s.count <= maxLen { return s }
            return String(s.prefix(maxLen)) + " …(\(s.count - maxLen) chars truncated)"
        }
        return "<\(data.count) bytes, non-UTF8>"
    }
}
