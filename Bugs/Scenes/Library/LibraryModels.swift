//
//  LibraryModels.swift
//  Bugs
//

import Foundation

enum Library {

    struct CategoryDefinition {
        let titleLocalizationKey: String
        let imageAssetName: String
    }

    enum CellItem: Equatable {
        case category(title: String, imageAssetName: String)
        case spacer
    }

    enum Present {
        struct Request {
            let searchQuery: String
        }
        struct Response {
            let definitions: [CategoryDefinition]
        }
        struct ViewModel {
            let cellItems: [CellItem]
        }
    }
}
