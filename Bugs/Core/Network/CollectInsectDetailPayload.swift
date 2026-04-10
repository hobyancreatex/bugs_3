//
//  CollectInsectDetailPayload.swift
//  Bugs
//

import Foundation

enum CollectInsectDetailPayloadError: Error {
    case invalidJSON
}

/// Разбор тела `GET insects/{id}/` (корень или `insects_payload`).
enum CollectInsectDetailPayload {
    static func rootObject(from data: Data) throws -> [String: Any] {
        let obj = try JSONSerialization.jsonObject(with: data)
        guard let root = obj as? [String: Any] else {
            throw CollectInsectDetailPayloadError.invalidJSON
        }
        if let nested = root["insects_payload"] as? [String: Any] {
            return nested
        }
        return root
    }
}

enum CollectInsectDetailMapper {
    struct Mapped {
        let title: String
        let scientificLine: String?
        let description: String
        let heroImageURL: URL?
        let galleryImageURLs: [URL]
        let characteristics: [(String, String)]
        let classification: [(String, String)]
        let biteDescription: String?
        let bitePhotoURLs: [URL]
        let isPoisonous: Bool
        let widespread: Bool?
    }

    static func map(_ dict: [String: Any]) -> Mapped? {
        guard let title = CollectHomeListPayload.pickString(
            dict,
            keys: ["common_name", "name", "title", "label"]
        ) else {
            return nil
        }

        let scientificLine = resolveScientificLine(dict)
        let description = CollectHomeListPayload.pickString(
            dict,
            keys: ["description", "short_description", "summary", "content", "body", "text"]
        ) ?? ""

        let bannerURL = CollectHomeListPayload.pickURL(
            dict,
            keys: [
                "image", "image_url", "photo", "thumbnail", "thumbnail_url", "cover",
                "preview", "preview_image", "hero_image", "main_image",
            ]
        )
        let orderedPhotos = orderedPhotoURLs(from: dict)
        let (hero, galleryStrip) = resolveHeroAndGallery(bannerURL: bannerURL, photoURLs: orderedPhotos)

        let fromArray = parseLabeledRows(
            dict["characteristics"],
            titleKeys: ["title", "name", "label"],
            valueKeys: ["value", "text", "description"]
        )
        let flat = flatCharacteristics(from: dict)
        let characteristics = flat.isEmpty && !fromArray.isEmpty ? fromArray : (flat + fromArray)

        let biteDescription = CollectHomeListPayload.pickString(
            dict,
            keys: ["bite_description", "bites_description", "bite_info", "bite_text"]
        )
        let bitePhotoURLs = bitePhotoURLs(from: dict)
        let isPoisonous = dict["is_poisonous"] as? Bool ?? false
        let widespread = dict["widespread"] as? Bool

        return Mapped(
            title: title,
            scientificLine: scientificLine,
            description: description,
            heroImageURL: hero,
            galleryImageURLs: galleryStrip,
            characteristics: characteristics,
            classification: classificationRows(from: dict),
            biteDescription: biteDescription,
            bitePhotoURLs: bitePhotoURLs,
            isPoisonous: isPoisonous,
            widespread: widespread
        )
    }

    private static func bitePhotoURLs(from dict: [String: Any]) -> [URL] {
        guard let arr = dict["bite_photos"] as? [Any] else { return [] }
        var out: [URL] = []
        var seen = Set<String>()
        for item in arr {
            if let s = item as? String, let u = URL(string: s), u.scheme == "http" || u.scheme == "https" {
                let key = u.absoluteString
                guard seen.insert(key).inserted else { continue }
                out.append(u)
                continue
            }
            guard let row = item as? [String: Any] else { continue }
            guard let u = CollectHomeListPayload.pickURL(row, keys: ["image", "url", "image_url", "src", "thumbnail", "thumbnail_url", "photo"]) else {
                continue
            }
            let key = u.absoluteString
            guard seen.insert(key).inserted else { continue }
            out.append(u)
        }
        return out
    }

    /// Порядок как в `photos[]`; часто первый кадр лучше по качеству, чем поле `image`.
    private static func orderedPhotoURLs(from dict: [String: Any]) -> [URL] {
        guard let arr = dict["photos"] as? [Any] else { return [] }
        var out: [URL] = []
        var seen = Set<String>()
        for item in arr {
            guard let row = item as? [String: Any] else { continue }
            guard let u = CollectHomeListPayload.pickURL(row, keys: ["image", "url", "image_url", "src", "thumbnail", "thumbnail_url", "photo"]) else {
                continue
            }
            let s = u.absoluteString
            guard seen.insert(s).inserted else { continue }
            out.append(u)
        }
        return out
    }

    private static func resolveHeroAndGallery(bannerURL: URL?, photoURLs: [URL]) -> (hero: URL?, gallery: [URL]) {
        if let first = photoURLs.first {
            var gallery = Array(photoURLs.dropFirst())
            if let banner = bannerURL {
                let bannerStr = banner.absoluteString
                let inStrip = gallery.contains { $0.absoluteString == bannerStr }
                let isHero = first.absoluteString == bannerStr
                if !isHero && !inStrip {
                    gallery.insert(banner, at: 0)
                }
            }
            return (first, dedupePreservingOrder(gallery))
        }
        return (bannerURL, [])
    }

