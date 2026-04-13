//
//  CollectAchievementsModels.swift
//  Bugs
//

import Foundation

// MARK: - GET classification/achievements/ (обёртка API v3)

struct CollectAchievementsAPIEnvelope: Codable {
    let insectsPayload: CollectAchievementsPagedPayload

    enum CodingKeys: String, CodingKey {
        case insectsPayload = "insects_payload"
    }
}

struct CollectAchievementsPagedPayload: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [CollectAchievementItemDTO]
}

struct CollectAchievementItemDTO: Codable {
    let currentCount: Int
    let helpText: String
    let image: String
    let imageInactive: String
    let maxCount: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case currentCount = "current_count"
        case helpText = "help_text"
        case image
        case imageInactive = "image_inactive"
        case maxCount = "max_count"
        case name
    }
}

enum CollectAchievementsParser {

    static func results(from data: Data) throws -> [CollectAchievementItemDTO] {
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(CollectAchievementsAPIEnvelope.self, from: data) {
            return envelope.insectsPayload.results
        }
        if let payload = try? decoder.decode(CollectAchievementsPagedPayload.self, from: data) {
            return payload.results
        }
        throw CollectAchievementsParseError.unexpectedShape
    }
}

enum CollectAchievementsParseError: Error {
    case unexpectedShape
}
