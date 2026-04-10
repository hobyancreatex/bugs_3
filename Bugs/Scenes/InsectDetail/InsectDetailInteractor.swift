//
//  InsectDetailInteractor.swift
//  Bugs
//

import Foundation

protocol InsectDetailBusinessLogic: AnyObject {
    func loadDetail(request: InsectDetail.Load.Request)
}

final class InsectDetailInteractor: InsectDetailBusinessLogic {

    var presenter: InsectDetailPresentationLogic?

    private let insectId: String?
    private let heroImageAssetName: String
    private let heroImageURL: URL?
    private let leftHazardStatus: InsectDetail.LeftHazardStatus

    /// Разные ассеты из каталога — для отладки полноэкранной галереи и пейджинга.
    private static let stubGalleryAssetNames: [String] = [
        "home_popular_insect",
        "home_article_cover",
        "home_category_thumbnail",
        "scanner_no_match_illustration",
        "home_ai_banner_background",
        "scanner_tip_1_right",
        "scanner_tip_2_right",
        "scanner_tip_3_right",
        "scanner_tip_4_right",
        "scanner_tip_1_wrong",
        "scanner_tip_2_wrong",
        "scanner_tip_3_wrong",
        "scanner_tip_4_wrong",
        "list_search_empty",
        "profile_collection_empty",
        "insect_detail_status_harmless",
        "insect_detail_status_poisonous",
        "insect_detail_status_toxic",
        "insect_detail_status_widespread",
    ]

    init(
        insectId: String? = nil,
        heroImageAssetName: String,
        heroImageURL: URL? = nil,
        leftHazardStatus: InsectDetail.LeftHazardStatus = .harmless
    ) {
        self.insectId = insectId
        self.heroImageAssetName = heroImageAssetName
        self.heroImageURL = heroImageURL
        self.leftHazardStatus = leftHazardStatus
    }

