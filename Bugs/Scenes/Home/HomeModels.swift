//
//  HomeModels.swift
//  Bugs
//

import Foundation

enum Home {

    enum Load {
        struct Request {}
        struct Response {
            let categories: [CategoryItemResponse]
        }
        struct ViewModel {
            let title: String
            let searchPlaceholder: String
            let bannerTitle: String
            let bannerButtonTitle: String
            let categories: [CategoryCellViewModel]
        }
    }

    struct CategoryItemResponse {
        let titleLocalizationKey: String
        let imageAssetName: String
    }

    struct CategoryCellViewModel {
        let title: String
        let imageAssetName: String
    }
}
