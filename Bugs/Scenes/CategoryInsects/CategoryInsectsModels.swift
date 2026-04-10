//
//  CategoryInsectsModels.swift
//  Bugs
//

import Foundation

enum CategoryInsects {

    struct InsectDefinition {
        let insectId: String?
        let title: String
        let subtitle: String
        let imageAssetName: String
        let imageURL: URL?
    }

    struct InsectCellViewModel {
        let insectId: String?
        let title: String
        let subtitle: String
        let imageAssetName: String
        let imageURL: URL?
    }

    enum Present {
        struct Request {
            let searchQuery: String
        }
        struct Response {
            let insects: [InsectDefinition]
            let searchQuery: String
            let isLoading: Bool
            let isLoadingMore: Bool
        }
        struct ViewModel {
            let isLoading: Bool
            let isLoadingMore: Bool
            let rows: [InsectCellViewModel]
            let showsEmptySearchState: Bool
        }
    }
}
