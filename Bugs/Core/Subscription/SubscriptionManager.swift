//
//  SubscriptionManager.swift
//  Bugs
//

import Foundation
import StoreKit

enum SubscriptionManagerError: Error {
    case productNotFound
    case userCancelled
    case pending
    case unverifiedTransaction
    case unknownPurchaseResult
}

/// Подписки: загрузка продуктов, покупка, restore, статус по дате окончания в UserDefaults (как в IAPManager по смыслу).
@MainActor
final class SubscriptionManager {

    static let shared = SubscriptionManager()

    private let expiryKey = "bugs.subscription.expiryDate"
    private let legacyPremiumKey = "bugs.subscription.isPremiumActive"

    private var transactionListener: Task<Void, Never>?

    private init() {
        migrateLegacyIfNeeded()
        transactionListener = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
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

    func loadSubscriptionProducts() async throws -> [Product] {
        let ids = [PaywallConfiguration.subscriptionProductID]
        return try await Product.products(for: ids)
    }

    // MARK: - Purchase & restore

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await persistExpiry(from: transaction, product: product)
            await transaction.finish()
        case .userCancelled:
            throw SubscriptionManagerError.userCancelled
        case .pending:
            throw SubscriptionManagerError.pending
        @unknown default:
            throw SubscriptionManagerError.unknownPurchaseResult
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await syncExpirationsFromCurrentEntitlements()
    }

    /// Синхронизация с активными entitlement (удобно при старте приложения).
    func refreshEntitlementsIntoUserDefaults() async {
        await syncExpirationsFromCurrentEntitlements()
    }

    // MARK: - Private

    private func migrateLegacyIfNeeded() {
        guard UserDefaults.standard.object(forKey: legacyPremiumKey) != nil else { return }
        let wasPremium = UserDefaults.standard.bool(forKey: legacyPremiumKey)
        UserDefaults.standard.removeObject(forKey: legacyPremiumKey)
        guard wasPremium, subscriptionExpiryDate == nil else { return }
        grantLocalPremiumExtension(days: 7)
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                guard transaction.productID == PaywallConfiguration.subscriptionProductID else {
                    await transaction.finish()
                    continue
                }
                await persistExpiry(from: transaction, product: nil)
                await transaction.finish()
            } catch {
                continue
            }
        }
    }

    private func syncExpirationsFromCurrentEntitlements() async {
        var best: Date?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == PaywallConfiguration.subscriptionProductID else { continue }
            if let exp = transaction.expirationDate {
                best = max(best ?? exp, exp)
            } else {
                let inferred = inferredExpiry(from: transaction, product: nil)
                best = max(best ?? inferred, inferred)
            }
        }
        if let best {
            UserDefaults.standard.set(best.timeIntervalSince1970, forKey: expiryKey)
            NotificationCenter.default.post(name: SubscriptionAccess.premiumStatusDidChange, object: nil)
        }
    }

    private func persistExpiry(from transaction: Transaction, product: Product?) async {
        let end = transaction.expirationDate ?? inferredExpiry(from: transaction, product: product)
        UserDefaults.standard.set(end.timeIntervalSince1970, forKey: expiryKey)
        NotificationCenter.default.post(name: SubscriptionAccess.premiumStatusDidChange, object: nil)
    }

    private func inferredExpiry(from transaction: Transaction, product: Product?) -> Date {
        if let product, let sub = product.subscription {
            let days = calendarDaysApproximation(sub.subscriptionPeriod)
            return transaction.purchaseDate.addingTimeInterval(Double(days) * 86400)
        }
        return transaction.purchaseDate.addingTimeInterval(7 * 86400)
    }

    private func calendarDaysApproximation(_ period: Product.SubscriptionPeriod) -> Int {
        switch period.unit {
        case .day: return period.value
        case .week: return 7 * period.value
        case .month: return 30 * period.value
        case .year: return 365 * period.value
        @unknown default: return 7
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
