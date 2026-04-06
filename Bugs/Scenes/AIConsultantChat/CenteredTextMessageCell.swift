//
//  CenteredTextMessageCell.swift
//  Bugs
//

import MessageKit
import UIKit

/// Текст сообщения визуально центрируется по вертикали в пузыре (при лишней высоте, например min 51 pt).
final class CenteredTextMessageCell: TextMessageCell {

    private var canonicalTextInsets: UIEdgeInsets = .zero

    public override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            canonicalTextInsets = attributes.messageLabelInsets
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let containerBounds = messageContainerView.bounds
        guard containerBounds.width > 0, containerBounds.height > 0 else { return }

        let base = canonicalTextInsets
        let textWidth = max(0, containerBounds.width - base.left - base.right)
        let measuredHeight = messageLabel.sizeThatFits(
            CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        ).height
        let slack = containerBounds.height - measuredHeight - base.top - base.bottom
        let pad = max(0, slack / 2)
        messageLabel.textInsets = UIEdgeInsets(
            top: base.top + pad,
            left: base.left,
            bottom: base.bottom + pad,
            right: base.right
        )
        messageLabel.setNeedsDisplay()
    }
}
