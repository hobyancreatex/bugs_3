//
//  CollectAuthService.swift
//  Bugs
//

import Foundation

struct CollectAuthCredentialsRequest: Encodable {
    let username: String
    let password: String
}

enum CollectAuthServiceError: Error {
    case invalidURL
    case badStatus(Int, Data?)
    case noTokenInResponse
    case emptyCredentials
}

final class CollectAuthService {
    static let shared = CollectAuthService()

    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    private init(
        session: URLSession = URLSession(configuration: .ephemeral),
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = {
            let d = JSONDecoder()
            d.keyDecodingStrategy = .convertFromSnakeCase
            return d
        }()
    ) {
        self.session = session
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }

    func signUp(credentials: CollectAuthCredentialsRequest) async throws -> String {
        try await post(path: "auth/sign-up/", body: credentials)
    }

    func login(credentials: CollectAuthCredentialsRequest) async throws -> String {
        try await post(path: "auth/login/", body: credentials)
    }

    private func post(path: String, body: CollectAuthCredentialsRequest) async throws -> String {
        let base = APIConfiguration.collectBaseURL
        guard let url = URL(string: path, relativeTo: base)?.absoluteURL else {
            throw CollectAuthServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let payload = try jsonEncoder.encode(body)
        request.httpBody = payload

        CollectAPILogger.logRequest(
            method: "POST",
            url: url,
            headers: request.allHTTPHeaderFields,
            body: payload
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            CollectAPILogger.logResponse(url: url, status: nil, data: nil, error: error)
            throw error
        }

        let http = response as? HTTPURLResponse
        let status = http?.statusCode
        CollectAPILogger.logResponse(url: url, status: status, data: data, error: nil)

        guard let status, (200 ..< 300).contains(status) else {
            throw CollectAuthServiceError.badStatus(status ?? -1, data.isEmpty ? nil : data)
        }

        let decoded = try? jsonDecoder.decode(CollectAuthAPIResponse.self, from: data)
        guard let token = decoded?.authToken else {
            throw CollectAuthServiceError.noTokenInResponse
        }
        return token
    }
}
