//
//  LaunchSplashViewController.swift
//  Bugs
//

import UIKit
import Lottie
import AppTrackingTransparency

/// Кремовый экран; Lottie 88×88 по центру.
final class LaunchSplashViewController: UIViewController {

    private static let screenBackground = UIColor(
        red: 253 / 255,
        green: 255 / 255,
        blue: 243 / 255,
        alpha: 1
    )

    private let animationView = LottieAnimationView(name: "loading", bundle: .main)

    private var launchTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.screenBackground

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.backgroundColor = .clear
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        view.addSubview(animationView)

        let side: CGFloat = 88
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: side),
            animationView.heightAnchor.constraint(equalToConstant: side),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animationView.play()
        requestTrackingAuthorizationIfNeeded()

        launchTask?.cancel()
        launchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            async let minSplash: Void = {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }()
            await AuthBootstrapper.shared.bootstrapIfNeeded()
            await minSplash
            guard !Task.isCancelled else { return }
            transitionToMain()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        launchTask?.cancel()
        launchTask = nil
    }

    private func transitionToMain() {
        guard let window = view.window else { return }
        launchTask = nil
        let next: UIViewController
        if SubscriptionManager.shared.isSubscriptionActive {
            next = MainTabBarController()
        } else {
            next = OnboardingViewController()
        }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = next
        }
    }

    private func requestTrackingAuthorizationIfNeeded() {
        guard #available(iOS 14, *) else { return }
        ATTrackingManager.requestTrackingAuthorization { _ in }
    }
}