    func loadDetail(request: InsectDetail.Load.Request) {
        let trimmedId = insectId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedId.isEmpty else {
            presenter?.presentDetail(response: Self.stubResponse(
                heroImageAssetName: heroImageAssetName,
                heroImageURL: heroImageURL,
                leftHazardStatus: leftHazardStatus
            ))
            return
        }

        Task { [weak self] in
            guard let self else { return }
            await MainActor.run { [weak self] in
                self?.presenter?.presentLoading(true)
            }
            do {
                let path = "insects/\(trimmedId)/"
                let data = try await CollectAPIClient.shared.get(path: path)
                CollectAPILogger.logInsectDetailResponse(data)
                let root = try CollectInsectDetailPayload.rootObject(from: data)
                let mapped = CollectInsectDetailMapper.map(root)
                let response: InsectDetail.Load.Response
                if let mapped {
                    response = Self.response(from: mapped, fallbackHeroURL: self.heroImageURL)
                } else {
                    response = Self.stubResponse(
                        heroImageAssetName: self.heroImageAssetName,
                        heroImageURL: self.heroImageURL,
                        leftHazardStatus: self.leftHazardStatus
                    )
                }
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.presenter?.presentLoading(false)
                    self.presenter?.presentDetail(response: response)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.presenter?.presentLoading(false)
                    self.presenter?.presentDetail(
                        response: Self.stubResponse(
                            heroImageAssetName: self.heroImageAssetName,
                            heroImageURL: self.heroImageURL,
                            leftHazardStatus: self.leftHazardStatus
                        )
                    )
                }
            }
        }
    }

    private static func response(from mapped: CollectInsectDetailMapper.Mapped, fallbackHeroURL: URL?) -> InsectDetail.Load.Response {
        let heroURL = mapped.heroImageURL ?? fallbackHeroURL
        let galleryURLs = mapped.galleryImageURLs
        let galleryNames = Array(repeating: "home_popular_insect", count: galleryURLs.count)
        let charResolved = mapped.characteristics.isEmpty ? nil : mapped.characteristics
        let classResolved = mapped.classification.isEmpty ? nil : mapped.classification
        let stubChar = stubCharacteristicRows()
        let stubClass = stubClassificationRows()
        let hazard: InsectDetail.LeftHazardStatus = mapped.isPoisonous ? .poisonous : .harmless
        let widespreadOverride: String? = mapped.widespread.map { value in
            value
                ? L10n.string("insect.detail.widespread.api.yes")
                : L10n.string("insect.detail.widespread.api.no")
        }
        let biteText = mapped.biteDescription.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        return InsectDetail.Load.Response(
            heroImageAssetName: "home_popular_insect",
            heroImageURL: heroURL,
            galleryImageAssetNames: galleryNames,
            galleryImageURLs: galleryURLs.map { Optional.some($0) },
            scientificTitleKey: "insect.detail.mock.scientific_title",
            scientificTitleOverride: mapped.title,
            leftHazardStatus: hazard,
            widespreadStatusKey: "insect.detail.status.widespread",
            widespreadStatusOverride: widespreadOverride,
            aliasesKey: "insect.detail.mock.aliases",
            aliasesNamesOverride: mapped.scientificLine.flatMap { $0.isEmpty ? nil : $0 },
            alsoKnownPrefixKey: "insect.detail.also_known_prefix",
            descriptionSectionKey: "insect.detail.section.description",
            descriptionBodyKey: "insect.detail.mock.description",
            descriptionBodyOverride: mapped.description.isEmpty ? nil : mapped.description,
            readMoreKey: "insect.detail.read_more",
            characteristicsSectionKey: "insect.detail.section.characteristics",
            characteristicRows: stubChar,
            characteristicRowsResolved: charResolved,
            classificationSectionKey: "insect.detail.section.classification",
            classificationRows: stubClass,
            classificationRowsResolved: classResolved,
            bitesSectionKey: "insect.detail.section.bites",
            biteDescriptionOverride: biteText,
            bitePhotoURLs: mapped.bitePhotoURLs
        )
    }

    private static func stubResponse(
        heroImageAssetName: String,
        heroImageURL: URL?,
        leftHazardStatus: InsectDetail.LeftHazardStatus
    ) -> InsectDetail.Load.Response {
        var gallery = stubGalleryAssetNames
        if !gallery.contains(heroImageAssetName) {
            gallery.insert(heroImageAssetName, at: 0)
        }
        let nilURLs = [URL?](repeating: nil, count: gallery.count)
        return InsectDetail.Load.Response(
            heroImageAssetName: heroImageAssetName,
            heroImageURL: heroImageURL,
            galleryImageAssetNames: gallery,
            galleryImageURLs: nilURLs,
            scientificTitleKey: "insect.detail.mock.scientific_title",
            scientificTitleOverride: nil,
            leftHazardStatus: leftHazardStatus,
            widespreadStatusKey: "insect.detail.status.widespread",
            widespreadStatusOverride: nil,
            aliasesKey: "insect.detail.mock.aliases",
            aliasesNamesOverride: nil,
            alsoKnownPrefixKey: "insect.detail.also_known_prefix",
            descriptionSectionKey: "insect.detail.section.description",
            descriptionBodyKey: "insect.detail.mock.description",
            descriptionBodyOverride: nil,
            readMoreKey: "insect.detail.read_more",
            characteristicsSectionKey: "insect.detail.section.characteristics",
            characteristicRows: stubCharacteristicRows(),
            characteristicRowsResolved: nil,
            classificationSectionKey: "insect.detail.section.classification",
            classificationRows: stubClassificationRows(),
            classificationRowsResolved: nil,
            bitesSectionKey: "insect.detail.section.bites",
            biteDescriptionOverride: nil,
            bitePhotoURLs: []
        )
    }

    private static func stubCharacteristicRows() -> [InsectDetail.CharacteristicLocalizationPair] {
        [
            .init(titleKey: "insect.detail.char.adult_size.title", valueKey: "insect.detail.char.adult_size.value"),
            .init(titleKey: "insect.detail.char.forms.title", valueKey: "insect.detail.char.forms.value"),
            .init(titleKey: "insect.detail.char.colors.title", valueKey: "insect.detail.char.colors.value"),
            .init(titleKey: "insect.detail.char.population.title", valueKey: "insect.detail.char.population.value"),
            .init(titleKey: "insect.detail.char.habitat.title", valueKey: "insect.detail.char.habitat.value"),
            .init(titleKey: "insect.detail.char.diet.title", valueKey: "insect.detail.char.diet.value"),
        ]
    }

    private static func stubClassificationRows() -> [InsectDetail.CharacteristicLocalizationPair] {
        [
            .init(titleKey: "insect.detail.class.genus.title", valueKey: "insect.detail.class.genus.value"),
            .init(titleKey: "insect.detail.class.family.title", valueKey: "insect.detail.class.family.value"),
            .init(titleKey: "insect.detail.class.order.title", valueKey: "insect.detail.class.order.value"),
            .init(titleKey: "insect.detail.class.class.title", valueKey: "insect.detail.class.class.value"),
            .init(titleKey: "insect.detail.class.phylum.title", valueKey: "insect.detail.class.phylum.value"),
            .init(titleKey: "insect.detail.class.kingdom.title", valueKey: "insect.detail.class.kingdom.value"),
            .init(titleKey: "insect.detail.class.domain.title", valueKey: "insect.detail.class.domain.value"),
        ]
    }
}
