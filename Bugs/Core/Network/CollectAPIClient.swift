//
//  CollectAPIClient.swift
//  Bugs
//

import Foundation

/// Авторизованные запросы к Collect API (GET и далее другие методы).
final class CollectAPIClient {
    static let shared = CollectAPIClient()

    private let session: URLSession

    private init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    func get(path: String) async throws -> Data {
        let base = APIConfiguration.collectBaseURL
        guard let url = URL(string: path, relativeTo: base)?.absoluteURL else {
            throw CollectAPIError.invalidURL
        }
        return try await get(url: url)
    }

    /// Полный URL (например из поля `next` пагинации).
    func get(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = CollectAPIAuthState.token {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }

        CollectAPILogger.logRequest(
            method: "GET",
            url: url,
            headers: CollectAPILogger.redactedHTTPHeaders(request.allHTTPHeaderFields),
            body: nil
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw error
        }

        let http = response as? HTTPURLResponse
        let status = http?.statusCode

        guard let status, (200 ..< 300).contains(status) else {
            throw CollectAPIError.badStatus(status ?? -1, data.isEmpty ? nil : data)
        }
        return data
    }
}
