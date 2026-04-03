//
//  CategoryInsectsPresenter.swift
//  Bugs
//

import Foundation

protocol CategoryInsectsPresentationLogic: AnyObject {
    func presentInsects(response: CategoryInsects.Present.Response)
}

final class CategoryInsectsPresenter: CategoryInsectsPresentationLogic {

    weak var viewController: CategoryInsectsDisplayLogic?

    func presentInsects(response: CategoryInsects.Present.Response) {
        let trimmedQuery = response.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let showsEmptySearchState = response.insects.isEmpty && !trimmedQuery.isEmpty
        let rows = response.insects.map {
            CategoryInsects.InsectCellViewModel(
                title: L10n.string($0.titleLocalizationKey),
                subtitle: L10n.string($0.subtitleLocalizationKey),
                imageAssetName: $0.imageAssetName
            )
        }
        viewController?.displayInsects(
            viewModel: CategoryInsects.Present.ViewModel(rows: rows, showsEmptySearchState: showsEmptySearchState)
        )
    }
}
