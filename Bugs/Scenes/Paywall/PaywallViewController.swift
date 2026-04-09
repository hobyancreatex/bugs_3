//
//  PaywallViewController.swift
//  Bugs
//

import UIKit

/// Полноэкранный пейвол (модально). После «Next» выставляет премиум и закрывается.
final class PaywallViewController: UIViewController {

    private let contentView = PaywallScreenView(embeddedInOnboarding: false)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        overrideUserInterfaceStyle = .light

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.onCloseTap = { [weak self] in
            self?.dismiss(animated: true)
        }
        contentView.onPrimaryTap = { [weak self] in
            SubscriptionAccess.shared.setPremiumActive(true)
            self?.dismiss(animated: true)
        }
        contentView.onTermsTap = { [weak self] in
            self?.openExternalURL(key: "settings.link.terms")
        }
        contentView.onPrivacyTap = { [weak self] in
            self?.openExternalURL(key: "settings.link.privacy")
        }
        contentView.onRestoreTap = { [weak self] in
            self?.presentRestoreMessage()
        }

        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func openExternalURL(key: String) {
        let s = L10n.string(key)
        guard let url = URL(string: s) else { return }
        UIApplication.shared.open(url)
    }

    private func presentRestoreMessage() {
        let alert = UIAlertController(
            title: L10n.string("settings.row.restore"),
            message: L10n.string("settings.restore.message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.string("common.done"), style: .default))
        present(alert, animated: true)
    }
}
