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
                title: item.displayTitle,
                categoryLocalizationKey: item.categoryRoutingKey,
                imageAssetName: item.imageAssetName,
                imageURL: item.imageURL
            )
        }
        let popularInsects = response.popularInsects.map { item in
            Home.PopularInsectCellViewModel(
                insectId: item.insectId,
                title: item.displayTitle,
                imageAssetName: item.imageAssetName,
                badgeAssetName: item.badgeAssetName,
                imageURL: item.imageURL
            )
        }
        let articles = response.articles.map { item in
            let detail = Home.ArticleDetailViewModel(from: item)
            return Home.ArticleCellViewModel(
                articleId: item.articleId,
                title: detail.title,
                subtitle: detail.subtitle,
                imageAssetName: item.imageAssetName,
                coverImageURL: item.coverImageURL,
                detail: detail
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
        if response.hadNetworkError {
            viewController?.displayGenericRequestError()
        }
    }
}
