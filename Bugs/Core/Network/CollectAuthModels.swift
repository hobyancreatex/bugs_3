//
//  CollectAuthModels.swift
//  Bugs
//

import Foundation

/// Ответ `POST /api/auth/sign-up/` и `POST /api/auth/login/` (контракт совпадает).
struct CollectAuthAPIResponse: Decodable {
    struct InsectsPayload: Decodable {
        let token: String
        let user: User?
    }

    struct User: Decodable {
        let id: Int
        let username: String
    }

    let traceId: String?
    let insectsPayload: InsectsPayload?
    let queryStatus: String?
    let serverTime: Int64?
    let insectApiVersion: String?
    let clientAuthenticated: Bool?
    let requestOperation: String?
    let requestEndpoint: String?
    let responseCode: Int?
}

extension CollectAuthAPIResponse {
    /// Токен для заголовков последующих запросов.
    var authToken: String? {
        guard let t = insectsPayload?.token, !t.isEmpty else { return nil }
        return t
    }
}
