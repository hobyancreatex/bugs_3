//
//  InsectDetailConfigurator.swift
//  Bugs
//

import UIKit

enum InsectDetailConfigurator {

    static func assemble(
        heroImageAssetName: String,
        heroImageURL: URL? = nil,
        insectId: String? = nil,
        leftHazardStatus: InsectDetail.LeftHazardStatus = .harmless,
        isInCollection: Bool = false,
        prefilledCollectionJPEG: Data? = nil
    ) -> UIViewController {
        let viewController = InsectDetailViewController()
        viewController.isInCollection = isInCollection
        viewController.prefilledCollectionJPEG = prefilledCollectionJPEG
        let interactor = InsectDetailInteractor(
            insectId: insectId,
            heroImageAssetName: heroImageAssetName,
            heroImageURL: heroImageURL,
            leftHazardStatus: leftHazardStatus
        )
        let presenter = InsectDetailPresenter()

        viewController.interactor = interactor
        interactor.presenter = presenter
        presenter.viewController = viewController

        return viewController
    }
}
