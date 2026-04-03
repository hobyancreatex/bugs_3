//
//  LibraryGridMetrics.swift
//  Bugs
//

import CoreGraphics
import Foundation

enum LibraryGridMetrics {

    static let columns: CGFloat = 3
    static let interItemSpacing: CGFloat = 28
    static let lineSpacing: CGFloat = 28
    static let sectionHorizontalInset: CGFloat = 16

    /// Width × height with aspect 100 : 77 (same as Home horizontal categories).
    static func cellSize(collectionWidth: CGFloat) -> CGSize {
        guard collectionWidth > 1 else {
            return CGSize(width: 100, height: 77)
        }
        let inner = collectionWidth - sectionHorizontalInset * 2
        let gaps = interItemSpacing * (columns - 1)
        let cellWidth = floor((inner - gaps) / columns)
        let cellHeight = cellWidth * 77 / 100
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
