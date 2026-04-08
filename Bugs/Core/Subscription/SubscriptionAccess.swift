//
//  SubscriptionAccess.swift
//  Bugs
//

import Foundation

/// Доступ к премиум-контенту. Заглушка на UserDefaults — позже подключить StoreKit / сервер.
final class SubscriptionAccess {

    static let shared = SubscriptionAccess()

    static let premiumStatusDidChange = Notification.Name("bugs.subscription.premiumStatusDidChange")

    private let premiumKey = "bugs.subscription.isPremiumActive"

    private init() {}

    var isPremiumActive: Bool {
        UserDefaults.standard.bool(forKey: premiumKey)
    }

    /// После успешной покупки / восстановления из пейвола или StoreKit.
    func setPremiumActive(_ active: Bool) {
        UserDefaults.standard.set(active, forKey: premiumKey)
        NotificationCenter.default.post(name: Self.premiumStatusDidChange, object: nil)
    }
}
