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
        let response = Home.Load.Response(categories: categories, popularInsects: popularInsects)
        presenter?.presentLoad(response: response)
    }
}
