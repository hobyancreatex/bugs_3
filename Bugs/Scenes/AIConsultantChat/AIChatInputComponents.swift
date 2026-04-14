//
//  AIChatInputComponents.swift
//  Bugs
//

import InputBarAccessoryView
import UIKit

/// Кнопка отправки: картинка `chat_send` заполняет всю область 48×48 (aspect fill).
final class ChatFullBleedSendButton: InputBarSendButton {
    private var normalImage: UIImage?
    private let spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.hidesWhenStopped = true
        v.color = .appTextPrimary
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        imageView?.clipsToBounds = true
        imageView?.contentMode = .scaleAspectFill
        imageView?.frame = bounds
    }

    override func setImage(_ image: UIImage?, for state: UIControl.State) {
        if state == .normal {
            normalImage = image
        }
        super.setImage(image, for: state)
    }

    func setLoading(_ loading: Bool) {
        if loading {
            super.setImage(nil, for: .normal)
            super.setImage(nil, for: .highlighted)
            super.setImage(nil, for: .disabled)
            isUserInteractionEnabled = false
            alpha = 1
            bringSubviewToFront(spinner)
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            super.setImage(normalImage, for: .normal)
            super.setImage(normalImage, for: .highlighted)
            super.setImage(normalImage, for: .disabled)
            isUserInteractionEnabled = true
            alpha = 1
        }
    }
}
