//
//  InsectDetailViewController.swift
//  Bugs
//

import UIKit

protocol InsectDetailDisplayLogic: AnyObject {
    func displayDetail(viewModel: InsectDetail.Load.ViewModel)
}

final class InsectDetailViewController: UIViewController, InsectDetailDisplayLogic {

    var interactor: InsectDetailBusinessLogic?

    private var galleryAssetNames: [String] = []

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.alwaysBounceVertical = true
        s.showsVerticalScrollIndicator = true
        s.contentInsetAdjustmentBehavior = .never
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 60
        iv.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return iv
    }()

    private lazy var galleryLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.itemSize = CGSize(width: 128, height: 128)
        l.minimumLineSpacing = 4
        l.minimumInteritemSpacing = 0
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return l
    }()

    private lazy var galleryCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: galleryLayout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(InsectDetailGalleryCell.self, forCellWithReuseIdentifier: InsectDetailGalleryCell.reuseIdentifier)
        return cv
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "library_nav_back"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        scrollView.backgroundColor = .appBackground
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        buildLayout()
        interactor?.loadDetail(request: InsectDetail.Load.Request())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    private func buildLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(heroImageView)
        contentView.addSubview(galleryCollectionView)
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: 344.0 / 390.0),

            galleryCollectionView.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 4),
            galleryCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            galleryCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            galleryCollectionView.heightAnchor.constraint(equalToConstant: 128),
            galleryCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    func displayDetail(viewModel: InsectDetail.Load.ViewModel) {
        heroImageView.image = UIImage(named: viewModel.heroImageAssetName)
        galleryAssetNames = viewModel.galleryImageAssetNames
        galleryCollectionView.reloadData()
    }
}

extension InsectDetailViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        galleryAssetNames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InsectDetailGalleryCell.reuseIdentifier,
            for: indexPath
        ) as? InsectDetailGalleryCell else {
            return UICollectionViewCell()
        }
        cell.configure(imageAssetName: galleryAssetNames[indexPath.item])
        return cell
    }
}

extension InsectDetailViewController: UICollectionViewDelegateFlowLayout {}
