//
//  AuthBootstrapper.swift
//  Bugs
//

import Foundation
import UIKit

/// Скрытая авторизация устройства: регистрация по UUID или логин для обновления токена.
actor AuthBootstrapper {
    static let shared = AuthBootstrapper()

    private var runningTask: Task<Void, Never>?

    func bootstrapIfNeeded() async {
        if let runningTask {
            await runningTask.value
            return
        }
        let task = Task { await self.performBootstrap() }
        runningTask = task
        await task.value
        runningTask = nil
    }

    private func performBootstrap() async {
        let service = CollectAuthService.shared

        if DeviceAuthKeychain.isDeviceRegistered {
            guard let username = DeviceAuthKeychain.storedUsername,
                  let password = DeviceAuthKeychain.storedPassword,
                  !username.isEmpty, !password.isEmpty
            else {
                await registerNewDevice(using: service)
                return
            }

            do {
                let token = try await service.login(
                    credentials: .init(username: username, password: password)
                )
                try DeviceAuthKeychain.saveToken(token)
                CollectAPIAuthState.setToken(token)
            } catch {
                await MainActor.run {
                    UserFacingRequestErrorAlert.presentTryAgainLater()
                }
            }
            return
        }

        await registerNewDevice(using: service)
    }

    private func registerNewDevice(using service: CollectAuthService) async {
        let uuid = UUID().uuidString
        let credentials = CollectAuthCredentialsRequest(username: uuid, password: uuid)

        do {
            let token = try await service.signUp(credentials: credentials)
            try DeviceAuthKeychain.saveCredentials(username: uuid, password: uuid)
            try DeviceAuthKeychain.saveToken(token)
            try DeviceAuthKeychain.setDeviceRegistered(true)
            CollectAPIAuthState.setToken(token)
        } catch {
            await MainActor.run {
                UserFacingRequestErrorAlert.presentTryAgainLater()
            }
        }
    }
}
