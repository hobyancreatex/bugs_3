//
//  ContentLoadingOverlayView.swift
//  Bugs
//

import UIKit

/// Центрированный индикатор загрузки контента (компактный `.medium`) — для главной, библиотеки и других экранов.
final class ContentLoadingOverlayView: UIView {

    private let indicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.hidesWhenStopped = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true
        addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setActive(_ active: Bool) {
        isHidden = !active
        if active {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }
    }
}
