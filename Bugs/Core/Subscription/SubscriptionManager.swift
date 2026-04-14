//
//  SubscriptionManager.swift
//  Bugs
//

import Foundation
import StoreKit
import SwiftyStoreKit

enum SubscriptionManagerError: Error {
    case productNotFound
    case userCancelled
    case purchaseFailed
    case restoreFailed
}

struct SubscriptionProduct {
    let id: String
    let displayPrice: String
    let priceDecimal: NSDecimalNumber
}

/// Подписки на StoreKit1 (SwiftyStoreKit), статус храним локально в UserDefaults.
@MainActor
final class SubscriptionManager {

    static let shared = SubscriptionManager()

    private let expiryKey = "bugs.subscription.expiryDate"
    private let legacyPremiumKey = "bugs.subscription.isPremiumActive"

    private init() {
        migrateLegacyIfNeeded()
        completePendingTransactionsOnLaunch()
    }

    // MARK: - Status (UserDefaults)

    var subscriptionExpiryDate: Date? {
        let t = UserDefaults.standard.double(forKey: expiryKey)
        guard t > 0 else { return nil }
        return Date(timeIntervalSince1970: t)
    }

    var isSubscriptionActive: Bool {
        guard let end = subscriptionExpiryDate else { return false }
        return end > Date()
    }

    @discardableResult
    func checkSubscriptionStatus() -> Bool {
        isSubscriptionActive
    }

    func clearSubscription() {
        UserDefaults.standard.removeObject(forKey: expiryKey)
        NotificationCenter.default.post(name: SubscriptionAccess.premiumStatusDidChange, object: nil)
    }

    /// Локальное продление (онбординг / отладка), без чека App Store.
    func grantLocalPremiumExtension(days: Int) {
        let days = max(1, days)
        let now = Date()
        let currentEnd = subscriptionExpiryDate ?? now
        let base = max(currentEnd, now)
        let end =
            Calendar.current.date(byAdding: .day, value: days, to: base)
            ?? base.addingTimeInterval(Double(days) * 86400)
        UserDefaults.standard.set(end.timeIntervalSince1970, forKey: expiryKey)
        NotificationCenter.default.post(name: SubscriptionAccess.premiumStatusDidChange, object: nil)
    }

    // MARK: - Products

    func loadSubscriptionProducts() async throws -> [SubscriptionProduct] {
        let ids = Set([PaywallConfiguration.subscriptionProductID])
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[SubscriptionProduct], Error>) in
            SwiftyStoreKit.retrieveProductsInfo(ids) { result in
                if let error = result.error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let product = result.retrievedProducts.first else {
                    continuation.resume(throwing: SubscriptionManagerError.productNotFound)
                    return
                }
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = product.priceLocale
                let price = formatter.string(from: product.price) ?? "—"
                continuation.resume(returning: [
                    SubscriptionProduct(id: product.productIdentifier, displayPrice: price, priceDecimal: product.price),
                ])
            }
        }
    }

    // MARK: - Purchase & restore

    func purchase(_ product: SubscriptionProduct) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            SwiftyStoreKit.purchaseProduct(product.id, atomically: true) { [weak self] result in
                guard let self else {
                    continuation.resume(throwing: SubscriptionManagerError.purchaseFailed)
                    return
                }
                switch result {
                case .success:
                    self.grantLocalPremiumExtension(days: 7)
                    continuation.resume(returning: ())
                case .error(let error):
                    if error.code == .paymentCancelled {
                        continuation.resume(throwing: SubscriptionManagerError.userCancelled)
                    } else {
                        continuation.resume(throwing: SubscriptionManagerError.purchaseFailed)
                    }
                @unknown default:
                    continuation.resume(throwing: SubscriptionManagerError.purchaseFailed)
                }
            }
        }
    }

    func restorePurchases() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            SwiftyStoreKit.restorePurchases(atomically: true) { [weak self] results in
                guard let self else {
                    continuation.resume(throwing: SubscriptionManagerError.restoreFailed)
                    return
                }
                if results.restoreFailedPurchases.isEmpty && results.restoredPurchases.isEmpty {
                    continuation.resume(returning: ())
                    return
                }
                if !results.restoredPurchases.isEmpty {
                    self.grantLocalPremiumExtension(days: 7)
                    continuation.resume(returning: ())
                    return
                }
                continuation.resume(throwing: SubscriptionManagerError.restoreFailed)
            }
        }
    }

    func refreshEntitlementsIntoUserDefaults() async {
        _ = checkSubscriptionStatus()
    }

    // MARK: - Private

    private func migrateLegacyIfNeeded() {
        guard UserDefaults.standard.object(forKey: legacyPremiumKey) != nil else { return }
        let wasPremium = UserDefaults.standard.bool(forKey: legacyPremiumKey)
        UserDefaults.standard.removeObject(forKey: legacyPremiumKey)
        guard wasPremium, subscriptionExpiryDate == nil else { return }
        grantLocalPremiumExtension(days: 7)
    }

    private func completePendingTransactionsOnLaunch() {
        SwiftyStoreKit.completeTransactions(atomically: true) { [weak self] purchases in
            guard let self else { return }
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    self.grantLocalPremiumExtension(days: 7)
                default:
                    break
                }
            }
        }
    }

    // StoreKit1 mode: local expiry is updated on purchase/restore.
}
