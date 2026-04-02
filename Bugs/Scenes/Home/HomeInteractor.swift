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
        let response = Home.Load.Response(categories: categories)
        presenter?.presentLoad(response: response)
    }
}
