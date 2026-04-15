//
//  InsectDetailPresenter.swift
//  Bugs
//

import Foundation

protocol InsectDetailPresentationLogic: AnyObject {
    func presentLoading(_ active: Bool, hidesScroll: Bool)
    func presentDetail(response: InsectDetail.Load.Response)
    func presentAddToCollection(response: InsectDetail.AddToCollection.Response)
    func presentRemoveFromCollection(response: InsectDetail.RemoveFromCollection.Response)
}

final class InsectDetailPresenter: InsectDetailPresentationLogic {

    weak var viewController: InsectDetailDisplayLogic?

    func presentLoading(_ active: Bool, hidesScroll: Bool) {
        viewController?.displayLoading(active, hidesScroll: hidesScroll)
    }

    func presentDetail(response: InsectDetail.Load.Response) {
        let rows: [(title: String, value: String)]
        if let resolved = response.characteristicRowsResolved {
            rows = resolved
        } else {
            rows = response.characteristicRows.map {
                (title: L10n.string($0.titleKey), value: L10n.string($0.valueKey))
            }
        }
        let classificationRows: [(title: String, value: String)]
        if let resolved = response.classificationRowsResolved {
            classificationRows = resolved
        } else {
            classificationRows = response.classificationRows.map {
                (title: L10n.string($0.titleKey), value: L10n.string($0.valueKey))
            }
        }
        let galleryURLs = response.galleryImageURLs
        let names = response.galleryImageAssetNames
        let paddedURLs: [URL?] = (0 ..< names.count).map { idx in
            idx < galleryURLs.count ? galleryURLs[idx] : nil
        }

        let biteTextTrimmed = response.biteDescriptionOverride?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bitePhotos = response.bitePhotoURLs
        let showsBites = !biteTextTrimmed.isEmpty || !bitePhotos.isEmpty
        let biteBullets = biteTextTrimmed.isEmpty ? [] : InsectDetailBitesTextFormatter.bullets(from: biteTextTrimmed)

        viewController?.displayDetail(
            viewModel: InsectDetail.Load.ViewModel(
                heroImageAssetName: response.heroImageAssetName,
                heroImageURL: response.heroImageURL,
                galleryImageAssetNames: names,
                galleryImageURLs: paddedURLs,
                scientificTitle: response.scientificTitleOverride ?? L10n.string(response.scientificTitleKey),
                leftHazardStatus: response.leftHazardStatus,
                leftStatusText: L10n.string(response.leftHazardStatus.localizationKey),
                widespreadStatusText: response.widespreadStatusOverride ?? L10n.string(response.widespreadStatusKey),
                alsoKnownPrefix: L10n.string(response.alsoKnownPrefixKey),
                alsoKnownNames: response.aliasesNamesOverride ?? L10n.string(response.aliasesKey),
                descriptionSectionTitle: L10n.string(response.descriptionSectionKey),
                descriptionBody: response.descriptionBodyOverride ?? L10n.string(response.descriptionBodyKey),
                readMoreTitle: L10n.string(response.readMoreKey),
                readLessTitle: L10n.string("insect.detail.read_less"),
                characteristicsSectionTitle: L10n.string(response.characteristicsSectionKey),
                characteristicRows: rows,
                classificationSectionTitle: L10n.string(response.classificationSectionKey),
                classificationRows: classificationRows,
                bitesSectionTitle: L10n.string(response.bitesSectionKey),
                showsBitesSection: showsBites,
                bitesIntro: showsBites ? L10n.string("insect.detail.bites.intro") : "",
                bitesFirstAidTitle: showsBites ? L10n.string("insect.detail.bites.first_aid") : "",
                bitesBulletLines: biteBullets,
                bitePhotoURLs: bitePhotos,
                userCollectionPhotos: response.userCollectionPhotos,
                isAddToCollectionAvailable: response.isAddToCollectionAvailable,
                isInUserCollection: response.isInUserCollection,
                isDetailPayloadFromServer: response.isDetailPayloadFromServer
            )
        )
    }

    func presentAddToCollection(response: InsectDetail.AddToCollection.Response) {
        let viewModel: InsectDetail.AddToCollection.ViewModel
        switch response {
        case .success:
            viewModel = .success
        case .failure(let key):
            viewModel = .failure(
                title: Self.networkErrorAlertTitle(forMessageKey: key),
                message: L10n.string(key)
            )
        }
        viewController?.displayAddToCollectionResult(viewModel)
    }

    func presentRemoveFromCollection(response: InsectDetail.RemoveFromCollection.Response) {
        let viewModel: InsectDetail.RemoveFromCollection.ViewModel
        switch response {
        case .success:
            viewModel = .success
        case .failure(let key):
            viewModel = .failure(
                title: Self.networkErrorAlertTitle(forMessageKey: key),
                message: L10n.string(key)
            )
        }
        viewController?.displayRemoveFromCollectionResult(viewModel)
    }

    private static func networkErrorAlertTitle(forMessageKey key: String) -> String? {
        key == "common.error.try_later" ? L10n.string("common.error.title") : nil
    }
}
