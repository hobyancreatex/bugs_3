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

    // MARK: - Classification (multipart)

    nonisolated static func logClassificationWillSend(
        url: URL,
        fieldName: String,
        fileName: String,
        mimeType: String,
        imageByteCount: Int,
        multipartBodyByteCount: Int,
        boundary: String,
        headers: [String: String]?
    ) {
        var parts = [
            "classification REQUEST POST \(url.absoluteString)",
            "form field=\(fieldName) filename=\(fileName) mime=\(mimeType)",
            "image payload: \(imageByteCount) bytes",
            "multipart body: \(multipartBodyByteCount) bytes",
            "boundary: \(boundary)",
        ]
        if let headers, !headers.isEmpty {
            parts.append("headers: \(headers)")
        }
        log(parts.joined(separator: " | "))
    }

    nonisolated static func logClassificationResponse(status: Int, url: URL?, data: Data) {
        let body = classificationResponseBodyPreview(data)
        let u = url?.absoluteString ?? "(nil)"
        log("classification RESPONSE status=\(status) url=\(u) body: \(body)")
    }

    nonisolated static func logClassificationTransportError(_ error: Error) {
        log("classification transport error: \(error.localizedDescription)")
    }

    /// Текст ответа для лога (обрезка, чтобы не залить консоль).
    nonisolated private static func classificationResponseBodyPreview(_ data: Data) -> String {
        if data.isEmpty { return "<empty>" }
        if let s = String(data: data, encoding: .utf8) {
            let maxLen = 12_000
            if s.count <= maxLen { return s }
            return String(s.prefix(maxLen)) + " …(\(s.count - maxLen) chars truncated)"
        }
        return "<\(data.count) bytes, non-UTF8>"
    }
}
