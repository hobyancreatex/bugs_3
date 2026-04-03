//
//  CategoryInsectsModels.swift
//  Bugs
//

import Foundation

enum CategoryInsects {

    struct InsectDefinition {
        let titleLocalizationKey: String
        let subtitleLocalizationKey: String
        let imageAssetName: String
    }

    struct InsectCellViewModel {
        let title: String
        let subtitle: String
        let imageAssetName: String
    }

    enum Present {
        struct Request {
            let searchQuery: String
        }
        struct Response {
            let insects: [InsectDefinition]
            let searchQuery: String
        }
        struct ViewModel {
            let rows: [InsectCellViewModel]
            let showsEmptySearchState: Bool
        }
    }
}
