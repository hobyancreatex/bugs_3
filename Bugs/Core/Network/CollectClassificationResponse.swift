//
//  CollectClassificationResponse.swift
//  Bugs
//

import Foundation

// MARK: - API JSON (POST /api/classification/)

struct CollectClassificationAPIResponse: Decodable {
    let traceId: String?
    let insectsPayload: CollectClassificationInsectsPayload?
    let queryStatus: String?
    let serverTime: Int64?
    let insectApiVersion: String?
    let clientAuthenticated: Bool?
    let requestOperation: String?
    let requestEndpoint: String?
    let responseCode: Int?
}

struct CollectClassificationInsectsPayload: Decodable {
    let id: Int?
    let image: String?
    let completed: Bool?
    let createdAt: String?
    let results: [CollectClassificationResultItem]?
}

struct CollectClassificationResultItem: Decodable {
    let id: Int?
    let name: String?
    let reference: CollectClassificationInsectReference?
    let chance: Double?
    let isFavorite: Bool?
}

struct CollectClassificationInsectReference: Decodable {
    let id: Int
    let image: String?
    let name: String?
    let photos: [CollectClassificationPhotoItem]?
}

struct CollectClassificationPhotoItem: Decodable {
    let id: Int?
    let image: String?
    let reference: Int?
}

// MARK: - UI model

/// Кандидат распознавания для сетки и пейджера деталок.
struct RecognitionClassificationCandidate: Equatable, Sendable {
    let insectId: String
    let displayName: String
    let heroImageURL: URL?
    let thumbnailURL: URL?
    let confidence: Double?
    /// Заглушка: превью из ассета, если нет URL.
    let thumbnailAssetName: String?

    nonisolated init(
        insectId: String,
        displayName: String,
        heroImageURL: URL?,
        thumbnailURL: URL?,
        confidence: Double?,
        thumbnailAssetName: String? = nil
    ) {
        self.insectId = insectId
        self.displayName = displayName
        self.heroImageURL = heroImageURL
        self.thumbnailURL = thumbnailURL
        self.confidence = confidence
        self.thumbnailAssetName = thumbnailAssetName
    }

    static func fromLegacyAssetNames(_ names: [String]) -> [RecognitionClassificationCandidate] {
        names.map {
            RecognitionClassificationCandidate(
                insectId: "",
                displayName: "",
                heroImageURL: nil,
                thumbnailURL: nil,
                confidence: nil,
                thumbnailAssetName: $0
            )
        }
    }
}

enum CollectClassificationParsing {
    static func decode(_ data: Data) throws -> CollectClassificationAPIResponse {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return try dec.decode(CollectClassificationAPIResponse.self, from: data)
    }

    /// Кандидаты по убыванию `chance`; без `reference` строка отбрасывается.
    static func candidates(from response: CollectClassificationAPIResponse) -> [RecognitionClassificationCandidate] {
        guard let results = response.insectsPayload?.results else { return [] }
        let sorted = results.sorted { ($0.chance ?? 0) > ($1.chance ?? 0) }
        return sorted.compactMap(candidate(from:))
    }

    private nonisolated static func candidate(from item: CollectClassificationResultItem) -> RecognitionClassificationCandidate? {
        guard let ref = item.reference else { return nil }
        let id = String(ref.id)
        let title = item.name ?? ref.name ?? ""
        let hero = ref.image.flatMap { URL(string: $0) }
        let fromPhotos = ref.photos?.compactMap { $0.image }.compactMap { URL(string: $0) }.first
        let thumb = hero ?? fromPhotos
        return RecognitionClassificationCandidate(
            insectId: id,
            displayName: title,
            heroImageURL: hero,
            thumbnailURL: thumb,
            confidence: item.chance,
            thumbnailAssetName: nil
        )
    }
}
