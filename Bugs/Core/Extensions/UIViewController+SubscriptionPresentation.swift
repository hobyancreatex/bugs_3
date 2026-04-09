//
//  UIViewController+SubscriptionPresentation.swift
//  Bugs
//

import UIKit

extension UIViewController {

    /// Перечитывает локальный статус подписки (дата в UserDefaults). Вызывать из `viewWillAppear`, чтобы UI совпадал после покупки.
    func applySubscriptionStatusForAppearance() {
        _ = SubscriptionManager.shared.checkSubscriptionStatus()
    }

    func presentPaywallFullScreen(animated: Bool = true) {
        let paywall = PaywallViewController()
        paywall.modalPresentationStyle = .fullScreen
        present(paywall, animated: animated)
    }
}
