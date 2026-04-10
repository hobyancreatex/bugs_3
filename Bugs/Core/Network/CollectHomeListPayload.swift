//
//  CollectHomeListPayload.swift
//  Bugs
//

import Foundation

enum CollectHomePayloadError: Error {
    case invalidJSON
    case unexpectedShape
}

/// Достаёт массив объектов из ответа Collect API (корень, `insects_payload`, вложенные списки).
enum CollectHomeListPayload {
    private static let nestedArrayKeys = [
        "categories", "items", "results", "articles", "insects", "data", "popular", "objects", "rows",
    ]

    static func objectRows(from data: Data) throws -> [[String: Any]] {
        let obj = try JSONSerialization.jsonObject(with: data)
        if let rows = obj as? [[String: Any]] { return rows }
        guard let root = obj as? [String: Any] else {
            throw CollectHomePayloadError.invalidJSON
        }
        if let rows = root["results"] as? [[String: Any]] { return rows }
        if let payload = root["insects_payload"] {
            if let rows = payload as? [[String: Any]] { return rows }
            if let dict = payload as? [String: Any] {
                for key in nestedArrayKeys {
                    if let rows = dict[key] as? [[String: Any]] { return rows }
                }
            }
        }
        throw CollectHomePayloadError.unexpectedShape
    }

    static func pickString(_ dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            guard let value = dict[key] else { continue }
            switch value {
            case let s as String where !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty:
                return s
            case let i as Int:
                return String(i)
            case let i as Int64:
                return String(i)
            case let d as Double:
                if d.rounded() == d { return String(Int(d)) }
                return String(d)
            default:
                break
            }
        }
        return nil
    }

    static func pickURL(_ dict: [String: Any], keys: [String]) -> URL? {
        guard let s = pickString(dict, keys: keys) else { return nil }
        guard let url = URL(string: s), url.scheme == "http" || url.scheme == "https" else { return nil }
        return url
    }
}

enum CollectHomeDTOMapper {
    static func category(_ dict: [String: Any]) -> Home.CategoryItemResponse? {
        guard let title = CollectHomeListPayload.pickString(dict, keys: ["name", "title", "label"]) else {
            return nil
        }
        let key = CollectHomeListPayload.pickString(dict, keys: ["slug", "key", "code"])
            ?? CollectHomeListPayload.pickString(dict, keys: ["id"])
            ?? title
        let imageURL = CollectHomeListPayload.pickURL(
            dict,
            keys: ["image", "image_url", "thumbnail_url", "icon", "cover", "thumbnail", "photo"]
        )
        return Home.CategoryItemResponse(
            displayTitle: title,
            categoryRoutingKey: key,
            imageAssetName: "home_category_thumbnail",
            imageURL: imageURL
        )
    }

    static func popularInsect(_ dict: [String: Any]) -> Home.PopularInsectItemResponse? {
        guard let title = CollectHomeListPayload.pickString(
            dict,
            keys: [
                "name", "title", "label", "common_name", "species", "species_name",
                "insect_name", "scientific_name", "latin_name",
            ]
        ) else {
            return nil
        }
        let imageURL = CollectHomeListPayload.pickURL(
            dict,
            keys: [
                "image", "image_url", "photo", "thumbnail", "thumbnail_url", "cover",
                "preview", "preview_image", "hero_image",
            ]
        )
        return Home.PopularInsectItemResponse(
            displayTitle: title,
            imageAssetName: "home_popular_insect",
            badgeAssetName: "home_popular_badge",
            imageURL: imageURL
        )
    }

    static func article(_ dict: [String: Any]) -> Home.ArticleItemResponse? {
        guard let title = CollectHomeListPayload.pickString(dict, keys: ["title", "name", "heading"]) else {
            return nil
        }
        let subtitle = CollectHomeListPayload.pickString(
            dict,
            keys: ["subtitle", "description", "excerpt", "summary", "lead"]
        ) ?? ""
        let coverURL = CollectHomeListPayload.pickURL(
            dict,
            keys: ["image", "cover", "cover_image", "thumbnail", "image_url", "preview_image", "hero_image"]
        )
        let blocks = articleBlocks(from: dict)
        let finalBlocks: [Home.ArticleDetailBlockResponse]
        if blocks.isEmpty {
            finalBlocks = [Home.ArticleDetailBlockResponse(sectionTitle: nil, body: "")]
        } else {
            finalBlocks = blocks
        }
        return Home.ArticleItemResponse(
            displayTitle: title,
            displaySubtitle: subtitle,
            imageAssetName: "home_article_cover",
            coverImageURL: coverURL,
            blocks: finalBlocks
        )
    }

    private static func articleBlocks(from dict: [String: Any]) -> [Home.ArticleDetailBlockResponse] {
        if let raw = dict["blocks"] as? [[String: Any]] {
            return raw.compactMap { block in
                let section = CollectHomeListPayload.pickString(
                    block,
                    keys: ["title", "heading", "section_title"]
                )
                let body = CollectHomeListPayload.pickString(
                    block,
                    keys: ["body", "text", "content", "html"]
                ) ?? ""
                if body.isEmpty, section == nil { return nil }
                return Home.ArticleDetailBlockResponse(sectionTitle: section, body: body)
            }
        }
        if let content = CollectHomeListPayload.pickString(dict, keys: ["content", "body", "text", "html"]) {
            return [Home.ArticleDetailBlockResponse(sectionTitle: nil, body: content)]
        }
        return []
    }
}
