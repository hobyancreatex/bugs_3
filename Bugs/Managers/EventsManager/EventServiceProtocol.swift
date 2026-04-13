import Foundation

protocol EventServiceProtocol {
    func logEvent(name: String, parameters: [String: Any]?)
}
