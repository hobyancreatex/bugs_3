//
//  HomeConfigurator.swift
//  Bugs
//

import UIKit

enum HomeConfigurator {

    static func assemble() -> UIViewController {
        let viewController = HomeViewController()
        let interactor = HomeInteractor()
        let presenter = HomePresenter()

        viewController.interactor = interactor
        interactor.presenter = presenter
        presenter.viewController = viewController

        return viewController
    }
}
