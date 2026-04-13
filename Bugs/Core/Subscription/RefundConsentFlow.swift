import UIKit

/// Refund / purchase-data consent alert → `UserAcquisitionManager.refundConsent` (DarkLocator paywall flow).
enum RefundConsentFlow {

    @MainActor
    static func present(from viewController: UIViewController, onFinished: @escaping () -> Void) {
        let alert = UIAlertController(
            title: nil,
            message: L10n.string("settings.refund_consent.message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.string("settings.refund_consent.allow"), style: .default) { _ in
            sendConsent(true, onFinished: onFinished)
        })
        alert.addAction(UIAlertAction(title: L10n.string("settings.refund_consent.decline"), style: .cancel) { _ in
            sendConsent(false, onFinished: onFinished)
        })
        viewController.present(alert, animated: true)
    }

    private static func sendConsent(_ consented: Bool, onFinished: @escaping () -> Void) {
        UserAcquisitionManager.shared.refundConsent(consented: consented) { _ in
            DispatchQueue.main.async {
                onFinished()
            }
        }
    }
}
