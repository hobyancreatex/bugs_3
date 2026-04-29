import Foundation
import ObjectiveC.runtime
import UIKit

/// Automatically emits `view_<screen>` for app view controllers.
enum ScreenViewAutoTracker {
    private static var isInstalled = false

    static func install() {
        guard !isInstalled else { return }
        isInstalled = true

        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        let swizzledSelector = #selector(UIViewController.bugs_viewDidAppearForScreenTracking(_:))

        guard
            let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

private extension UIViewController {
    @objc
    func bugs_viewDidAppearForScreenTracking(_ animated: Bool) {
        // Calls original implementation because methods are exchanged.
        bugs_viewDidAppearForScreenTracking(animated)
        logAutomaticScreenViewEventIfNeeded()
    }

    func logAutomaticScreenViewEventIfNeeded() {
        guard Bundle(for: type(of: self)) == .main else { return }
        guard !(self is UIAlertController) else { return }

        let className = String(describing: type(of: self))
        guard className.hasSuffix("ViewController") else { return }

        // Keep dedicated onboarding funnel events as the source of truth there.
        guard className != "OnboardingViewController" else { return }

        let stem = String(className.dropLast("ViewController".count))
        let eventName = "view_" + stem.snakeCasedForAnalyticsEvent()
        EventsManager.shared.logEvent(name: eventName)
    }
}

private extension String {
    func snakeCasedForAnalyticsEvent() -> String {
        guard !isEmpty else { return self }
        var out = ""
        for (idx, ch) in enumerated() {
            if ch.isUppercase && idx > 0 { out.append("_") }
            out.append(ch.lowercased())
        }
        return out
    }
}
