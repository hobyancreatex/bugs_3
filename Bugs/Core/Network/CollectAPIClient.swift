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

    /// POST `classification/` — одно фото жука в `multipart/form-data` (поле по умолчанию `image`).
    func postClassification(
        imageJPEGData: Data,
        fieldName: String = "image",
        fileName: String = "insect.jpg",
        mimeType: String = "image/jpeg"
    ) async throws -> Data {
        let base = APIConfiguration.collectBaseURL
        guard let url = URL(string: "classification/", relativeTo: base)?.absoluteURL else {
            throw CollectAPIError.invalidURL
        }

        let boundary = "BugsCollect-\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let body = Self.buildMultipartBody(
            boundary: boundary,
            fieldName: fieldName,
            fileName: fileName,
            mimeType: mimeType,
            fileData: imageJPEGData
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = CollectAPIAuthState.token {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }

        CollectAPILogger.logClassificationWillSend(
            url: url,
            fieldName: fieldName,
            fileName: fileName,
            mimeType: mimeType,
            imageByteCount: imageJPEGData.count,
            multipartBodyByteCount: body.count,
            boundary: boundary,
            headers: CollectAPILogger.redactedHTTPHeaders(request.allHTTPHeaderFields)
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            CollectAPILogger.logClassificationTransportError(error)
            throw error
        }

        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? -1
        CollectAPILogger.logClassificationResponse(status: status, url: response.url, data: data)

        guard let code = http?.statusCode, (200 ..< 300).contains(code) else {
            throw CollectAPIError.badStatus(status, data.isEmpty ? nil : data)
        }
        return data
    }

    private static func buildMultipartBody(
        boundary: String,
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var d = Data()
        let crlf = Data("\r\n".utf8)
        d.append(Data("--\(boundary)\r\n".utf8))
        d.append(
            Data(
                "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
                    .utf8
            )
        )
        d.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        d.append(fileData)
        d.append(crlf)
        d.append(Data("--\(boundary)--\r\n".utf8))
        return d
    }
}
