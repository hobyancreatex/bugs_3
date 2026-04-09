//
//  OnboardingCompletionStore.swift
//  Bugs
//

import Foundation

enum OnboardingCompletionStore {
    private static let key = "Bugs.onboarding.completed"

    static var isComplete: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
