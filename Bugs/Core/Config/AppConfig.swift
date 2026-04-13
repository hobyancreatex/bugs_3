import Foundation

/// URLs and third-party keys. Replace with your values (xcconfig / Info.plist in production).
enum AppConfig {

    enum UserAcquisition {
        /// Base URL for chkmob-style receipt & consent API (same pattern as DarkLocator).
        static let baseURL = "https://dash.chkmob.com/"
    }

    enum Secrets {
        /// Dashboard API key (User Acquisition).
        static let userAcquisitionAPIKey = "YOUR_CHKMOB_API_KEY"
        /// App Store Connect → App → App-Specific Shared Secret (for receipt verification).
        static let appStoreSharedSecret = "YOUR_APP_STORE_SHARED_SECRET"
    }

    enum AppsFlyer {
        static let devKey = "YOUR_APPSFLYER_DEV_KEY"
        /// Numeric App Store ID (e.g. 1234567890).
        static let appleAppID = "YOUR_APP_STORE_NUMERIC_ID"
    }
}
