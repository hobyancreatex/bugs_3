//
//  CollectCollectionAPI.swift
//  Bugs
//

import Foundation

/// Разбор ответов POST `/collection/` и `/collection/upload/` (id новой или существующей записи коллекции).
enum CollectCollectionResponseParser {

    static func collectionId(from data: Data) -> Int? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) else { return nil }
        if let id = intValue(extractId(from: obj)) {
            return id
        }
        return nil
    }

    private static func extractId(from obj: Any) -> Any? {
        if let dict = obj as? [String: Any] {
            // Ответ Collect API: `insects_payload.id` — id записи коллекции (см. POST /collection/).
            if let payload = dict["insects_payload"] as? [String: Any], let id = payload["id"] {
                return id
            }
            if let uc = dict["user_collection"] as? [String: Any], let id = uc["id"] {
                return id
            }
            if let id = dict["id"] { return id }
        }
        return nil
    }

    private static func intValue(_ any: Any?) -> Int? {
        switch any {
        case let i as Int:
            return i
        case let i as Int64:
            return Int(i)
        case let n as NSNumber:
            return n.intValue
        case let s as String:
            return Int(s)
        default:
            return nil
        }
    }
}

// MARK: - GET collection/

/// Элемент списка `GET collection/` для вкладки «Профиль».
struct CollectProfileCollectionRow {
    /// Значение поля `reference` — id/slug вида для `GET insects/{id}/`.
    let insectReference: String
    let title: String
    let subtitle: String
    let coverImageURL: URL?
}

enum CollectCollectionListParser {

    static func profileRows(from data: Data) throws -> [CollectProfileCollectionRow] {
        if let raw = try? CollectHomeListPayload.objectRows(from: data) {
            return raw.compactMap { mapListItem($0) }
        }
        let obj = try JSONSerialization.jsonObject(with: data)
        guard let root = obj as? [String: Any] else { return [] }
        if let payload = root["insects_payload"] as? [[String: Any]] {
            return payload.compactMap { mapListItem($0) }
        }
        if let payload = root["insects_payload"] as? [String: Any], let row = mapListItem(payload) {
            return [row]
        }
        if let row = mapListItem(root) {
            return [row]
        }
        return []
    }

    private static func mapListItem(_ dict: [String: Any]) -> CollectProfileCollectionRow? {
        guard intValue(dict["id"]) != nil else { return nil }

        // Collect API: `reference` — объект вида (id, name, family, order, class_name, image).
        if let refDict = dict["reference"] as? [String: Any] {
            guard let refId = referenceString(refDict["id"]) else { return nil }
            let title =
                CollectHomeListPayload.pickString(refDict, keys: ["name", "common_name", "title", "label"])
                ?? refId
            let family = CollectHomeListPayload.pickString(refDict, keys: ["family", "family_name"])
            let order = CollectHomeListPayload.pickString(refDict, keys: ["order", "order_name"])
            let className = CollectHomeListPayload.pickString(refDict, keys: ["class_name", "class"])
            let subtitle = [family, order, className]
                .compactMap { $0 }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")

            let userPhoto = firstUserPhotoURL(from: dict["user_photos"])
            let catalogImage = CollectHomeListPayload.pickURL(
                refDict,
                keys: ["image", "image_url", "thumbnail", "thumbnail_url", "photo", "cover"]
            )
            let coverURL = userPhoto ?? catalogImage

            return CollectProfileCollectionRow(
                insectReference: refId,
                title: title,
                subtitle: subtitle,
                coverImageURL: coverURL
            )
        }

        // Legacy: `reference` — число или строка (id/slug вида).
        guard let ref = referenceString(dict["reference"]) else { return nil }

        let nestedInsect =
            dict["insect"] as? [String: Any]
            ?? dict["reference_insect"] as? [String: Any]
            ?? dict["insects_payload"] as? [String: Any]

        let title =
            CollectHomeListPayload.pickString(dict, keys: ["common_name", "name", "title", "label"])
            ?? nestedInsect.flatMap {
                CollectHomeListPayload.pickString($0, keys: ["common_name", "name", "title", "label"])
            }
            ?? ref

        let subtitle =
            CollectHomeListPayload.pickString(dict, keys: ["scientific_name", "latin_name", "subtitle", "species_name"])
            ?? nestedInsect.flatMap {
                CollectHomeListPayload.pickString($0, keys: ["scientific_name", "latin_name", "species_name", "genus"])
            }
            ?? ""

        let coverURL = firstUserPhotoURL(from: dict["user_photos"])

        return CollectProfileCollectionRow(
            insectReference: ref,
            title: title,
            subtitle: subtitle,
            coverImageURL: coverURL
        )
    }

    private static func firstUserPhotoURL(from raw: Any?) -> URL? {
        guard let arr = raw as? [Any] else { return nil }
        for item in arr {
            guard let row = item as? [String: Any] else { continue }
            if let u = CollectHomeListPayload.pickURL(
                row,
                keys: ["image", "url", "image_url", "src", "thumbnail", "thumbnail_url", "photo"]
            ) {
                return u
            }
        }
        return nil
    }

    private static func referenceString(_ value: Any?) -> String? {
        switch value {
        case let s as String:
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        case let i as Int:
            return String(i)
        case let i as Int64:
            return String(i)
        case let n as NSNumber:
            return n.stringValue
        default:
            return nil
        }
    }

    private static func intValue(_ any: Any?) -> Int? {
        switch any {
        case let i as Int:
            return i
        case let i as Int64:
            return Int(i)
        case let n as NSNumber:
            return n.intValue
        case let s as String:
            return Int(s)
        default:
            return nil
        }
    }
}
