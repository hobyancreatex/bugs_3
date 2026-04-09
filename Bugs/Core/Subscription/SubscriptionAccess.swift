//
//  SubscriptionAccess.swift
//  Bugs
//

import Foundation

/// Доступ к премиуму: активность = дата окончания в UserDefaults после покупки / restore (см. `SubscriptionManager`).
final class SubscriptionAccess {

    static let shared = SubscriptionAccess()

    static let premiumStatusDidChange = Notification.Name("bugs.subscription.premiumStatusDidChange")

    private init() {}

    var isPremiumActive: Bool {
        SubscriptionManager.shared.isSubscriptionActive
    }

    /// `true` — локально продлить премиум (онбординг и т.п.). `false` — сбросить сохранённую дату.
    func setPremiumActive(_ active: Bool) {
        if active {
            SubscriptionManager.shared.grantLocalPremiumExtension(days: 7)
        } else {
            SubscriptionManager.shared.clearSubscription()
        }
    }
}
