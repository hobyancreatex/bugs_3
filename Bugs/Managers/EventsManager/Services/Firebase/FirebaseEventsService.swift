import FirebaseAnalytics
import FirebaseCore

final class FirebaseEventsService: EventServiceProtocol {

    init() {
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            #if DEBUG
            print("[Analytics] GoogleService-Info.plist missing — Firebase not configured")
            #endif
            return
        }
        FirebaseApp.configure()
    }

    func logEvent(name: String, parameters: [String: Any]? = nil) {
        guard FirebaseApp.app() != nil else { return }
        Analytics.logEvent(name, parameters: parameters)
    }
}
