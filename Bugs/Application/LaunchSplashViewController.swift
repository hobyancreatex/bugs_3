//
//  LaunchSplashViewController.swift
//  Bugs
//

import UIKit
import Lottie

/// Кремовый экран; Lottie 88×88 по центру.
final class LaunchSplashViewController: UIViewController {

    private static let screenBackground = UIColor(
        red: 253 / 255,
        green: 255 / 255,
        blue: 243 / 255,
        alpha: 1
    )

    private let animationView = LottieAnimationView(name: "loading", bundle: .main)

    private var finishWorkItem: DispatchWorkItem?

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

        finishWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.transitionToMain()
        }
        finishWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        finishWorkItem?.cancel()
        finishWorkItem = nil
    }

    private func transitionToMain() {
        guard let window = view.window else { return }
        finishWorkItem = nil
        let next: UIViewController = SubscriptionManager.shared.isSubscriptionActive
            ? MainTabBarController()
            : OnboardingViewController()
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = next
        }
    }
}
