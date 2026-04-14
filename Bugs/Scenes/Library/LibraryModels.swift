//
//  LibraryModels.swift
//  Bugs
//

import Foundation

enum Library {

    struct CategoryDefinition: Equatable {
        let displayTitle: String
        let routingKey: String
        let imageAssetName: String
        let imageURL: URL?
    }

    enum CellItem: Equatable {
        case category(title: String, routingKey: String, imageAssetName: String, imageURL: URL?)
        case spacer
    }

    enum Present {
        struct Request {
            let searchQuery: String
        }
        struct Response {
            let definitions: [CategoryDefinition]
            let searchQuery: String
            let isLoading: Bool
            /// Categories request failed (network / bad status); list may be empty.
            let listRequestFailed: Bool
        }
        struct ViewModel {
            let isLoading: Bool
            let cellItems: [CellItem]
            let showsEmptySearchState: Bool
        }
    }
}
