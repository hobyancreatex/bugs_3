//
//  PaywallViewController.swift
//  Bugs
//

import UIKit

/// Заглушка пейвола: после «Подписаться» выставляет премиум и закрывается.
final class PaywallViewController: UIViewController {

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle(L10n.string("paywall.close"), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.setTitleColor(.appReadMore, for: .normal)
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .appTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.text = L10n.string("paywall.title")
        return l
    }()

    private let subscribeButton: GradientRoundedCTAControl = {
        let b = GradientRoundedCTAControl()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle(L10n.string("paywall.subscribe"), for: .normal)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        overrideUserInterfaceStyle = .light

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        subscribeButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)

        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(subscribeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subscribeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 46),
            subscribeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -46),
            subscribeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            subscribeButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
    }

    @objc
    private func subscribeTapped() {
        SubscriptionAccess.shared.setPremiumActive(true)
        dismiss(animated: true)
    }
}
