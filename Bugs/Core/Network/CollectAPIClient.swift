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
            CollectAPILogger.logHTTPTransportFailure(method: "GET", url: url, error: error)
            throw error
        }

        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? -1

        guard (200 ..< 300).contains(status) else {
            throw CollectAPIError.badStatus(status, data.isEmpty ? nil : data)
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
        try await postMultipart(
            path: "classification/",
            parts: [
                MultipartPart(name: fieldName, filename: fileName, mimeType: mimeType, data: imageJPEGData),
            ],
            partsDescription: "fields=[\(fieldName)(file \(fileName) \(imageJPEGData.count) bytes)]"
        )
    }

    /// POST `collection/` — новая коллекция по виду: `image` + `reference` (id/slug насекомого), как в legacy `createNewCollection`.
    func postCreateCollection(insectReference: String, imageJPEGData: Data) async throws -> Data {
        let refData = Data(insectReference.utf8)
        return try await postMultipart(
            path: "collection/",
            parts: [
                MultipartPart(name: "image", filename: "photo.jpg", mimeType: "image/jpeg", data: imageJPEGData),
                MultipartPart(name: "reference", filename: nil, mimeType: nil, data: refData),
            ],
            partsDescription:
                "fields=[image(photo.jpg \(imageJPEGData.count) bytes), reference(utf8 \(refData.count) bytes)]"
        )
    }

    /// DELETE `collection/{id}/` — удалить коллекцию по этому виду (все пользовательские фото).
    func deleteCollection(id: Int) async throws {
        let base = APIConfiguration.collectBaseURL
        guard let url = URL(string: "collection/\(id)/", relativeTo: base)?.absoluteURL else {
            throw CollectAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = CollectAPIAuthState.token {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }

        CollectAPILogger.logRequest(
            method: "DELETE",
            url: url,
            headers: CollectAPILogger.redactedHTTPHeaders(request.allHTTPHeaderFields),
            body: nil
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            CollectAPILogger.logHTTPTransportFailure(method: "DELETE", url: url, error: error)
            throw error
        }

        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? -1

        guard (200 ..< 300).contains(status) else {
            throw CollectAPIError.badStatus(status, data.isEmpty ? nil : data)
        }
    }

    /// DELETE `auth/terminate/` — удаление аккаунта текущего устройства.
    func terminateAccount() async throws {
        let base = APIConfiguration.collectBaseURL
        guard let url = URL(string: "auth/terminate/", relativeTo: base)?.absoluteURL else {
            throw CollectAPIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = CollectAPIAuthState.token {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200 ..< 300).contains(status) else {
            throw CollectAPIError.badStatus(status, data.isEmpty ? nil : data)
        }
    }

    /// POST `collection/upload/` — фото в уже существующую коллекцию: `image` + `item` (id коллекции), как в legacy `addToExistedCollection`.
    func postAddPhotoToCollection(collectionId: Int, imageJPEGData: Data) async throws -> Data {
        let itemData = Data("\(collectionId)".utf8)
        return try await postMultipart(
            path: "collection/upload/",
            parts: [
                MultipartPart(name: "image", filename: "photo.jpg", mimeType: "image/jpeg", data: imageJPEGData),
                MultipartPart(name: "item", filename: nil, mimeType: nil, data: itemData),
            ],
            partsDescription:
                "fields=[image(photo.jpg \(imageJPEGData.count) bytes), item(utf8 \(itemData.count) bytes) id=\(collectionId)]"
        )
    }

    // MARK: - Multipart POST

    private struct MultipartPart {
        let name: String
        let filename: String?
        let mimeType: String?
        let data: Data
    }

    private func postMultipart(path: String, parts: [MultipartPart], partsDescription: String) async throws -> Data {
        let base = APIConfiguration.collectBaseURL
        guard let url = URL(string: path, relativeTo: base)?.absoluteURL else {
            throw CollectAPIError.invalidURL
        }

        let boundary = "BugsCollect-\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let body = Self.buildMultipartBody(boundary: boundary, parts: parts)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = CollectAPIAuthState.token {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        }

        CollectAPILogger.logMultipartRequest(
            method: "POST",
            url: url,
            headers: request.allHTTPHeaderFields,
            partsDescription: partsDescription
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            CollectAPILogger.logHTTPTransportFailure(method: "POST", url: url, error: error)
            throw error
        }

        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? -1

        guard (200 ..< 300).contains(status) else {
            throw CollectAPIError.badStatus(status, data.isEmpty ? nil : data)
        }
        return data
    }

    private static func buildMultipartBody(boundary: String, parts: [MultipartPart]) -> Data {
        var d = Data()
        let crlf = Data("\r\n".utf8)
        for part in parts {
            d.append(Data("--\(boundary)\r\n".utf8))
            if let filename = part.filename {
                d.append(
                    Data(
                        "Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(filename)\"\r\n"
                            .utf8
                    )
                )
            } else {
                d.append(Data("Content-Disposition: form-data; name=\"\(part.name)\"\r\n".utf8))
            }
            if let mime = part.mimeType {
                d.append(Data("Content-Type: \(mime)\r\n".utf8))
            }
            d.append(crlf)
            d.append(part.data)
            d.append(crlf)
        }
        d.append(Data("--\(boundary)--\r\n".utf8))
        return d
    }
}
