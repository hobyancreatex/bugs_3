import AppsFlyerLib
import Foundation
import StoreKit

final class AppsFlyerEventsService: NSObject, EventServiceProtocol, AppsFlyerLibDelegate {

    private let isConfigured: Bool

    override init() {
        let key = AppConfig.AppsFlyer.devKey
        let appId = AppConfig.AppsFlyer.appleAppID
        let ok = key != "YOUR_APPSFLYER_DEV_KEY" && appId != "YOUR_APP_STORE_NUMERIC_ID"
        self.isConfigured = ok
        super.init()
        guard ok else {
            #if DEBUG
            print("[AppsFlyer] Missing devKey or appleAppID — SDK not started")
            #endif
            return
        }
        let af = AppsFlyerLib.shared()
        af.delegate = self
        af.appsFlyerDevKey = key
        af.appleAppID = appId
        af.waitForATTUserAuthorization(timeoutInterval: 60)
        af.start()
    }

    func logEvent(name: String, parameters: [String: Any]?) {
        guard isConfigured else { return }
        AppsFlyerLib.shared().logEvent(name, withValues: parameters)
    }

    func logPurchase(product _: Product) {
        guard isConfigured else { return }
        AppsFlyerLib.shared().logEvent(AFEventPurchase, withValues: ["eventValue": ""])
    }

    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        guard let data = conversionInfo as? [String: Any] else { return }
        UserAcquisitionManager.shared.conversionInfo.setAppsFlyerData(data)
        UserAcquisitionManager.shared.conversionInfo.appsFlyerId = AppsFlyerLib.shared().getAppsFlyerUID()
    }

    func onConversionDataFail(_ error: Error) {}
}
