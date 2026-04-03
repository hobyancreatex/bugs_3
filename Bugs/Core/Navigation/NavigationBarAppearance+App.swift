//
//  NavigationBarAppearance+App.swift
//  Bugs
//

import UIKit

enum AppNavigationBarAppearance {

    static func apply(to navigationBar: UINavigationBar) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBackground
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.appTextPrimary,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.compactScrollEdgeAppearance = appearance
        navigationBar.tintColor = .appTextPrimary
    }
}
