//
//  AppStoreReviewSessionPrompt.swift
//  Bugs
//

import StoreKit
import UIKit

/// Системный prompt оценки в App Store; не чаще одной попытки за жизнь процесса приложения.
enum AppStoreReviewSessionPrompt {

    private static var didScheduleThisSession = false

    /// Вызывать после успешного сценария (например, получены кандидаты распознавания).
    /// Задержка даёт завершиться push-анимации; факт показа решает iOS (квота Apple).
    static func scheduleAfterSuccessfulCoreFlow() {
        guard !didScheduleThisSession else { return }
        didScheduleThisSession = true
        let delay: TimeInterval = 0.75
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else { return }
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
