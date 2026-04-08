//
//  ProfileViewController.swift
//  Bugs
//

import UIKit

/// Профиль: кастомный навбар как на главной, сегмент «Коллекция / Достижения», список насекомых в коллекции.
final class ProfileViewController: UIViewController {

    /// Пустой массив — показывается заглушка коллекции. Для превью списка временно добавьте элементы.
    private var collectionRows: [CategoryInsects.InsectCellViewModel] = []

    private let collectionEmptyStateView: ListSearchEmptyStateView = {
        let v = ListSearchEmptyStateView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let navBarContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .appTextPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let settingsButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "home_nav_settings"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        return b
    }()

    private let premiumButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "home_nav_premium"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        return b
    }()

    private lazy var segmentControl = ProfileSegmentedControl(
        leftTitle: L10n.string("profile.segment.collection"),
        rightTitle: L10n.string("profile.segment.achievements")
    )

    private lazy var listLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .vertical
        l.minimumLineSpacing = 12
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: listLayout)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(CategoryInsectsCell.self, forCellWithReuseIdentifier: CategoryInsectsCell.reuseIdentifier)
        return cv
    }()

    private let achievementsPlaceholder: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .black
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    private var lastCollectionWidthForLayout: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        titleLabel.text = L10n.string("profile.title")
        achievementsPlaceholder.text = L10n.string("profile.achievements.placeholder")
        loadMockCollection()
        collectionEmptyStateView.configure(
            title: L10n.string("profile.collection.empty.title"),
            subtitle: L10n.string("profile.collection.empty.subtitle"),
            imageAssetName: "profile_collection_empty",
            imageSide: 120
        )

        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)

        buildHierarchy()
        layoutConstraints()
        applyCollectionTabContentVisibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed { return }
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = collectionView.bounds.width
        guard w > 1 else { return }
        if abs(w - lastCollectionWidthForLayout) > 0.5 {
            lastCollectionWidthForLayout = w
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func loadMockCollection() {
        collectionRows = []
    }

    private func buildHierarchy() {
        view.addSubview(navBarContainer)
        navBarContainer.addSubview(titleLabel)
        navBarContainer.addSubview(settingsButton)
        navBarContainer.addSubview(premiumButton)

        view.addSubview(segmentControl)
        view.addSubview(collectionView)
        view.addSubview(collectionEmptyStateView)
        view.addSubview(achievementsPlaceholder)
    }

    private func layoutConstraints() {
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            navBarContainer.topAnchor.constraint(equalTo: safe.topAnchor),
            navBarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBarContainer.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: navBarContainer.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: navBarContainer.centerYAnchor),

            premiumButton.trailingAnchor.constraint(equalTo: navBarContainer.trailingAnchor, constant: -16),
            premiumButton.centerYAnchor.constraint(equalTo: navBarContainer.centerYAnchor),
            premiumButton.widthAnchor.constraint(equalToConstant: 28),
            premiumButton.heightAnchor.constraint(equalToConstant: 28),

            settingsButton.trailingAnchor.constraint(equalTo: premiumButton.leadingAnchor, constant: -16),
            settingsButton.centerYAnchor.constraint(equalTo: navBarContainer.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 28),
            settingsButton.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: settingsButton.leadingAnchor, constant: -8),

            segmentControl.topAnchor.constraint(equalTo: navBarContainer.bottomAnchor, constant: 16),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentControl.heightAnchor.constraint(equalToConstant: 44),

            collectionView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            achievementsPlaceholder.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            achievementsPlaceholder.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            achievementsPlaceholder.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            achievementsPlaceholder.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            collectionEmptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionEmptyStateView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            collectionEmptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            collectionEmptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc
    private func settingsTapped() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc
    private func segmentChanged() {
        applyCollectionTabContentVisibility()
    }

    private func applyCollectionTabContentVisibility() {
        let onCollection = segmentControl.selectedIndex == 0
        achievementsPlaceholder.isHidden = onCollection
        guard onCollection else {
            collectionView.isHidden = true
            collectionEmptyStateView.isHidden = true
            return
        }
        let empty = collectionRows.isEmpty
        collectionView.isHidden = empty
        collectionEmptyStateView.isHidden = !empty
        if !empty {
            collectionView.reloadData()
        }
    }
}

extension ProfileViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionRows.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CategoryInsectsCell.reuseIdentifier,
            for: indexPath
        ) as? CategoryInsectsCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: collectionRows[indexPath.item])
        return cell
    }
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let horizontalInset: CGFloat = 32
        let w = max(0, collectionView.bounds.width - horizontalInset)
        return CGSize(width: w, height: 104)
    }
}

extension ProfileViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let asset = collectionRows[indexPath.item].imageAssetName
        let detail = InsectDetailConfigurator.assemble(heroImageAssetName: asset, isInCollection: true)
        navigationController?.pushViewController(detail, animated: true)
    }
}
