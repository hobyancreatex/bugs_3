//
//  PaywallViewController.swift
//  Bugs
//

import StoreKit
import UIKit

/// Полноэкранный пейвол (модально). Покупка и restore через `SubscriptionManager`.
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
            Task { await self?.performPurchase() }
        }
        contentView.onTermsTap = { [weak self] in
            self?.openExternalURL(key: "settings.link.terms")
        }
        contentView.onPrivacyTap = { [weak self] in
            self?.openExternalURL(key: "settings.link.privacy")
        }
        contentView.onRestoreTap = { [weak self] in
            Task { await self?.performRestore() }
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

    @MainActor
    private func performPurchase() async {
        contentView.setPurchaseInProgress(true)
        showCenterLoadingOverlay()
        defer {
            hideCenterLoadingOverlay()
            contentView.setPurchaseInProgress(false)
        }

        do {
            let products = try await SubscriptionManager.shared.loadSubscriptionProducts()
            guard let product = products.first else {
                presentAlert(titleKey: "subscription.error.title", messageKey: "subscription.error.product_unavailable")
                return
            }
            try await SubscriptionManager.shared.purchase(product)
            dismiss(animated: true)
        } catch SubscriptionManagerError.userCancelled {
            return
        } catch SubscriptionManagerError.pending {
            presentAlert(titleKey: "subscription.pending.title", messageKey: "subscription.pending.message")
        } catch {
            presentAlert(titleKey: "subscription.error.title", messageKey: "subscription.error.purchase_failed")
        }
    }

    @MainActor
    private func performRestore() async {
        contentView.setPurchaseInProgress(true)
        showCenterLoadingOverlay()
        defer {
            hideCenterLoadingOverlay()
            contentView.setPurchaseInProgress(false)
        }

        do {
            try await SubscriptionManager.shared.restorePurchases()
            if SubscriptionManager.shared.isSubscriptionActive {
                presentAlert(titleKey: "subscription.restore.title", messageKey: "subscription.restore.success", dismissSelf: true)
            } else {
                presentAlert(titleKey: "subscription.restore.title", messageKey: "subscription.restore.nothing")
            }
        } catch {
            presentAlert(titleKey: "subscription.error.title", messageKey: "subscription.error.restore_failed")
        }
    }

    private func presentAlert(titleKey: String, messageKey: String, dismissSelf: Bool = false) {
        let alert = UIAlertController(
            title: L10n.string(titleKey),
            message: L10n.string(messageKey),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.string("common.done"), style: .default) { [weak self] _ in
            if dismissSelf {
                self?.dismiss(animated: true)
            }
        })
        present(alert, animated: true)
    }
}
