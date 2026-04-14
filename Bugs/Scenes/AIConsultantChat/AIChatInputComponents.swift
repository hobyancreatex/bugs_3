//
//  AIChatInputComponents.swift
//  Bugs
//

import InputBarAccessoryView
import UIKit

/// Кнопка отправки: картинка `chat_send` заполняет всю область 48×48 (aspect fill).
final class ChatFullBleedSendButton: InputBarSendButton {
    private let spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.hidesWhenStopped = true
        v.color = .white
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

    func setLoading(_ loading: Bool) {
        if loading {
            imageView?.alpha = 0
            isEnabled = false
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            imageView?.alpha = 1
            isEnabled = true
        }
    }
}
