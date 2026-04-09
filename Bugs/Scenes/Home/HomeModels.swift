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
            let articles: [ArticleItemResponse]
        }
        struct ViewModel {
            let title: String
            let searchPlaceholder: String
            let bannerTitle: String
            let bannerButtonTitle: String
            let categories: [CategoryCellViewModel]
            let popularSectionTitle: String
            let popularInsects: [PopularInsectCellViewModel]
            let articlesSectionTitle: String
            let articles: [ArticleCellViewModel]
        }
    }

    struct CategoryItemResponse {
        let titleLocalizationKey: String
        let imageAssetName: String
    }

    struct CategoryCellViewModel {
        let title: String
        let categoryLocalizationKey: String
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

    struct ArticleDetailBlockResponse {
        let titleLocalizationKey: String?
        let bodyLocalizationKey: String
    }

    struct ArticleItemResponse {
        let titleLocalizationKey: String
        let subtitleLocalizationKey: String
        let imageAssetName: String
        let blocks: [ArticleDetailBlockResponse]
    }

    struct ArticleDetailViewModel {
        let title: String
        let subtitle: String
        let heroImageAssetName: String
        let blocks: [Block]
        struct Block {
            let sectionTitle: String?
            let body: String
        }
    }

    struct ArticleCellViewModel {
        let title: String
        let subtitle: String
        let imageAssetName: String
        let detail: ArticleDetailViewModel
    }
}