    private static func dedupePreservingOrder(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.filter { seen.insert($0.absoluteString).inserted }
    }

    private static func resolveScientificLine(_ dict: [String: Any]) -> String? {
        if let s = CollectHomeListPayload.pickString(dict, keys: ["scientific_name", "latin_name", "species_name"]), !s.isEmpty {
            return s
        }
        let genus = CollectHomeListPayload.pickString(dict, keys: ["genus", "genus_name"])
        let species = CollectHomeListPayload.pickString(dict, keys: ["species", "species_name"])
        if let genus, let species, !genus.isEmpty, !species.isEmpty {
            return "\(genus) \(species)"
        }
        if let genus, !genus.isEmpty {
            return genus
        }
        let commonNames = CollectHomeListPayload.pickString(dict, keys: ["common_names"])
        let title = CollectHomeListPayload.pickString(dict, keys: ["name", "common_name", "title"])
        if let commonNames, let title, commonNames != title, !commonNames.isEmpty {
            return commonNames
        }
        return commonNames.flatMap { $0.isEmpty ? nil : $0 }
    }

    private static func flatCharacteristics(from dict: [String: Any]) -> [(String, String)] {
        var rows: [(String, String)] = []
        func add(_ label: String, _ value: String?) {
            guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty else { return }
            rows.append((label, v))
        }
        add("Color", CollectHomeListPayload.pickString(dict, keys: ["color", "colour"]))

        let lenMin = pickDouble(dict["length_min"])
        let lenMax = pickDouble(dict["length_max"])
        if let mn = lenMin, let mx = lenMax {
            add("Length", String(format: "%.1f–%.1f mm", mn, mx))
        } else if let mn = lenMin {
            add("Length", String(format: "%.1f mm", mn))
        }

        if let hName = CollectHomeListPayload.pickString(dict, keys: ["habitat_name"]) {
            let hDesc = CollectHomeListPayload.pickString(dict, keys: ["habitat_description"]) ?? ""
            if hDesc.isEmpty {
                add("Habitat", hName)
            } else {
                add("Habitat", "\(hName). \(hDesc)")
            }
        }

        add("Population", CollectHomeListPayload.pickString(dict, keys: ["population"]))

        let incMin = pickDouble(dict["incubation_period_min"])
        let incMax = pickDouble(dict["incubation_period_max"])
        if let a = incMin, let b = incMax {
            add("Incubation", String(format: "%.0f–%.0f days", a, b))
        }

        add("Life forms", CollectHomeListPayload.pickString(dict, keys: ["existence_forms", "forms"]))
        add("Diet", CollectHomeListPayload.pickString(dict, keys: ["diet", "food"]))

        return rows
    }

    private static func pickDouble(_ value: Any?) -> Double? {
        switch value {
        case let d as Double:
            return d
        case let i as Int:
            return Double(i)
        case let n as NSNumber:
            return n.doubleValue
        default:
            return nil
        }
    }

    private static func parseLabeledRows(
        _ raw: Any?,
        titleKeys: [String],
        valueKeys: [String]
    ) -> [(String, String)] {
        guard let rows = raw as? [[String: Any]] else { return [] }
        return rows.compactMap { row in
            guard let t = CollectHomeListPayload.pickString(row, keys: titleKeys) else { return nil }
            let v = CollectHomeListPayload.pickString(row, keys: valueKeys) ?? ""
            if v.isEmpty { return nil }
            return (t, v)
        }
    }

    private static func classificationRows(from dict: [String: Any]) -> [(String, String)] {
        var rows: [(String, String)] = []
        func add(_ label: String, _ dict: [String: Any], keys: [String]) {
            if let v = CollectHomeListPayload.pickString(dict, keys: keys), !v.isEmpty {
                rows.append((label, v))
            }
        }
        if let tax = dict["taxonomy"] as? [String: Any] {
            add("Genus", tax, keys: ["genus", "genus_name"])
            add("Family", tax, keys: ["family", "family_name"])
            add("Order", tax, keys: ["order", "order_name"])
            add("Class", tax, keys: ["class", "class_name"])
            add("Phylum", tax, keys: ["phylum", "phylum_name"])
            add("Kingdom", tax, keys: ["kingdom", "kingdom_name"])
            add("Domain", tax, keys: ["domain", "domain_name"])
        }
        add("Genus", dict, keys: ["genus", "genus_name"])
        add("Family", dict, keys: ["family", "family_name"])
        add("Order", dict, keys: ["order", "order_name", "insect_order", "taxon_order"])
        add("Class", dict, keys: ["class", "class_name"])
        add("Phylum", dict, keys: ["phylum", "phylum_name"])
        add("Kingdom", dict, keys: ["kingdom", "kingdom_name"])
        add("Domain", dict, keys: ["domain", "domain_name"])
        if let nested = dict["order"] as? [String: Any] {
            add("Order", nested, keys: ["name", "title", "label"])
        }
        if let nested = dict["family"] as? [String: Any] {
            add("Family", nested, keys: ["name", "title", "label"])
        }
        return rows
    }
}
