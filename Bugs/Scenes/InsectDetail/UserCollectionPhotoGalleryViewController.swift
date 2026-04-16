//
//  UserCollectionPhotoGalleryViewController.swift
//  Bugs
//

import UIKit

/// Полноэкранный просмотр фото из «Моей коллекции» с удалением текущего кадра.
final class UserCollectionPhotoGalleryViewController: UIViewController {

    private var photos: [InsectDetail.UserCollectionPhoto]
    private let initialIndex: Int
    private let onDismiss: () -> Void

    private var didApplyInitialScroll = false
    private var currentPage: Int = 0
    private var isDeleting = false
    private var deleteLoadingOverlay: UIView?

    private let mainCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .appBackground
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.register(InsectImageGalleryPageCell.self, forCellWithReuseIdentifier: InsectImageGalleryPageCell.reuseIdentifier)
        return cv
    }()

    private lazy var thumbLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.itemSize = CGSize(width: 72, height: 72)
        l.minimumLineSpacing = 8
        l.minimumInteritemSpacing = 8
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return l
    }()

    private lazy var thumbCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: thumbLayout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.register(InsectImageGalleryThumbnailCell.self, forCellWithReuseIdentifier: InsectImageGalleryThumbnailCell.reuseIdentifier)
        return cv
    }()

    private let counterPill: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .appReadMore
        v.layer.cornerRadius = 10
        v.layer.masksToBounds = true
        return v
    }()

    private let counterLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let deleteButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(.insectDetailDeleteFromCollection(), for: .normal)
        b.tintColor = .appCollectionDelete
        b.accessibilityLabel = L10n.string("insect.detail.remove_from_collection.accessibility")
        return b
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.accessibilityLabel = L10n.string("scanner.close.accessibility")
        return b
    }()

    private var itemCount: Int { photos.count }

    private func clampedPageIndex(_ raw: Int) -> Int {
        let n = itemCount
        guard n > 0 else { return 0 }
        return min(max(0, raw), n - 1)
    }

    init(
        photos: [InsectDetail.UserCollectionPhoto],
        initialIndex: Int = 0,
        onDismiss: @escaping () -> Void
    ) {
        self.photos = photos
        self.onDismiss = onDismiss
        let maxIdx = max(0, photos.count - 1)
        self.initialIndex = min(max(0, initialIndex), maxIdx)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .appBackground

        currentPage = initialIndex

        closeButton.setImage(Self.lightCloseImage(), for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        mainCollectionView.dataSource = self
        mainCollectionView.delegate = self
        thumbCollectionView.dataSource = self
        thumbCollectionView.delegate = self
        thumbCollectionView.allowsSelection = true
        thumbCollectionView.allowsMultipleSelection = false

        counterPill.addSubview(counterLabel)
        view.addSubview(mainCollectionView)
        view.addSubview(counterPill)
        view.addSubview(thumbCollectionView)
        view.addSubview(deleteButton)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            deleteButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            deleteButton.widthAnchor.constraint(equalToConstant: 32),
            deleteButton.heightAnchor.constraint(equalToConstant: 32),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            thumbCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thumbCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thumbCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            thumbCollectionView.heightAnchor.constraint(equalToConstant: 88),

            mainCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mainCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainCollectionView.bottomAnchor.constraint(equalTo: thumbCollectionView.topAnchor, constant: -12),

            counterLabel.leadingAnchor.constraint(equalTo: counterPill.leadingAnchor, constant: 12),
            counterLabel.trailingAnchor.constraint(equalTo: counterPill.trailingAnchor, constant: -12),
            counterLabel.topAnchor.constraint(equalTo: counterPill.topAnchor),
            counterLabel.bottomAnchor.constraint(equalTo: counterPill.bottomAnchor),

            counterPill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            counterPill.bottomAnchor.constraint(equalTo: mainCollectionView.bottomAnchor, constant: -20),
            counterPill.heightAnchor.constraint(equalToConstant: 20),
        ])

        updateCounterLabel(page: currentPage)
        thumbCollectionView.reloadData()

        deleteButton.layer.zPosition = 20_000
        closeButton.layer.zPosition = 20_000
        counterPill.layer.zPosition = 15_000
        thumbCollectionView.layer.zPosition = 15_000
        mainCollectionView.layer.zPosition = 0
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed {
            onDismiss()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let sz = mainCollectionView.bounds.size
        if sz.width > 0, sz.height > 0,
           let flow = mainCollectionView.collectionViewLayout as? UICollectionViewFlowLayout,
           flow.itemSize != sz {
            flow.itemSize = sz
            flow.invalidateLayout()
        }

        guard !didApplyInitialScroll, mainCollectionView.bounds.width > 0, itemCount > 0 else { return }
        didApplyInitialScroll = true
        let idx = min(initialIndex, itemCount - 1)
        mainCollectionView.scrollToItem(at: IndexPath(item: idx, section: 0), at: .centeredHorizontally, animated: false)
        alignMainScrollToPageAndRefreshThumbs(idx)
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
    }

    @objc
    private func deleteTapped() {
        guard !isDeleting, currentPage >= 0, currentPage < photos.count else { return }
        let alert = UIAlertController(
            title: L10n.string("insect.detail.collection_photo.delete.confirm.title"),
            message: L10n.string("insect.detail.collection_photo.delete.confirm.message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.string("insect.detail.collection_photo.delete.confirm.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.string("insect.detail.collection_photo.delete.confirm.delete"), style: .destructive) { [weak self] _ in
            self?.performDeleteCurrentPhoto()
        })
        present(alert, animated: true)
    }

    private func performDeleteCurrentPhoto() {
        guard !isDeleting, currentPage >= 0, currentPage < photos.count else { return }
        let indexToDelete = currentPage
        let photoId = photos[indexToDelete].id
        isDeleting = true
        installDeleteLoadingOverlay()
        Task { [weak self] in
            do {
                try await CollectAPIClient.shared.deleteCollectionPhoto(id: photoId)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.removeDeleteLoadingOverlay()
                    self.applyDeleteSuccess(at: indexToDelete)
                    self.bringChromeToFront()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.removeDeleteLoadingOverlay()
                    self.isDeleting = false
                    self.bringChromeToFront()
                    UserFacingRequestErrorAlert.presentTryAgainLater()
                }
            }
        }
    }

    private func installDeleteLoadingOverlay() {
        removeDeleteLoadingOverlay()
        let dim = UIView()
        dim.translatesAutoresizingMaskIntoConstraints = false
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        dim.isUserInteractionEnabled = true
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .white
        spinner.startAnimating()
        dim.addSubview(spinner)
        view.addSubview(dim)
        NSLayoutConstraint.activate([
            dim.topAnchor.constraint(equalTo: view.topAnchor),
            dim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dim.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: dim.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: dim.centerYAnchor),
        ])
        dim.layer.zPosition = 25_000
        view.bringSubviewToFront(dim)
        deleteLoadingOverlay = dim
        closeButton.isEnabled = false
        deleteButton.isEnabled = false
    }

    private func removeDeleteLoadingOverlay() {
        deleteLoadingOverlay?.removeFromSuperview()
        deleteLoadingOverlay = nil
        deleteButton.isEnabled = true
        closeButton.isEnabled = true
    }

    /// После `reloadData`/`layout` основная коллекция может перехватывать тапы; уводим её назад и поднимаем хром.
    private func bringChromeToFront() {
        view.sendSubviewToBack(mainCollectionView)
        view.bringSubviewToFront(counterPill)
        view.bringSubviewToFront(thumbCollectionView)
        view.bringSubviewToFront(deleteButton)
        view.bringSubviewToFront(closeButton)
    }

    private func applyDeleteSuccess(at index: Int) {
        guard index >= 0, index < photos.count else {
            isDeleting = false
            deleteButton.isEnabled = true
            closeButton.isEnabled = true
            bringChromeToFront()
            return
        }
        photos.remove(at: index)
        if photos.isEmpty {
            isDeleting = false
            dismiss(animated: true)
            return
        }
        let newCount = photos.count
        var nextPage = index
        if nextPage >= newCount {
            nextPage = newCount - 1
        }
        mainCollectionView.reloadData()
        thumbCollectionView.reloadData()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        if let flow = mainCollectionView.collectionViewLayout as? UICollectionViewFlowLayout,
           mainCollectionView.bounds.width > 0, mainCollectionView.bounds.height > 0 {
            flow.itemSize = mainCollectionView.bounds.size
            flow.invalidateLayout()
        }
        mainCollectionView.layoutIfNeeded()
        mainCollectionView.scrollToItem(at: IndexPath(item: nextPage, section: 0), at: .centeredHorizontally, animated: false)
        alignMainScrollToPageAndRefreshThumbs(nextPage)
        isDeleting = false
    }

    private func updateCounterLabel(page: Int) {
        let total = max(1, itemCount)
        let p = min(max(0, page), total - 1) + 1
        counterLabel.text = "\(p)/\(total)"
    }

    private func setPage(_ page: Int, animated: Bool) {
        let maxP = max(0, itemCount - 1)
        let p = min(max(0, page), maxP)
        let previous = currentPage
        currentPage = p
        updateCounterLabel(page: p)
        mainCollectionView.scrollToItem(at: IndexPath(item: p, section: 0), at: .centeredHorizontally, animated: animated)
        updateThumbnailSelection(from: previous, to: p)
        scrollThumbToVisible(animated: animated)
        thumbCollectionView.selectItem(at: IndexPath(item: p, section: 0), animated: false, scrollPosition: .centeredHorizontally)
    }

    private func updateThumbnailSelection(from oldIndex: Int, to newIndex: Int) {
        guard oldIndex != newIndex else { return }
        let candidates = [oldIndex, newIndex].filter { $0 >= 0 && $0 < itemCount }
        var needReload: [IndexPath] = []
        for index in candidates {
            let ip = IndexPath(item: index, section: 0)
            let selected = index == newIndex
            if let cell = thumbCollectionView.cellForItem(at: ip) as? InsectImageGalleryThumbnailCell {
                cell.applySelection(selected: selected)
            } else {
                needReload.append(ip)
            }
        }
        if !needReload.isEmpty {
            UIView.performWithoutAnimation {
                thumbCollectionView.reloadItems(at: needReload)
            }
        }
    }

    private func pageFromMainScroll() -> Int {
        let w = mainCollectionView.bounds.width
        guard w > 1 else { return clampedPageIndex(0) }
        let raw = Int(round(mainCollectionView.contentOffset.x / w))
        return clampedPageIndex(raw)
    }

    /// После `reloadData` offset иногда остаётся от старого числа страниц — выравниваем и миниатюру «выбранной».
    private func alignMainScrollToPageAndRefreshThumbs(_ page: Int) {
        let p = clampedPageIndex(page)
        currentPage = p
        let w = mainCollectionView.bounds.width
        guard w > 1, itemCount > 0 else {
            thumbCollectionView.reloadData()
            return
        }
        mainCollectionView.layoutIfNeeded()
        mainCollectionView.contentOffset = CGPoint(x: CGFloat(p) * w, y: mainCollectionView.contentOffset.y)
        updateCounterLabel(page: p)
        thumbCollectionView.reloadData()
        thumbCollectionView.layoutIfNeeded()
        let ip = IndexPath(item: p, section: 0)
        thumbCollectionView.selectItem(at: ip, animated: false, scrollPosition: .centeredHorizontally)
        scrollThumbToVisible(animated: false)
    }

    private func scrollThumbToVisible(animated: Bool) {
        let ip = IndexPath(item: currentPage, section: 0)
        guard currentPage < itemCount else { return }
        thumbCollectionView.scrollToItem(at: ip, at: .centeredHorizontally, animated: animated)
    }

    private static func lightCloseImage() -> UIImage? {
        let side: CGFloat = 32
        let format = UIGraphicsImageRendererFormat()
        format.scale = UITraitCollection.current.displayScale
        format.opaque = false
        let color = UIColor.appReadMore
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { _ in
            let lineWidth: CGFloat = 1.5
            let ovalInset: CGFloat = 2
            let oval = UIBezierPath(
                ovalIn: CGRect(
                    x: ovalInset,
                    y: ovalInset,
                    width: side - ovalInset * 2,
                    height: side - ovalInset * 2
                )
            )
            oval.lineWidth = lineWidth
            color.setStroke()
            oval.stroke()

            let crossInset: CGFloat = 10
            let cross = UIBezierPath()
            cross.move(to: CGPoint(x: crossInset, y: crossInset))
            cross.addLine(to: CGPoint(x: side - crossInset, y: side - crossInset))
            cross.move(to: CGPoint(x: side - crossInset, y: crossInset))
            cross.addLine(to: CGPoint(x: crossInset, y: side - crossInset))
            cross.lineWidth = lineWidth
            cross.lineCapStyle = .round
            color.setStroke()
            cross.stroke()
        }
    }
}

extension UserCollectionPhotoGalleryViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        itemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === mainCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: InsectImageGalleryPageCell.reuseIdentifier,
                for: indexPath
            ) as? InsectImageGalleryPageCell else {
                return UICollectionViewCell()
            }
            cell.configureRemote(url: photos[indexPath.item].url)
            return cell
        }
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InsectImageGalleryThumbnailCell.reuseIdentifier,
            for: indexPath
        ) as? InsectImageGalleryThumbnailCell else {
            return UICollectionViewCell()
        }
        cell.configureRemote(url: photos[indexPath.item].url, selected: indexPath.item == currentPage)
        return cell
    }
}

extension UserCollectionPhotoGalleryViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView === mainCollectionView {
            return collectionView.bounds.size
        }
        return CGSize(width: 72, height: 72)
    }
}

extension UserCollectionPhotoGalleryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === thumbCollectionView else { return }
        setPage(indexPath.item, animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === mainCollectionView else { return }
        let p = pageFromMainScroll()
        if p != currentPage {
            let previous = currentPage
            currentPage = p
            updateCounterLabel(page: p)
            updateThumbnailSelection(from: previous, to: p)
            scrollThumbToVisible(animated: true)
            thumbCollectionView.selectItem(at: IndexPath(item: p, section: 0), animated: false, scrollPosition: .centeredHorizontally)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === mainCollectionView else { return }
        let p = pageFromMainScroll()
        guard p != currentPage else { return }
        let previous = currentPage
        currentPage = p
        updateCounterLabel(page: p)
        updateThumbnailSelection(from: previous, to: p)
        thumbCollectionView.selectItem(at: IndexPath(item: p, section: 0), animated: false, scrollPosition: .centeredHorizontally)
    }
}
