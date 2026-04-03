//
//  LibraryCompositionalLayoutBuilder.swift
//  Bugs
//

import UIKit

enum LibraryCompositionalLayoutBuilder {

    /// Ровно 3 ячейки в ряд: `UICollectionViewFlowLayout` с self-sizing мог отдавать 2 колонки из‑за подбора размера ячеек.
    static func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            section(environment: environment)
        }
    }

    private static func section(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let containerWidth = environment.container.effectiveContentSize.width
        let size = LibraryGridMetrics.cellSize(collectionWidth: containerWidth)
        let itemW = size.width
        let itemH = size.height

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemW),
            heightDimension: .absolute(itemH)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(itemH)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item, item, item]
        )
        group.interItemSpacing = .fixed(LibraryGridMetrics.interItemSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = LibraryGridMetrics.lineSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: LibraryGridMetrics.sectionHorizontalInset,
            bottom: 0,
            trailing: LibraryGridMetrics.sectionHorizontalInset
        )
        return section
    }
}
