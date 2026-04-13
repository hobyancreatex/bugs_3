//
//  CollectChatModels.swift
//  Bugs
//

import Foundation

// MARK: - REST (обёртка API v3)

struct CollectChatInsectsEnvelope<Payload: Codable>: Codable {
    let insectsPayload: Payload

    enum CodingKeys: String, CodingKey {
        case insectsPayload = "insects_payload"
    }
}

struct CollectChatPagedListPayload: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [CollectChatListItemDTO]
}

struct CollectChatListItemDTO: Codable {
    let id: Int
}

struct CollectChatDetailDTO: Codable {
    let id: Int
    let messages: [CollectChatMessageDTO]
    let title: String
    let createdAt: String
    let lastMessage: String?
    let user: Int

    enum CodingKeys: String, CodingKey {
        case id, messages, title
        case createdAt = "created_at"
        case lastMessage = "last_message"
        case user
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        messages = try c.decodeIfPresent([CollectChatMessageDTO].self, forKey: .messages) ?? []
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        createdAt = try c.decode(String.self, forKey: .createdAt)
        lastMessage = try c.decodeIfPresent(String.self, forKey: .lastMessage)
        user = try c.decode(Int.self, forKey: .user)
    }
}

struct CollectChatMessageDTO: Codable {
    let id: Int
    let sender: Int?
    let text: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, sender, text
        case createdAt = "created_at"
    }
}

/// Тело `insects_payload` после `POST chats/` (без `messages`).
struct CollectChatCreatedPayload: Codable {
    let id: Int
}

// MARK: - WebSocket (streaming)

struct CollectChatSocketChunk: Codable {
    let chunk: CollectChatSocketChunkBody
    let chatID: Int

    enum CodingKeys: String, CodingKey {
        case chunk
        case chatID = "chat_id"
    }

    init(chunk: CollectChatSocketChunkBody, chatID: Int) {
        self.chunk = chunk
        self.chatID = chatID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chunk = try c.decode(CollectChatSocketChunkBody.self, forKey: .chunk)
        if let id = try? c.decode(Int.self, forKey: .chatID) {
            chatID = id
        } else if let d = try? c.decode(Double.self, forKey: .chatID) {
            chatID = Int(d)
        } else if let s = try? c.decode(String.self, forKey: .chatID), let id = Int(s) {
            chatID = id
        } else {
            throw DecodingError.dataCorruptedError(forKey: .chatID, in: c, debugDescription: "chat_id")
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(chunk, forKey: .chunk)
        try c.encode(chatID, forKey: .chatID)
    }
}

struct CollectChatSocketChunkBody: Codable {
    let choices: [CollectChatSocketChoice]

    init(choices: [CollectChatSocketChoice]) {
        self.choices = choices
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        choices = try c.decodeIfPresent([CollectChatSocketChoice].self, forKey: .choices) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(choices, forKey: .choices)
    }

    enum CodingKeys: String, CodingKey {
        case choices
    }
}

struct CollectChatSocketChoice: Codable {
    let delta: CollectChatSocketDelta
}

struct CollectChatSocketDelta: Codable {
    let content: String

    init(content: String) {
        self.content = content
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(content, forKey: .content)
    }

    private enum CodingKeys: String, CodingKey {
        case content
    }
}
