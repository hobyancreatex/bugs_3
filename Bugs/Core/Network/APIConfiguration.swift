//
//  APIConfiguration.swift
//  Bugs
//

import Foundation

enum APIConfiguration {
    static let collectBaseURL = URL(string: "https://collect.bugs-identifier.com/api/")!

    /// WebSocket для стриминга ответов чата (тот же хост, что и Collect API).
    static let collectChatWebSocketURL = URL(string: "wss://collect.bugs-identifier.com/ws/chat/")!
}
