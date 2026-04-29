//
//  PaywallViewController.swift
//  Bugs
//

import UIKit

/// Полноэкранный пейвол (модально). Покупка и restore через `SubscriptionManager`.
final class PaywallViewController: UIViewController {

    private let contentView = PaywallScreenView(embeddedInOnboarding: false)
    private var didLogInAppPaywallShown = false

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
            self?.openExternalURL(AppConfig.Marketing.termsOfUseURL)
        }
        contentView.onPrivacyTap = { [weak self] in
            self?.openExternalURL(AppConfig.Marketing.privacyPolicyURL)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didLogInAppPaywallShown else { return }
        didLogInAppPaywallShown = true
        EventsManager.shared.logEvent(.paywall_inapp_displayed)
    }

    private func openExternalURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    @MainActor
    private func performPurchase() async {
        guard NetworkReachability.shared.isConnected else {
            UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
            return
        }
        contentView.setPurchaseInProgress(true)
        showCenterLoadingOverlay()

        do {
            let products = try await SubscriptionManager.shared.loadSubscriptionProducts()
            guard let product = products.first else {
                hideCenterLoadingOverlay()
                contentView.setPurchaseInProgress(false)
                presentAlert(titleKey: "subscription.error.title", messageKey: "subscription.error.product_unavailable")
                return
            }
            try await SubscriptionManager.shared.purchase(product)
            hideCenterLoadingOverlay()
            contentView.setPurchaseInProgress(false)
            EventsManager.shared.recordSubscriptionPurchase(product: product, source: .inAppPaywall)
            RefundConsentFlow.present(from: self) { [weak self] in
                self?.dismiss(animated: true)
            }
        } catch SubscriptionManagerError.userCancelled {
            hideCenterLoadingOverlay()
            contentView.setPurchaseInProgress(false)
        } catch {
            hideCenterLoadingOverlay()
            contentView.setPurchaseInProgress(false)
            UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
        }
    }

    @MainActor
    private func performRestore() async {
        guard NetworkReachability.shared.isConnected else {
            UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
            return
        }
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
            UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
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
