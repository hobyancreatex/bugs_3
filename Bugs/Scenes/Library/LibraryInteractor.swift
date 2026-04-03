//
//  LibraryInteractor.swift
//  Bugs
//

import Foundation

protocol LibraryBusinessLogic: AnyObject {
    func presentCategories(request: Library.Present.Request)
}

final class LibraryInteractor: LibraryBusinessLogic {

    var presenter: LibraryPresentationLogic?

    private let allCategories: [Library.CategoryDefinition] = [
        Library.CategoryDefinition(titleLocalizationKey: "home.category.coleoptera", imageAssetName: "home_category_thumbnail"),
        Library.CategoryDefinition(titleLocalizationKey: "home.category.scorpiones", imageAssetName: "home_category_thumbnail"),
        Library.CategoryDefinition(titleLocalizationKey: "home.category.hymenoptera", imageAssetName: "home_category_thumbnail"),
        Library.CategoryDefinition(titleLocalizationKey: "home.category.araneae", imageAssetName: "home_category_thumbnail"),
        Library.CategoryDefinition(titleLocalizationKey: "home.category.lepidoptera", imageAssetName: "home_category_thumbnail"),
        Library.CategoryDefinition(titleLocalizationKey: "home.category.diptera", imageAssetName: "home_category_thumbnail"),
        Library.CategoryDefinition(titleLocalizationKey: "home.category.blattodea", imageAssetName: "home_category_thumbnail"),
        Library.CategoryDefinition(titleLocalizationKey: "home.category.hemiptera", imageAssetName: "home_category_thumbnail")
    ]

    func presentCategories(request: Library.Present.Request) {
        let query = request.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matches: [Library.CategoryDefinition]
        if query.isEmpty {
            matches = allCategories
        } else {
            matches = allCategories.filter {
                L10n.string($0.titleLocalizationKey).lowercased().contains(query)
            }
        }
        let response = Library.Present.Response(definitions: matches)
        presenter?.presentCategories(response: response)
    }
}
