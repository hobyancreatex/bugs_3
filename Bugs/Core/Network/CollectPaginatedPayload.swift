//
//  CollectPaginatedPayload.swift
//  Bugs
//

import Foundation

enum CollectPaginatedPayloadError: Error {
    case invalidJSON
    case missingResults
}

/// Парсинг страницы списка в стиле DRF: `results` + `next` внутри `insects_payload` (или в корне).
enum CollectPaginatedPayload {
    static func parseInsectsListPage(data: Data) throws -> (rows: [[String: Any]], nextURL: URL?) {
        let obj = try JSONSerialization.jsonObject(with: data)
        guard let root = obj as? [String: Any] else {
            throw CollectPaginatedPayloadError.invalidJSON
        }
        let container: [String: Any]
        if let payload = root["insects_payload"] as? [String: Any] {
            container = payload
        } else {
            container = root
        }
        guard let results = container["results"] as? [[String: Any]] else {
            throw CollectPaginatedPayloadError.missingResults
        }
        let nextURL = resolveNextURL(container["next"])
        return (results, nextURL)
    }

    private static func resolveNextURL(_ value: Any?) -> URL? {
        if value is NSNull || value == nil { return nil }
        guard let s = value as? String else { return nil }
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let absolute = URL(string: trimmed), absolute.scheme == "http" || absolute.scheme == "https" {
            return absolute
        }
        let base = APIConfiguration.collectBaseURL
        return URL(string: trimmed, relativeTo: base)?.absoluteURL
    }
}
