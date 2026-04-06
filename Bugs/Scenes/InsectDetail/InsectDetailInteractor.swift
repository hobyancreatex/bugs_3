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

    init(heroImageAssetName: String, leftHazardStatus: InsectDetail.LeftHazardStatus = .harmless) {
        self.heroImageAssetName = heroImageAssetName
        self.leftHazardStatus = leftHazardStatus
    }

    func loadDetail(request: InsectDetail.Load.Request) {
        let gallery = (0..<5).map { _ in heroImageAssetName }
        let characteristicRows: [InsectDetail.CharacteristicLocalizationPair] = [
            .init(titleKey: "insect.detail.char.adult_size.title", valueKey: "insect.detail.char.adult_size.value"),
            .init(titleKey: "insect.detail.char.forms.title", valueKey: "insect.detail.char.forms.value"),
            .init(titleKey: "insect.detail.char.colors.title", valueKey: "insect.detail.char.colors.value"),
            .init(titleKey: "insect.detail.char.population.title", valueKey: "insect.detail.char.population.value"),
            .init(titleKey: "insect.detail.char.habitat.title", valueKey: "insect.detail.char.habitat.value"),
            .init(titleKey: "insect.detail.char.diet.title", valueKey: "insect.detail.char.diet.value")
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
                characteristicRows: characteristicRows
            )
        )
    }
}
