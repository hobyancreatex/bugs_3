//
//  CollectChatWebSocketClient.swift
//  Bugs
//

import Foundation
import Starscream

/// WebSocket через Starscream, заголовок `Authorization: Token …`.
final class CollectChatWebSocketClient: WebSocketDelegate {
    private var socket: WebSocket?
    private var onText: ((String) -> Void)?

    func connect(onText: @escaping (String) -> Void) {
        disconnect()
        self.onText = onText
        guard let token = CollectAPIAuthState.token else { return }

        var request = URLRequest(url: APIConfiguration.collectChatWebSocketURL)
        request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let webSocket = WebSocket(request: request)
        webSocket.delegate = self
        socket = webSocket
        webSocket.connect()
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
        // Не обнулять onText: между disconnect и следующим connect событие может прийти из сокета — иначе чанк есть в логе, а в VC не доезжает.
    }

    func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        switch event {
        case .connected:
            break
        case let .disconnected(reason, code):
            CollectAPILogger.logChatFlowWebSocketInbound("disconnected: \(reason) code=\(code)")
        case let .text(string):
            CollectAPILogger.logChatFlowWebSocketInbound(string)
            let deliver = onText
            DispatchQueue.main.async {
                deliver?(string)
            }
        case let .binary(data):
            CollectAPILogger.logChatFlowWebSocketInbound("<binary \(data.count) bytes>")
        case let .error(error):
            CollectAPILogger.logChatFlowWebSocketInbound("error: \(error?.localizedDescription ?? "nil")")
        case .cancelled:
            break
        case .peerClosed:
            break
        case .ping, .pong, .viabilityChanged, .reconnectSuggested:
            break
        @unknown default:
            break
        }
    }
}
