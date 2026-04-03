//
//  CategoryInsectsInteractor.swift
//  Bugs
//

import Foundation

protocol CategoryInsectsBusinessLogic: AnyObject {
    func presentInsects(request: CategoryInsects.Present.Request)
}

final class CategoryInsectsInteractor: CategoryInsectsBusinessLogic {

    var presenter: CategoryInsectsPresentationLogic?

    private let categoryLocalizationKey: String

    init(categoryLocalizationKey: String) {
        self.categoryLocalizationKey = categoryLocalizationKey
    }

    func presentInsects(request: CategoryInsects.Present.Request) {
        let all = insects(for: categoryLocalizationKey)
        let query = request.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered: [CategoryInsects.InsectDefinition]
        if query.isEmpty {
            filtered = all
        } else {
            filtered = all.filter { def in
                let title = L10n.string(def.titleLocalizationKey).lowercased()
                let subtitle = L10n.string(def.subtitleLocalizationKey).lowercased()
                return title.contains(query) || subtitle.contains(query)
            }
        }
        presenter?.presentInsects(
            response: CategoryInsects.Present.Response(insects: filtered, searchQuery: request.searchQuery)
        )
    }

    private func insects(for categoryKey: String) -> [CategoryInsects.InsectDefinition] {
        if categoryKey == "home.category.hymenoptera" {
            return [
                CategoryInsects.InsectDefinition(titleLocalizationKey: "insect.hym.1.title", subtitleLocalizationKey: "insect.hym.1.subtitle", imageAssetName: "home_popular_insect"),
                CategoryInsects.InsectDefinition(titleLocalizationKey: "insect.hym.2.title", subtitleLocalizationKey: "insect.hym.2.subtitle", imageAssetName: "home_popular_insect"),
                CategoryInsects.InsectDefinition(titleLocalizationKey: "insect.hym.3.title", subtitleLocalizationKey: "insect.hym.3.subtitle", imageAssetName: "home_popular_insect"),
                CategoryInsects.InsectDefinition(titleLocalizationKey: "insect.hym.4.title", subtitleLocalizationKey: "insect.hym.4.subtitle", imageAssetName: "home_popular_insect"),
                CategoryInsects.InsectDefinition(titleLocalizationKey: "insect.hym.5.title", subtitleLocalizationKey: "insect.hym.5.subtitle", imageAssetName: "home_popular_insect")
            ]
        }
        return [
            CategoryInsects.InsectDefinition(titleLocalizationKey: "insect.default.1.title", subtitleLocalizationKey: "insect.default.1.subtitle", imageAssetName: "home_popular_insect"),
            CategoryInsects.InsectDefinition(titleLocalizationKey: "insect.default.2.title", subtitleLocalizationKey: "insect.default.2.subtitle", imageAssetName: "home_popular_insect"),
            CategoryInsects.InsectDefinition(titleLocalizationKey: "insect.default.3.title", subtitleLocalizationKey: "insect.default.3.subtitle", imageAssetName: "home_popular_insect")
        ]
    }
}
