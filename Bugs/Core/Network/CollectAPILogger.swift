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

    nonisolated static func logHTTPResponse(method: String, url: URL, statusCode: Int, body: Data, maxBodyLen: Int = 12_000) {
        let preview = responseBodyPreview(body, maxLen: maxBodyLen)
        log("RESPONSE \(method) \(url.absoluteString) status=\(statusCode) bytes=\(body.count) body: \(preview)")
    }

    nonisolated static func logHTTPTransportFailure(method: String, url: URL, error: Error) {
        log("RESPONSE \(method) \(url.absoluteString) transport error: \(error.localizedDescription)")
    }

    /// Ответ auth JSON: значения токенов в логе заменены.
    nonisolated static func logAuthHTTPResponse(url: URL, statusCode: Int, body: Data) {
        let preview = redactTokensInJSONForLog(body, maxLen: 2_000)
        log("RESPONSE POST \(url.absoluteString) status=\(statusCode) bytes=\(body.count) body: \(preview)")
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

    nonisolated private static func responseBodyPreview(_ data: Data, maxLen: Int) -> String {
        if data.isEmpty { return "<empty>" }
        if let s = String(data: data, encoding: .utf8) {
            if s.count <= maxLen { return s }
            return String(s.prefix(maxLen)) + " …(\(s.count - maxLen) chars truncated)"
        }
        return "<\(data.count) bytes, non-UTF8>"
    }

    nonisolated private static func redactTokensInJSONForLog(_ data: Data, maxLen: Int) -> String {
        guard let root = try? JSONSerialization.jsonObject(with: data) else {
            return responseBodyPreview(data, maxLen: maxLen)
        }
        let redacted = redactSensitiveJSONValues(root)
        guard let out = try? JSONSerialization.data(withJSONObject: redacted, options: [.sortedKeys]) else {
            return responseBodyPreview(data, maxLen: maxLen)
        }
        return responseBodyPreview(out, maxLen: maxLen)
    }

    private nonisolated static func redactSensitiveJSONValues(_ value: Any) -> Any {
        let tokenKeys: Set<String> = ["token", "auth_token", "key", "access", "refresh"]
        if var dict = value as? [String: Any] {
            var out: [String: Any] = [:]
            for (k, v) in dict {
                if tokenKeys.contains(k) {
                    out[k] = "<redacted>"
                } else {
                    out[k] = redactSensitiveJSONValues(v)
                }
            }
            return out
        }
        if let arr = value as? [Any] {
            return arr.map { redactSensitiveJSONValues($0) }
        }
        return value
    }
}
