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

    private let heroImageAssetName: String
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

    init(heroImageAssetName: String, leftHazardStatus: InsectDetail.LeftHazardStatus = .harmless) {
        self.heroImageAssetName = heroImageAssetName
        self.leftHazardStatus = leftHazardStatus
    }

    func loadDetail(request: InsectDetail.Load.Request) {
        var gallery = Self.stubGalleryAssetNames
        if !gallery.contains(heroImageAssetName) {
            gallery.insert(heroImageAssetName, at: 0)
        }
        let characteristicRows: [InsectDetail.CharacteristicLocalizationPair] = [
            .init(titleKey: "insect.detail.char.adult_size.title", valueKey: "insect.detail.char.adult_size.value"),
            .init(titleKey: "insect.detail.char.forms.title", valueKey: "insect.detail.char.forms.value"),
            .init(titleKey: "insect.detail.char.colors.title", valueKey: "insect.detail.char.colors.value"),
            .init(titleKey: "insect.detail.char.population.title", valueKey: "insect.detail.char.population.value"),
            .init(titleKey: "insect.detail.char.habitat.title", valueKey: "insect.detail.char.habitat.value"),
            .init(titleKey: "insect.detail.char.diet.title", valueKey: "insect.detail.char.diet.value")
        ]
        let classificationRows: [InsectDetail.CharacteristicLocalizationPair] = [
            .init(titleKey: "insect.detail.class.genus.title", valueKey: "insect.detail.class.genus.value"),
            .init(titleKey: "insect.detail.class.family.title", valueKey: "insect.detail.class.family.value"),
            .init(titleKey: "insect.detail.class.order.title", valueKey: "insect.detail.class.order.value"),
            .init(titleKey: "insect.detail.class.class.title", valueKey: "insect.detail.class.class.value"),
            .init(titleKey: "insect.detail.class.phylum.title", valueKey: "insect.detail.class.phylum.value"),
            .init(titleKey: "insect.detail.class.kingdom.title", valueKey: "insect.detail.class.kingdom.value"),
            .init(titleKey: "insect.detail.class.domain.title", valueKey: "insect.detail.class.domain.value")
        ]
        presenter?.presentDetail(
            response: InsectDetail.Load.Response(
                heroImageAssetName: heroImageAssetName,
                galleryImageAssetNames: gallery,
                scientificTitleKey: "insect.detail.mock.scientific_title",
                leftHazardStatus: leftHazardStatus,
                widespreadStatusKey: "insect.detail.status.widespread",
                aliasesKey: "insect.detail.mock.aliases",
                alsoKnownPrefixKey: "insect.detail.also_known_prefix",
                descriptionSectionKey: "insect.detail.section.description",
                descriptionBodyKey: "insect.detail.mock.description",
                readMoreKey: "insect.detail.read_more",
                characteristicsSectionKey: "insect.detail.section.characteristics",
                characteristicRows: characteristicRows,
                classificationSectionKey: "insect.detail.section.classification",
                classificationRows: classificationRows,
                bitesSectionKey: "insect.detail.section.bites"
            )
        )
    }
}
