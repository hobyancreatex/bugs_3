//
//  OnboardingViewController.swift
//  Bugs
//

import UIKit

/// Два экрана на `UICollectionView`, листание только по кнопке.
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
        cv.register(OnboardingOutroPageCollectionViewCell.self, forCellWithReuseIdentifier: OnboardingOutroPageCollectionViewCell.reuseIdentifier)
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
        updateButtonTitle()

        view.addSubview(collectionView)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            actionButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 46),
            actionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -46),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -44),
            actionButton.heightAnchor.constraint(equalToConstant: 56),
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

    private func updateButtonTitle() {
        let key = currentPage == 0 ? "onboarding.button.next" : "onboarding.button.start"
        actionButton.setTitle(L10n.string(key), for: .normal)
    }

    @objc
    private func actionTapped() {
        if currentPage == 0 {
            currentPage = 1
            let indexPath = IndexPath(item: 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            updateButtonTitle()
        } else {
            OnboardingCompletionStore.isComplete = true
            transitionToMain()
        }
    }

    private func transitionToMain() {
        guard let window = view.window else { return }
        let main = MainTabBarController()
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = main
        }
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
            withReuseIdentifier: OnboardingOutroPageCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as! OnboardingOutroPageCollectionViewCell
        cell.configure()
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let intro = cell as? OnboardingIntroPageCollectionViewCell {
            intro.playBenefitsRevealAnimation()
        }
    }
}
