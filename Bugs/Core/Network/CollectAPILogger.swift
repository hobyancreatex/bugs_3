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

    /// Лог POST с multipart без вывода бинарника: только имена полей и размер файла.
    nonisolated static func logMultipartRequest(method: String, url: URL, headers: [String: String]?, partsDescription: String) {
        var parts = ["REQUEST \(method) \(url.absoluteString)"]
        if let headers, !headers.isEmpty {
            parts.append("headers: \(redactedHTTPHeaders(headers) ?? [:])")
        }
        parts.append("multipart: \(partsDescription)")
        log(parts.joined(separator: " | "))
    }

    nonisolated static func logHTTPTransportFailure(method: String, url: URL, error: Error) {
        log("RESPONSE \(method) \(url.absoluteString) transport error: \(error.localizedDescription)")
    }

    // MARK: - Только флоу чата (HTTP + WS), для разбора контракта

    nonisolated static func logChatFlowHTTPResponse(
        method: String,
        url: URL,
        statusCode: Int,
        body: Data,
        maxBodyLen: Int = 24_000
    ) {
        let preview = chatFlowBodyPreview(body, maxLen: maxBodyLen)
        log("[CHAT_FLOW] RESPONSE \(method) \(url.absoluteString) status=\(statusCode) bytes=\(body.count) body: \(preview)")
    }

    nonisolated static func logChatFlowWebSocketInbound(_ text: String, maxLen: Int = 24_000) {
        if text.count <= maxLen {
            log("[CHAT_FLOW] WS IN: \(text)")
        } else {
            log("[CHAT_FLOW] WS IN: \(String(text.prefix(maxLen))) …(\(text.count - maxLen) chars truncated)")
        }
    }

    nonisolated static func logChatFlowTransportFailure(method: String, url: URL, error: Error) {
        log("[CHAT_FLOW] transport \(method) \(url.absoluteString): \(error.localizedDescription)")
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

    nonisolated private static func chatFlowBodyPreview(_ data: Data, maxLen: Int) -> String {
        if data.isEmpty { return "<empty>" }
        if let s = String(data: data, encoding: .utf8) {
            if s.count <= maxLen { return s }
            return String(s.prefix(maxLen)) + " …(\(s.count - maxLen) chars truncated)"
        }
        return "<\(data.count) bytes, non-UTF8>"
    }
}
