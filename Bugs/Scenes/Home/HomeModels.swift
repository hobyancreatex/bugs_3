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
        let insectId: String?
        let displayTitle: String
        let imageAssetName: String
        let badgeAssetName: String
        let imageURL: URL?
    }

    struct PopularInsectCellViewModel {
        let insectId: String?
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
        let articleId: String?
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

        init(title: String, subtitle: String, heroImageAssetName: String, heroImageURL: URL?, blocks: [Block]) {
            self.title = title
            self.subtitle = subtitle
            self.heroImageAssetName = heroImageAssetName
            self.heroImageURL = heroImageURL
            self.blocks = blocks
        }

        init(from item: ArticleItemResponse) {
            let detailBlocks = item.blocks.map { Block(sectionTitle: $0.sectionTitle, body: $0.body) }
            var subtitle = item.displaySubtitle
            // Пустой `parts`: описание уходит и в subtitle, и в единственный блок — на экране дублируется.
            if detailBlocks.count == 1, detailBlocks[0].sectionTitle == nil {
                let body = detailBlocks[0].body
                if body == subtitle
                    || body.trimmingCharacters(in: .whitespacesAndNewlines)
                    == subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
                {
                    subtitle = ""
                }
            }
            self.init(
                title: item.displayTitle,
                subtitle: subtitle,
                heroImageAssetName: item.imageAssetName,
                heroImageURL: item.coverImageURL,
                blocks: detailBlocks
            )
        }
    }

    struct ArticleCellViewModel {
        let articleId: String?
        let title: String
        let subtitle: String
        let imageAssetName: String
        let coverImageURL: URL?
        let detail: ArticleDetailViewModel
    }
}
