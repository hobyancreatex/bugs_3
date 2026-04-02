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
            let popularInsects: [PopularInsectItemResponse]
        }
        struct ViewModel {
            let title: String
            let searchPlaceholder: String
            let bannerTitle: String
            let bannerButtonTitle: String
            let categories: [CategoryCellViewModel]
            let popularSectionTitle: String
            let popularInsects: [PopularInsectCellViewModel]
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

    struct PopularInsectItemResponse {
        let titleLocalizationKey: String
        let imageAssetName: String
        let badgeAssetName: String
    }

    struct PopularInsectCellViewModel {
        let title: String
        let imageAssetName: String
        let badgeAssetName: String
    }
}
