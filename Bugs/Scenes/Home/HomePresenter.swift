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
                categoryLocalizationKey: item.titleLocalizationKey,
                imageAssetName: item.imageAssetName
            )
        }
        let popularInsects = response.popularInsects.map { item in
            Home.PopularInsectCellViewModel(
                title: L10n.string(item.titleLocalizationKey),
                imageAssetName: item.imageAssetName,
                badgeAssetName: item.badgeAssetName
            )
        }
        let articles = response.articles.map { item in
            Home.ArticleCellViewModel(
                title: L10n.string(item.titleLocalizationKey),
                subtitle: L10n.string(item.subtitleLocalizationKey),
                imageAssetName: item.imageAssetName
            )
        }
        let viewModel = Home.Load.ViewModel(
            title: L10n.string("home.title"),
            searchPlaceholder: L10n.string("home.search.placeholder"),
            bannerTitle: L10n.string("home.ai_banner.title"),
            bannerButtonTitle: L10n.string("home.ai_banner.button"),
            categories: categories,
            popularSectionTitle: L10n.string("home.popular_this_week"),
            popularInsects: popularInsects,
            articlesSectionTitle: L10n.string("home.articles_section_title"),
            articles: articles
        )
        viewController?.displayLoad(viewModel: viewModel)
    }
}
