import Foundation
import SwiftyStoreKit
import UIKit

/// Sends subscription receipts and refund consent to the acquisition backend (DarkLocator-style).
final class UserAcquisitionManager: NSObject {

    struct Urls: RawRepresentable {
        var rawValue: String
        static let chkmob = Urls(rawValue: AppConfig.UserAcquisition.baseURL)
        init(rawValue: String) { self.rawValue = rawValue }
    }

    struct EndPoints: RawRepresentable {
        var rawValue: String
        static let receipt = EndPoints(rawValue: "v2/receipt")
        static let pushToken = EndPoints(rawValue: "v2/ios/push_token")
        static let userInfo = EndPoints(rawValue: "v1/ios/user_info")
        init(rawValue: String) { self.rawValue = rawValue }
    }

    static let shared = UserAcquisitionManager()

    var conversionInfo = Info()

    private var apiKey = ""
    private var urlRequest = ""

    private override init() {
        super.init()
        configure(withAPIKey: AppConfig.Secrets.userAcquisitionAPIKey, urlRequest: .chkmob)
    }

    func configure(withAPIKey APIKey: String, urlRequest: Urls) {
        self.apiKey = APIKey
        self.urlRequest = urlRequest.rawValue
    }

    func refundConsent(consented: Bool, completion: ((Bool) -> Void)?) {
        guard AppConfig.Secrets.hasUserAcquisitionAPIKey else {
            #if DEBUG
            print("[UserAcquisition] Missing API key — refundConsent skipped")
            #endif
            completion?(false)
            return
        }
        let secret = AppConfig.Secrets.appStoreSharedSecret
        guard AppConfig.Secrets.hasAppStoreSharedSecret else {
            #if DEBUG
            print("[UserAcquisition] Missing App Store shared secret — refundConsent skipped")
            #endif
            completion?(false)
            return
        }

        let appleReceiptValidator = AppleReceiptValidator(service: .production, sharedSecret: secret)
        SwiftyStoreKit.verifyReceipt(using: appleReceiptValidator) { [self] result in
            switch result {
            case .success(let receipt):
                let params: [String: Any] = [
                    "api_key": apiKey,
                    "original_transaction_ids": extractOriginalTransactionIDs(from: receipt),
                    "customer_consented": consented,
                ]
                requestToServer(params: params, endPoint: .userInfo) { result in
                    completion?(result["error"] == nil)
                }
            case .error:
                completion?(false)
            }
        }
    }

    func logPurchase(of product: SubscriptionProduct) {
        guard AppConfig.Secrets.hasUserAcquisitionAPIKey else {
            #if DEBUG
            print("[UserAcquisition] Missing API key — logPurchase skipped")
            #endif
            return
        }
        var receiptBase64: String?
        let group = DispatchGroup()
        group.enter()
        SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
            switch result {
            case .success(let receiptData):
                receiptBase64 = receiptData.base64EncodedString()
            case .error(let error):
                print("[UserAcquisition] fetchReceipt:", error)
            }
            group.leave()
        }
        group.notify(queue: .global()) { [self] in
            guard let receiptBase64 else { return }
            logPurchase(info: conversionInfo, product: product, receipt: receiptBase64)
        }
    }

    private func extractOriginalTransactionIDs(from receipt: ReceiptInfo) -> [String] {
        var ids: [String] = []
        if let latestReceipts = receipt["latest_receipt_info"] as? [[String: AnyObject]] {
            for receiptInfo in latestReceipts {
                if let originalID = receiptInfo["original_transaction_id"] as? String {
                    ids.append(originalID)
                }
            }
        }
        return Array(Set(ids))
    }

    private func logPurchase(info: Info, product: SubscriptionProduct, receipt: String) {
        let acquisitionSourceLabel: String = {
            switch info.acquisitionSource {
            case .facebook: return "Facebook"
            case .searchAds: return "Search Ads"
            case .organic: return "Organic"
            case let .custom(source): return source
            }
        }()

        // IDFA intentionally omitted (no AdSupport); attribution comes from AppsFlyer / UA payload.
        let idfa = ""

        let priceString = product.priceDecimal.stringValue
        let currencyCode = Locale.current.currency?.identifier ?? ""

        let iap: [String: Any] = [
            "product_id": product.id,
            "price": priceString,
            "currency": currencyCode,
        ]

        var extra: [String: Any] = [
            "acquisition_source": acquisitionSourceLabel,
            "acquisition_date": Int(info.acquisitionDate.timeIntervalSince1970),
            "ad_campaign": info.adCampaign,
            "ad_group": info.adGroup,
            "ad_creative": info.adCreative,
            "vendor_id": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "appsflyer_id": info.appsFlyerId,
            "appmetrica_device_id": info.appmetricaId,
            "amplitude_device_id": info.amplitudeId,
            "adjust_raw": info.adjustRaw,
            "appsflyer_raw": info.appsFlyerRaw,
            "searchads_raw": info.searchAdsRaw,
            "branch_raw": info.branchRaw,
            "fb_anonymous_id": info.fbAnonymousId,
        ]
        for (k, v) in info.extra { extra[k] = v }

        let params: [String: Any] = [
            "bundle_id": Bundle.main.bundleIdentifier ?? "",
            "afi": idfa,
            "receipt": receipt,
            "iap": iap,
            "country": Locale.current.region?.identifier ?? "",
            "extra": extra,
            "api_key": apiKey,
        ]
        requestToServer(params: params, endPoint: .receipt, completion: nil)
    }

    private func requestToServer(
        params: [String: Any],
        endPoint: EndPoints,
        completion: (([String: Any]) -> Void)?
    ) {
        guard let url = URL(string: urlRequest + endPoint.rawValue) else {
            completion?(["error": "Invalid URL"])
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        guard let body = try? JSONSerialization.data(withJSONObject: params) else {
            completion?(["error": "Encoding failed"])
            return
        }
        request.httpBody = body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, resp, error in
            if error != nil {
                completion?(["error": "network"])
                return
            }
            guard let http = resp as? HTTPURLResponse else {
                completion?(["error": "response"])
                return
            }
            if (200 ... 299).contains(http.statusCode),
               let data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion?(json)
            } else {
                completion?(["error": "Failure"])
            }
        }
        .resume()
    }
}

