//
//  InsectDetailPresenter.swift
//  Bugs
//

import Foundation

protocol InsectDetailPresentationLogic: AnyObject {
    func presentDetail(response: InsectDetail.Load.Response)
}

final class InsectDetailPresenter: InsectDetailPresentationLogic {

    weak var viewController: InsectDetailDisplayLogic?

    func presentDetail(response: InsectDetail.Load.Response) {
        let rows = response.characteristicRows.map {
            (title: L10n.string($0.titleKey), value: L10n.string($0.valueKey))
        }
        viewController?.displayDetail(
            viewModel: InsectDetail.Load.ViewModel(
                heroImageAssetName: response.heroImageAssetName,
                galleryImageAssetNames: response.galleryImageAssetNames,
                scientificTitle: L10n.string(response.scientificTitleKey),
                leftHazardStatus: response.leftHazardStatus,
                leftStatusText: L10n.string(response.leftHazardStatus.localizationKey),
                widespreadStatusText: L10n.string(response.widespreadStatusKey),
                alsoKnownPrefix: L10n.string(response.alsoKnownPrefixKey),
                alsoKnownNames: L10n.string(response.aliasesKey),
                descriptionSectionTitle: L10n.string(response.descriptionSectionKey),
                descriptionBody: L10n.string(response.descriptionBodyKey),
                readMoreTitle: L10n.string(response.readMoreKey),
                characteristicsSectionTitle: L10n.string(response.characteristicsSectionKey),
                characteristicRows: rows
            )
        )
    }
}
