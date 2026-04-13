//
//  InsectDetailModels.swift
//  Bugs
//

import Foundation

enum InsectDetail {

    /// Добавление фото в коллекцию: два сценария API (см. legacy `createNewCollection` / `addToExistedCollection`).
    enum AddToCollection {
        struct Request {
            let jpegData: Data
        }

        enum Response {
            case success
            case failure(messageKey: String)
        }

        enum ViewModel {
            case success
            case failure(message: String)
        }
    }

    enum RemoveFromCollection {
        struct Request {}

        enum Response {
            case success
            case failure(messageKey: String)
        }

        enum ViewModel {
            case success
            case failure(message: String)
        }
    }

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
            let heroImageURL: URL?
            let galleryImageAssetNames: [String]
            /// Параллельно именам ассетов; при непустом URL ячейка грузит картинку по сети.
            let galleryImageURLs: [URL?]
            let scientificTitleKey: String
            /// Если задано, подставляется вместо `L10n.string(scientificTitleKey)` (например имя с API).
            let scientificTitleOverride: String?
            let leftHazardStatus: LeftHazardStatus
            let widespreadStatusKey: String
            /// Текст из API (`widespread`), иначе локализованный заглушечный `widespreadStatusKey`.
            let widespreadStatusOverride: String?
            let aliasesKey: String
            /// Если задано, подставляется вместо `L10n.string(aliasesKey)` (например латинское имя).
            let aliasesNamesOverride: String?
            let alsoKnownPrefixKey: String
            let descriptionSectionKey: String
            let descriptionBodyKey: String
            /// Если задано, подставляется вместо `L10n.string(descriptionBodyKey)`.
            let descriptionBodyOverride: String?
            let readMoreKey: String
            let characteristicsSectionKey: String
            let characteristicRows: [CharacteristicLocalizationPair]
            let characteristicRowsResolved: [(title: String, value: String)]?
            let classificationSectionKey: String
            let classificationRows: [CharacteristicLocalizationPair]
            let classificationRowsResolved: [(title: String, value: String)]?
            let bitesSectionKey: String
            let biteDescriptionOverride: String?
            let bitePhotoURLs: [URL]
            /// Показать CTA «В коллекцию» (есть id вида и нет записи в коллекции).
            let isAddToCollectionAvailable: Bool
            /// У `GET insects/{id}/` уже есть `user_collection` — показываем удаление.
            let isInUserCollection: Bool
        }
        struct ViewModel {
            let heroImageAssetName: String
            let heroImageURL: URL?
            let galleryImageAssetNames: [String]
            let galleryImageURLs: [URL?]
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
            let classificationSectionTitle: String
            let classificationRows: [(title: String, value: String)]
            let bitesSectionTitle: String
            /// Показывать секцию «Укусы» (есть текст и/или фото укусов с API).
            let showsBitesSection: Bool
            let bitesIntro: String
            let bitesFirstAidTitle: String
            let bitesBulletLines: [String]
            let bitePhotoURLs: [URL]
            let isAddToCollectionAvailable: Bool
            let isInUserCollection: Bool
        }
    }
}
