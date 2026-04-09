//
//  OnboardingViewController.swift
//  Bugs
//

import UIKit

/// Общая геометрия плавающей CTA и встроенной кнопки пейвола на втором шаге онбординга.
enum OnboardingFloatingCTALayout {
    static let buttonHeight: CGFloat = 56
    /// Низ кнопки на `safeAreaLayoutGuide.bottomAnchor` с этим отступом (отрицательная константа в Auto Layout).
    static let bottomOffsetFromSafeAreaBottom: CGFloat = 44
}

/// Два экрана на `UICollectionView`, листание только по кнопке на первом шаге; второй — пейвол.
final class OnboardingViewController: UIViewController {

    private var currentPage = 0

    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.minimumLineSpacing = 0
        l.minimumInteritemSpacing = 0
        l.sectionInset = .zero
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .appBackground
        cv.isPagingEnabled = true
        cv.isScrollEnabled = false
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.bounces = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(OnboardingIntroPageCollectionViewCell.self, forCellWithReuseIdentifier: OnboardingIntroPageCollectionViewCell.reuseIdentifier)
        cv.register(OnboardingPaywallCollectionViewCell.self, forCellWithReuseIdentifier: OnboardingPaywallCollectionViewCell.reuseIdentifier)
        return cv
    }()

    private let actionButton: GradientRoundedCTAControl = {
        let b = GradientRoundedCTAControl()
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .appBackground

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        updateChromeForPage()

        view.addSubview(collectionView)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            actionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 46),
            actionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -46),
            actionButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -OnboardingFloatingCTALayout.bottomOffsetFromSafeAreaBottom
            ),
            actionButton.heightAnchor.constraint(equalToConstant: OnboardingFloatingCTALayout.buttonHeight),
        ])

        view.bringSubviewToFront(actionButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = collectionView.bounds.size
        guard size.width > 0, size.height > 0 else { return }
        if flowLayout.itemSize != size {
            flowLayout.itemSize = size
            flowLayout.invalidateLayout()
        }
    }

    private func updateChromeForPage() {
        actionButton.isHidden = false
        if currentPage == 0 {
            actionButton.setTitle(L10n.string("onboarding.button.next"), for: .normal)
        } else {
            actionButton.setTitle(L10n.string("paywall.button.next"), for: .normal)
        }
        actionButton.isPulseAnimationEnabled = (currentPage == 1)
    }

    @objc
    private func actionTapped() {
        if currentPage == 0 {
            currentPage = 1
            let indexPath = IndexPath(item: 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            updateChromeForPage()
        } else {
            completeOnboardingWithSubscription()
        }
    }

    fileprivate func completeOnboardingAndGoMain() {
        OnboardingCompletionStore.isComplete = true
        transitionToMain()
    }

    fileprivate func completeOnboardingWithSubscription() {
        SubscriptionAccess.shared.setPremiumActive(true)
        completeOnboardingAndGoMain()
    }

    fileprivate func completeOnboardingSkipPaywall() {
        completeOnboardingAndGoMain()
    }

    private func transitionToMain() {
        guard let window = view.window else { return }
        let main = MainTabBarController()
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = main
        }
    }

    fileprivate static func openExternalURL(key: String) {
        let s = L10n.string(key)
        guard let url = URL(string: s) else { return }
        UIApplication.shared.open(url)
    }

    fileprivate func presentRestoreMessage() {
        let alert = UIAlertController(
            title: L10n.string("settings.row.restore"),
            message: L10n.string("settings.restore.message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.string("common.done"), style: .default))
        present(alert, animated: true)
    }
}

extension OnboardingViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OnboardingIntroPageCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as! OnboardingIntroPageCollectionViewCell
            cell.configure()
            return cell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OnboardingPaywallCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as! OnboardingPaywallCollectionViewCell
        cell.configure(
            onClose: { [weak self] in self?.completeOnboardingSkipPaywall() },
            onTerms: { OnboardingViewController.openExternalURL(key: "settings.link.terms") },
            onPrivacy: { OnboardingViewController.openExternalURL(key: "settings.link.privacy") },
            onRestore: { [weak self] in self?.presentRestoreMessage() }
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let intro = cell as? OnboardingIntroPageCollectionViewCell {
            intro.playBenefitsRevealAnimation()
        }
    }
}
