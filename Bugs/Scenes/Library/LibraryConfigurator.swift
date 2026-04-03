//
//  LibraryConfigurator.swift
//  Bugs
//

import UIKit

enum LibraryConfigurator {

    static func assemble() -> UIViewController {
        let viewController = LibraryViewController()
        let interactor = LibraryInteractor()
        let presenter = LibraryPresenter()

        viewController.interactor = interactor
        interactor.presenter = presenter
        presenter.viewController = viewController

        return viewController
    }
}
