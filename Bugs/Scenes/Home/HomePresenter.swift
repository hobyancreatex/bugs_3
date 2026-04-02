//
//  HomePresenter.swift
//  Bugs
//

import Foundation

protocol HomePresentationLogic: AnyObject {
    func presentLoad(response: Home.Load.Response)
}

final class HomePresenter: HomePresentationLogic {

    weak var viewController: HomeDisplayLogic?

    func presentLoad(response: Home.Load.Response) {
        let categories = response.categories.map { item in
            Home.CategoryCellViewModel(
                title: L10n.string(item.titleLocalizationKey),
                imageAssetName: item.imageAssetName
            )
        }
        let viewModel = Home.Load.ViewModel(
            title: L10n.string("home.title"),
            searchPlaceholder: L10n.string("home.search.placeholder"),
            bannerTitle: L10n.string("home.ai_banner.title"),
            bannerButtonTitle: L10n.string("home.ai_banner.button"),
            categories: categories
        )
        viewController?.displayLoad(viewModel: viewModel)
    }
}
