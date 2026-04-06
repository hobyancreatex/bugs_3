//
//  InsectDetailConfigurator.swift
//  Bugs
//

import UIKit

enum InsectDetailConfigurator {

    static func assemble(
        heroImageAssetName: String,
        leftHazardStatus: InsectDetail.LeftHazardStatus = .harmless,
        isInCollection: Bool = false
    ) -> UIViewController {
        let viewController = InsectDetailViewController()
        viewController.isInCollection = isInCollection
        let interactor = InsectDetailInteractor(heroImageAssetName: heroImageAssetName, leftHazardStatus: leftHazardStatus)
        let presenter = InsectDetailPresenter()

        viewController.interactor = interactor
        interactor.presenter = presenter
        presenter.viewController = viewController

        return viewController
    }
}
