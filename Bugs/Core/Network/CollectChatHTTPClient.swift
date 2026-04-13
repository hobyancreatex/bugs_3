//
//  CollectChatHTTPClient.swift
//  Bugs
//

import Foundation

/// Только эндпоинты чата; логирует **тела ответов** для разбора контракта (см. `CollectAPILogger.logChatFlowHTTPResponse`).
final class CollectChatHTTPClient {
    static let shared = CollectChatHTTPClient()

    private let session: URLSession

    private init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    func get(path: String) async throws -> Data {
        try await authorizedRequest(method: "GET", path: path, jsonBody: nil)
    }

    func postJSON(path: String, body: [String: Any]) async throws -> Data {
        try await authorizedRequest(method: "POST", path: path, jsonBody: body)
    }

    private func authorizedRequest(method: String, path: String, jsonBody: [String: Any]?) async throws -> Data {
        let base = APIConfiguration.collectBaseURL
        guard let url = URL(string: path, relativeTo: base)?.absoluteURL else {
            throw CollectAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let jsonBody {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        }
        if let token = CollectAPIAuthState.token {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }

        CollectAPILogger.logRequest(
            method: method,
            url: url,
            headers: CollectAPILogger.redactedHTTPHeaders(request.allHTTPHeaderFields),
            body: request.httpBody
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            CollectAPILogger.logChatFlowTransportFailure(method: method, url: url, error: error)
            throw error
        }

        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? -1
        CollectAPILogger.logChatFlowHTTPResponse(method: method, url: url, statusCode: status, body: data)

        guard (200 ..< 300).contains(status) else {
            throw CollectAPIError.badStatus(status, data.isEmpty ? nil : data)
        }
        return data
    }
}

enum CollectChatListParser {
    /// Первый id из `GET chats/` — `insects_payload.results` (API v3) или плоские массивы.
    static func firstChatId(from data: Data) -> Int? {
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(CollectChatInsectsEnvelope<CollectChatPagedListPayload>.self, from: data) {
            return envelope.insectsPayload.results.first?.id
        }
        guard let root = try? JSONSerialization.jsonObject(with: data) else { return nil }
        if let arr = root as? [[String: Any]] {
            return arr.compactMap { $0["id"] as? Int }.first
        }
        if let dict = root as? [String: Any] {
            if let payload = dict["insects_payload"] as? [String: Any],
               let results = payload["results"] as? [[String: Any]]
            {
                return results.compactMap { $0["id"] as? Int }.first
            }
            for key in ["results", "data", "chats"] {
                if let nested = dict[key] as? [[String: Any]] {
                    return nested.compactMap { $0["id"] as? Int }.first
                }
            }
        }
        return nil
    }
}

enum CollectChatCreationParser {
    static func chatId(from data: Data) throws -> Int {
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(CollectChatInsectsEnvelope<CollectChatCreatedPayload>.self, from: data) {
            return envelope.insectsPayload.id
        }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let payload = obj["insects_payload"] as? [String: Any],
           let id = payload["id"] as? Int
        {
            return id
        }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let id = obj["id"] as? Int
        {
            return id
        }
        throw CollectChatFlowError.cannotParseChatId
    }
}

enum CollectChatFlowError: Error {
    case noAuthToken
    case cannotParseChatId
    case cannotParseChatDetail
}
