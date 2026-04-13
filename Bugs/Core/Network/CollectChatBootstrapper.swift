//
//  CollectChatBootstrapper.swift
//  Bugs
//

import Foundation

enum CollectChatBootstrapper {
    /// Ключчейн → при ошибке 404 сброс; иначе `GET chats/` (первый); иначе `POST chats/` с `message`.
    static func loadOrCreateChat(seedMessage: String) async throws -> CollectChatDetailDTO {
        guard CollectAPIAuthState.token != nil else {
            throw CollectChatFlowError.noAuthToken
        }

        let http = CollectChatHTTPClient.shared

        if let idStr = DeviceAuthKeychain.storedChatId, let id = Int(idStr) {
            do {
                let data = try await http.get(path: "chats/\(id)/")
                return try decodeDetail(data)
            } catch CollectAPIError.badStatus(404, _) {
                try? DeviceAuthKeychain.clearChatId()
            } catch {
                throw error
            }
        }

        let listData = try await http.get(path: "chats/")
        if let id = CollectChatListParser.firstChatId(from: listData) {
            try DeviceAuthKeychain.saveChatId(id)
            let detailData = try await http.get(path: "chats/\(id)/")
            return try decodeDetail(detailData)
        }

        let createdData = try await http.postJSON(path: "chats/", body: ["message": seedMessage])
        let newId = try CollectChatCreationParser.chatId(from: createdData)
        try DeviceAuthKeychain.saveChatId(newId)
        let detailData = try await http.get(path: "chats/\(newId)/")
        return try decodeDetail(detailData)
    }

    private static func decodeDetail(_ data: Data) throws -> CollectChatDetailDTO {
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(CollectChatInsectsEnvelope<CollectChatDetailDTO>.self, from: data) {
            return envelope.insectsPayload
        }
        if let dto = try? decoder.decode(CollectChatDetailDTO.self, from: data) {
            return dto
        }
        throw CollectChatFlowError.cannotParseChatDetail
    }

    /// Только `GET chats/{id}/` — для обновления истории после возврата на экран или ответа ИИ.
    static func fetchChatDetail(id: Int) async throws -> CollectChatDetailDTO {
        guard CollectAPIAuthState.token != nil else {
            throw CollectChatFlowError.noAuthToken
        }
        let data = try await CollectChatHTTPClient.shared.get(path: "chats/\(id)/")
        return try decodeDetail(data)
    }
}
