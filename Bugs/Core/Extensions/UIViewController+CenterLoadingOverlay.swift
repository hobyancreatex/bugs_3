//
//  UIViewController+CenterLoadingOverlay.swift
//  Bugs
//

import UIKit

private enum CenterLoadingOverlay {
    static let tag = 9_090_909
}

extension UIViewController {

    /// Полноэкранный полупрозрачный фон и `UIActivityIndicatorView` по центру.
    func showCenterLoadingOverlay() {
        guard view.viewWithTag(CenterLoadingOverlay.tag) == nil else { return }

        let cover = UIView()
        cover.tag = CenterLoadingOverlay.tag
        cover.translatesAutoresizingMaskIntoConstraints = false
        cover.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        cover.isUserInteractionEnabled = true

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .appTextPrimary
        spinner.startAnimating()

        cover.addSubview(spinner)
        view.addSubview(cover)

        NSLayoutConstraint.activate([
            cover.topAnchor.constraint(equalTo: view.topAnchor),
            cover.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cover.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cover.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: cover.centerYAnchor),
        ])

        cover.alpha = 0
        UIView.animate(withDuration: 0.2) {
            cover.alpha = 1
        }
    }

    func hideCenterLoadingOverlay() {
        guard let cover = view.viewWithTag(CenterLoadingOverlay.tag) else { return }
        UIView.animate(withDuration: 0.15, animations: {
            cover.alpha = 0
        }, completion: { _ in
            cover.removeFromSuperview()
        })
    }
}
