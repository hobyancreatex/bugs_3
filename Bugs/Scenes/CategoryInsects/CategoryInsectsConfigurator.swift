//
//  CategoryInsectsConfigurator.swift
//  Bugs
//

import UIKit

enum CategoryInsectsConfigurator {

    static func assemble(categoryLocalizationKey: String) -> UIViewController {
        let viewController = CategoryInsectsViewController(categoryLocalizationKey: categoryLocalizationKey)
        let interactor = CategoryInsectsInteractor(categoryRoutingKey: categoryLocalizationKey)
        let presenter = CategoryInsectsPresenter()

        viewController.interactor = interactor
        interactor.presenter = presenter
        presenter.viewController = viewController

        return viewController
    }
}
