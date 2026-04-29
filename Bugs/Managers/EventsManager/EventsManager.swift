import Foundation

enum SubscriptionPurchaseSource {
    case onboarding
    case inAppPaywall
}

final class EventsManager {

    static let shared = EventsManager()

    private let firebase = FirebaseEventsService()
    private let appsFlyer = AppsFlyerEventsService()

    private init() {}

    func logEvent(_ event: Event, parameters: [String: Any]? = nil) {
        let name = event.rawValue
        firebase.logEvent(name: name, parameters: parameters)
        appsFlyer.logEvent(name: name, parameters: parameters)
        #if DEBUG
        print("EVENT:", name, parameters ?? [:])
        #endif
    }

    func logEvent(name: String, parameters: [String: Any]? = nil) {
        firebase.logEvent(name: name, parameters: parameters)
        appsFlyer.logEvent(name: name, parameters: parameters)
        #if DEBUG
        print("EVENT:", name, parameters ?? [:])
        #endif
    }

    /// After a successful subscription purchase (Firebase + AppsFlyer + User Acquisition receipt).
    @MainActor
    func recordSubscriptionPurchase(product: SubscriptionProduct, source: SubscriptionPurchaseSource) {
        UserAcquisitionManager.shared.logPurchase(of: product)
        logEvent(.subscription_done_all)
        appsFlyer.logPurchase(productId: product.id)

        switch source {
        case .onboarding:
            logEvent(.subscription_done_purchased_onboarding)
        case .inAppPaywall:
            logEvent(.subscription_done_inapp_all)
        }

        let productId = product.id
        if productId.contains("week") {
            logEvent(.paywall_subscribe_week)
        } else if productId.contains("3month") {
            logEvent(.subscription_done_3month)
            logEvent(.subscription_done_three_month)
        } else if productId.contains("1year") {
            logEvent(.subscription_done_1year)
            logEvent(.subscription_done_year)
        }
    }

    enum Event: String, CaseIterable {
        case subscription_done_all
        case subscription_done_purchased_onboarding
        case subscription_done_inapp_all
        case paywall_subscribe_week
        case subscription_done_3month
        case subscription_done_three_month
        case subscription_done_1year
        case subscription_done_year
    }
}
