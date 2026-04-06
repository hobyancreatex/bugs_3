//
//  InsectDetailModels.swift
//  Bugs
//

import Foundation

enum InsectDetail {

    /// Пара ключей локализации для строки «характеристики» (заголовок / значение).
    struct CharacteristicLocalizationPair {
        let titleKey: String
        let valueKey: String
    }

    /// Левый бейдж в строке статусов: безопасен / ядовитый / токсичный.
    enum LeftHazardStatus {
        case harmless
        case poisonous
        case toxic

        var localizationKey: String {
            switch self {
            case .harmless: return "insect.detail.status.harmless"
            case .poisonous: return "insect.detail.status.poisonous"
            case .toxic: return "insect.detail.status.toxic"
            }
        }

        var imageAssetName: String {
            switch self {
            case .harmless: return "insect_detail_status_harmless"
            case .poisonous: return "insect_detail_status_poisonous"
            case .toxic: return "insect_detail_status_toxic"
            }
        }
    }

    enum Load {
        struct Request {}
        struct Response {
            let heroImageAssetName: String
            let galleryImageAssetNames: [String]
            let scientificTitleKey: String
            let leftHazardStatus: LeftHazardStatus
            let widespreadStatusKey: String
            let aliasesKey: String
            let alsoKnownPrefixKey: String
            let descriptionSectionKey: String
            let descriptionBodyKey: String
            let readMoreKey: String
            let characteristicsSectionKey: String
            let characteristicRows: [CharacteristicLocalizationPair]
        }
        struct ViewModel {
            let heroImageAssetName: String
            let galleryImageAssetNames: [String]
            let scientificTitle: String
            let leftHazardStatus: LeftHazardStatus
            let leftStatusText: String
            let widespreadStatusText: String
            let alsoKnownPrefix: String
            let alsoKnownNames: String
            let descriptionSectionTitle: String
            let descriptionBody: String
            let readMoreTitle: String
            let characteristicsSectionTitle: String
            let characteristicRows: [(title: String, value: String)]
        }
    }
}
