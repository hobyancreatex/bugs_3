//
//  LibraryPresenter.swift
//  Bugs
//

import Foundation

protocol LibraryPresentationLogic: AnyObject {
    func presentCategories(response: Library.Present.Response)
}

final class LibraryPresenter: LibraryPresentationLogic {

    weak var viewController: LibraryDisplayLogic?

    func presentCategories(response: Library.Present.Response) {
        let trimmedQuery = response.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        if response.isLoading {
            let viewModel = Library.Present.ViewModel(
                isLoading: true,
                cellItems: [],
                showsEmptySearchState: false
            )
            viewController?.displayCategories(viewModel: viewModel)
            return
        }

        let showsEmptySearchState = response.definitions.isEmpty && !trimmedQuery.isEmpty
        var items: [Library.CellItem] = response.definitions.map {
            .category(
                title: $0.displayTitle,
                routingKey: $0.routingKey,
                imageAssetName: $0.imageAssetName,
                imageURL: $0.imageURL
            )
        }
        if !items.isEmpty {
            let remainder = items.count % 3
            if remainder != 0 {
                for _ in 0..<(3 - remainder) {
                    items.append(.spacer)
                }
            }
        }
        let viewModel = Library.Present.ViewModel(
            isLoading: false,
            cellItems: items,
            showsEmptySearchState: showsEmptySearchState
        )
        viewController?.displayCategories(viewModel: viewModel)
        if response.listRequestFailed {
            viewController?.displayGenericRequestError()
        }
    }
}
