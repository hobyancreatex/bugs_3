//
//  UserFacingRequestErrorAlert.swift
//  Bugs
//

import UIKit

/// Generic API / network failure message (localized).
enum UserFacingRequestErrorAlert {

    @MainActor
    static func presentTryAgainLater(
        from viewController: UIViewController? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let host = viewController ?? topViewController()
        guard let host else { return }
        let alert = UIAlertController(
            title: L10n.string("common.error.title"),
            message: L10n.string("common.error.try_later"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.string("common.done"), style: .default) { _ in
            onDismiss?()
        })
        findPresenter(from: host).present(alert, animated: true)
    }

    @MainActor
    private static func findPresenter(from base: UIViewController) -> UIViewController {
        if let presented = base.presentedViewController {
            return findPresenter(from: presented)
        }
        if let nav = base as? UINavigationController, let visible = nav.visibleViewController {
            return findPresenter(from: visible)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return findPresenter(from: selected)
        }
        return base
    }

    @MainActor
    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let baseVC: UIViewController? = {
            if let base { return base }
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
        }()
        guard let baseVC else { return nil }
        if let presented = baseVC.presentedViewController {
            return topViewController(base: presented)
        }
        if let nav = baseVC as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = baseVC as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        return baseVC
    }
}
