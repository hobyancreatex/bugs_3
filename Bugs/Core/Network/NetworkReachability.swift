import Foundation
import Network

final class NetworkReachability {
    static let shared = NetworkReachability()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "bugs.network.reachability")
    private var currentStatus: NWPath.Status = .requiresConnection
    private var hasReceivedInitialPath = false

    var isConnected: Bool {
        // NWPathMonitor reports asynchronously after start.
        // Before the first callback we should not block user actions with a false "offline".
        if !hasReceivedInitialPath { return true }
        return currentStatus == .satisfied
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentStatus = path.status
            self?.hasReceivedInitialPath = true
        }
        monitor.start(queue: queue)
    }
}
