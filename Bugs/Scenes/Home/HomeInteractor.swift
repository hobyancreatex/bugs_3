//
//  HomeInteractor.swift
//  Bugs
//

import Foundation

protocol HomeBusinessLogic: AnyObject {
    func load(request: Home.Load.Request)
}

final class HomeInteractor: HomeBusinessLogic {

    var presenter: HomePresentationLogic?

    func load(request: Home.Load.Request) {
        let categories: [Home.CategoryItemResponse] = [
            Home.CategoryItemResponse(titleLocalizationKey: "home.category.coleoptera", imageAssetName: "home_category_thumbnail"),
            Home.CategoryItemResponse(titleLocalizationKey: "home.category.scorpiones", imageAssetName: "home_category_thumbnail"),
            Home.CategoryItemResponse(titleLocalizationKey: "home.category.hymenoptera", imageAssetName: "home_category_thumbnail"),
            Home.CategoryItemResponse(titleLocalizationKey: "home.category.araneae", imageAssetName: "home_category_thumbnail")
        ]
        let popularInsects: [Home.PopularInsectItemResponse] = [
            Home.PopularInsectItemResponse(titleLocalizationKey: "home.popular.butterfly", imageAssetName: "home_popular_insect", badgeAssetName: "home_popular_badge"),
            Home.PopularInsectItemResponse(titleLocalizationKey: "home.popular.mantis", imageAssetName: "home_popular_insect", badgeAssetName: "home_popular_badge"),
            Home.PopularInsectItemResponse(titleLocalizationKey: "home.popular.ant", imageAssetName: "home_popular_insect", badgeAssetName: "home_popular_badge"),
            Home.PopularInsectItemResponse(titleLocalizationKey: "home.popular.beetle", imageAssetName: "home_popular_insect", badgeAssetName: "home_popular_badge")
        ]
        let articles: [Home.ArticleItemResponse] = [
            Home.ArticleItemResponse(
                titleLocalizationKey: "home.article.identify.title",
                subtitleLocalizationKey: "home.article.identify.subtitle",
                imageAssetName: "home_article_cover",
                blocks: [
                    Home.ArticleDetailBlockResponse(
                        titleLocalizationKey: "home.article.identify.block1.title",
                        bodyLocalizationKey: "home.article.identify.block1.body"
                    ),
                    Home.ArticleDetailBlockResponse(
                        titleLocalizationKey: "home.article.identify.block2.title",
                        bodyLocalizationKey: "home.article.identify.block2.body"
                    ),
                ]
            ),
            Home.ArticleItemResponse(
                titleLocalizationKey: "home.article.habitats.title",
                subtitleLocalizationKey: "home.article.habitats.subtitle",
                imageAssetName: "home_article_cover",
                blocks: [
                    Home.ArticleDetailBlockResponse(
                        titleLocalizationKey: "home.article.habitats.block1.title",
                        bodyLocalizationKey: "home.article.habitats.block1.body"
                    ),
                    Home.ArticleDetailBlockResponse(
                        titleLocalizationKey: "home.article.habitats.block2.title",
                        bodyLocalizationKey: "home.article.habitats.block2.body"
                    ),
                ]
            ),
            Home.ArticleItemResponse(
                titleLocalizationKey: "home.article.photography.title",
                subtitleLocalizationKey: "home.article.photography.subtitle",
                imageAssetName: "home_article_cover",
                blocks: [
                    Home.ArticleDetailBlockResponse(
                        titleLocalizationKey: "home.article.photography.block1.title",
                        bodyLocalizationKey: "home.article.photography.block1.body"
                    ),
                    Home.ArticleDetailBlockResponse(
                        titleLocalizationKey: "home.article.photography.block2.title",
                        bodyLocalizationKey: "home.article.photography.block2.body"
                    ),
                ]
            ),
        ]
        let response = Home.Load.Response(categories: categories, popularInsects: popularInsects, articles: articles)
        presenter?.presentLoad(response: response)
    }
}
