//
//  AIChatInputComponents.swift
//  Bugs
//

import InputBarAccessoryView
import UIKit

/// Кнопка отправки: картинка `chat_send` заполняет всю область 48×48 (aspect fill).
final class ChatFullBleedSendButton: InputBarSendButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        imageView?.clipsToBounds = true
        imageView?.contentMode = .scaleAspectFill
        imageView?.frame = bounds
    }
}
