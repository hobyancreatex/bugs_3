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
        let displayTitle: String
        let categoryRoutingKey: String
        let imageAssetName: String
        let imageURL: URL?
    }

    struct CategoryCellViewModel {
        let title: String
        /// Ключ для перехода в список (slug / id / legacy localization key).
        let categoryLocalizationKey: String
        let imageAssetName: String
        let imageURL: URL?
    }

    struct PopularInsectItemResponse {
        let displayTitle: String
        let imageAssetName: String
        let badgeAssetName: String
        let imageURL: URL?
    }

    struct PopularInsectCellViewModel {
        let title: String
        let imageAssetName: String
        let badgeAssetName: String
        let imageURL: URL?
    }

    struct ArticleDetailBlockResponse {
        let sectionTitle: String?
        let body: String
    }

    struct ArticleItemResponse {
        let displayTitle: String
        let displaySubtitle: String
        let imageAssetName: String
        let coverImageURL: URL?
        let blocks: [ArticleDetailBlockResponse]
    }

    struct ArticleDetailViewModel {
        let title: String
        let subtitle: String
        let heroImageAssetName: String
        let heroImageURL: URL?
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
        let coverImageURL: URL?
        let detail: ArticleDetailViewModel
    }
}
