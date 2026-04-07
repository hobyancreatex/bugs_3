//
//  ScannerViewportLayout.swift
//  Bugs
//

import UIKit

/// Геометрия выреза под распознавание: только расчёт фрейма, без привязки к другим вью.
enum ScannerViewportLayout {

    static let sideInset: CGFloat = 24
    static let cornerRadius: CGFloat = 60
    /// Вертикальные поля над/под вырезом в пропорции 2 : 3 (сверху меньше).
    static let topMarginWeight: CGFloat = 2
    static let bottomMarginWeight: CGFloat = 3

    /// `bottomReserved` — зона под нижние кнопки и отступы (от низа bounds вверх).
    static func cutoutFrame(in bounds: CGRect, safeArea: UIEdgeInsets, bottomReserved: CGFloat) -> CGRect {
        let usableTop = bounds.minY + safeArea.top
        let usableBottom = bounds.maxY - safeArea.bottom - bottomReserved
        let usableHeight = max(0, usableBottom - usableTop)
        let cutoutWidth = bounds.width - 2 * sideInset
        let cutoutHeight = cutoutWidth
        guard cutoutHeight <= usableHeight, cutoutWidth > 0 else {
            return .zero
        }
        let verticalRemainder = usableHeight - cutoutHeight
        let sum = topMarginWeight + bottomMarginWeight
        let topMargin = verticalRemainder * (topMarginWeight / sum)
        let x = sideInset
        let y = usableTop + topMargin
        return CGRect(x: x, y: y, width: cutoutWidth, height: cutoutHeight)
    }
}
