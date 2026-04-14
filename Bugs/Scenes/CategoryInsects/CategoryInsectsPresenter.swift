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
        if response.isLoading {
            viewController?.displayInsects(
                viewModel: CategoryInsects.Present.ViewModel(
                    isLoading: true,
                    isLoadingMore: false,
                    rows: [],
                    showsEmptySearchState: false
                )
            )
            return
        }

        let trimmedQuery = response.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let showsEmptySearchState = response.insects.isEmpty && !trimmedQuery.isEmpty
        let rows = response.insects.map {
            CategoryInsects.InsectCellViewModel(
                insectId: $0.insectId,
                title: $0.title,
                subtitle: $0.subtitle,
                imageAssetName: $0.imageAssetName,
                imageURL: $0.imageURL
            )
        }
        viewController?.displayInsects(
            viewModel: CategoryInsects.Present.ViewModel(
                isLoading: false,
                isLoadingMore: response.isLoadingMore,
                rows: rows,
                showsEmptySearchState: showsEmptySearchState
            )
        )
        if response.didFailNetwork {
            viewController?.displayGenericRequestError()
        }
    }
}
