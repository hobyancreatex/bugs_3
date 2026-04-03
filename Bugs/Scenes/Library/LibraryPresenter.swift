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
        let showsEmptySearchState = response.definitions.isEmpty && !trimmedQuery.isEmpty
        var items: [Library.CellItem] = response.definitions.map {
            .category(
                title: L10n.string($0.titleLocalizationKey),
                titleLocalizationKey: $0.titleLocalizationKey,
                imageAssetName: $0.imageAssetName
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
        let viewModel = Library.Present.ViewModel(cellItems: items, showsEmptySearchState: showsEmptySearchState)
        viewController?.displayCategories(viewModel: viewModel)
    }
}