extension UserAcquisitionManager {
    /// Reference type so AppsFlyer delegate updates persist on `shared` (struct copy-on-write would drop mutations).
    final class Info {
        enum AcquisitionSource {
            case organic, facebook, searchAds, custom(String)
        }

        var userId: String?
        var acquisitionSource: AcquisitionSource = .organic
        var acquisitionDate = Date()
        var adCampaign = ""
        var adGroup = ""
        var adCreative = ""
        var appsFlyerId = ""
        var appmetricaId = ""
        var amplitudeId = ""
        var fbAnonymousId = ""
        var adjustRaw = ""
        var appsFlyerRaw = ""
        var searchAdsRaw = ""
        var branchRaw = ""
        var extra = [String: Any]()

        func setAppsFlyerData(_ appsFlyerData: [String: Any]) {
            if let jsonData = try? JSONSerialization.data(withJSONObject: appsFlyerData, options: .prettyPrinted) {
                appsFlyerRaw = String(data: jsonData, encoding: .utf8) ?? ""
            }

            let status = appsFlyerData["af_status"] as? String ?? ""
            let source = appsFlyerData["media_source"] as? String ?? ""
            let campaign = appsFlyerData["campaign"] as? String ?? ""
            let campaignId = appsFlyerData["campaign_id"] as? String ?? ""
            let adSet = appsFlyerData["adset"] as? String ?? ""
            let adSetId = appsFlyerData["adset_id"] as? String ?? ""
            let ad = appsFlyerData["ad"] as? String ?? ""
            let adId = appsFlyerData["ad_id"] as? String ?? ""

            let acquisitionSource: AcquisitionSource = {
                switch status {
                case "Non-organic":
                    switch source {
                    case "Facebook Ads": return .facebook
                    default: return .custom(source)
                    }
                case "Organic": return .organic
                default: return .custom("Undefined")
                }
            }()

            let acquisitionDate: Date = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-DD mm:HH:ss.SSS"
                return formatter.date(from: appsFlyerData["install_time"] as? String ?? "") ?? Date()
            }()

            func merged(_ str1: String, _ str2: String) -> String {
                str2.isEmpty ? str1 : "\(str1) (\(str2))"
            }

            self.acquisitionSource = acquisitionSource
            self.acquisitionDate = acquisitionDate
            self.adCampaign = merged(campaign, campaignId)
            self.adGroup = merged(adSet, adSetId)
            self.adCreative = merged(ad, adId)
        }
    }
}
