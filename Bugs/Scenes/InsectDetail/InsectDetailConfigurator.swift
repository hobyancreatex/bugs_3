//
//  InsectDetailConfigurator.swift
//  Bugs
//

import UIKit

enum InsectDetailConfigurator {

    static func assemble(
        heroImageAssetName: String,
        leftHazardStatus: InsectDetail.LeftHazardStatus = .harmless
    ) -> UIViewController {
        let viewController = InsectDetailViewController()
        let interactor = InsectDetailInteractor(heroImageAssetName: heroImageAssetName, leftHazardStatus: leftHazardStatus)
        let presenter = InsectDetailPresenter()

        viewController.interactor = interactor
        interactor.presenter = presenter
        presenter.viewController = viewController

        return viewController
    }
}
