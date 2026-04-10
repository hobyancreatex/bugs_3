//
//  InsectImageGalleryViewController.swift
//  Bugs
//

import UIKit

/// Полноэкранный просмотр фото насекомого: свайп, миниатюры, счётчик «текущая/всего».
final class InsectImageGalleryViewController: UIViewController {

    private enum Source {
        case remote([URL])
        case assets([String])
    }

    private let source: Source
    private let initialIndex: Int

    private var didApplyInitialScroll = false
    private var currentPage: Int = 0

    /// Только для режима `.assets` — без повторного `UIImage(named:)` при свайпе.
    private var imageCache: [String: UIImage] = [:]

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

    private let closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.accessibilityLabel = L10n.string("scanner.close.accessibility")
        return b
    }()

    private var itemCount: Int {
        switch source {
        case .remote(let urls): return urls.count
        case .assets(let names): return names.count
        }
    }

    /// Реальные URL с бэка (порядок: герой, затем галерея, без дублей).
    init(imageURLs: [URL], initialIndex: Int = 0) {
        self.source = .remote(imageURLs)
        let maxIdx = max(0, imageURLs.count - 1)
        self.initialIndex = min(max(0, initialIndex), maxIdx)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    /// Заглушка без сети (mock / список ассетов).
    init(imageAssetNames: [String], initialIndex: Int = 0) {
        self.source = .assets(imageAssetNames)
        let maxIdx = max(0, imageAssetNames.count - 1)
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
        if case .assets(let names) = source {
            for name in names where imageCache[name] == nil {
                imageCache[name] = UIImage(named: name)
            }
        }

        closeButton.setImage(Self.lightCloseImage(), for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        mainCollectionView.dataSource = self
        mainCollectionView.delegate = self
        thumbCollectionView.dataSource = self
        thumbCollectionView.delegate = self

        counterPill.addSubview(counterLabel)
        view.addSubview(mainCollectionView)
        view.addSubview(counterPill)
        view.addSubview(thumbCollectionView)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
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
        currentPage = idx
        updateCounterLabel(page: idx)
        thumbCollectionView.reloadData()
        scrollThumbToVisible(animated: false)
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
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
        guard w > 1 else { return 0 }
        return Int(round(mainCollectionView.contentOffset.x / w))
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

extension InsectImageGalleryViewController: UICollectionViewDataSource {

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
            switch source {
            case .remote(let urls):
                cell.configureRemote(url: urls[indexPath.item])
            case .assets(let names):
                cell.configureLocal(image: imageCache[names[indexPath.item]])
            }
            return cell
        }
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InsectImageGalleryThumbnailCell.reuseIdentifier,
            for: indexPath
        ) as? InsectImageGalleryThumbnailCell else {
            return UICollectionViewCell()
        }
        switch source {
        case .remote(let urls):
            cell.configureRemote(url: urls[indexPath.item], selected: indexPath.item == currentPage)
        case .assets(let names):
            cell.configureLocal(image: imageCache[names[indexPath.item]], selected: indexPath.item == currentPage)
        }
        return cell
    }
}

extension InsectImageGalleryViewController: UICollectionViewDelegateFlowLayout {

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

extension InsectImageGalleryViewController: UICollectionViewDelegate {

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
    }
}

// MARK: - Cells

private final class InsectImageGalleryPageCell: UICollectionViewCell {

    static let reuseIdentifier = "InsectImageGalleryPageCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .appBackground
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configureRemote(url: URL) {
        RemoteImageLoader.load(into: imageView, url: url)
    }

    func configureLocal(image: UIImage?) {
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = image
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = nil
    }
}

private final class InsectImageGalleryThumbnailCell: UICollectionViewCell {

    static let reuseIdentifier = "InsectImageGalleryThumbnailCell"

    private static let selectionBorder = UIColor.appReadMore.cgColor
    private static let borderWidth: CGFloat = 3

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configureRemote(url: URL, selected: Bool) {
        RemoteImageLoader.load(into: imageView, url: url)
        applySelection(selected: selected)
    }

    func configureLocal(image: UIImage?, selected: Bool) {
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = image
        applySelection(selected: selected)
    }

    func applySelection(selected: Bool) {
        imageView.layer.borderWidth = selected ? Self.borderWidth : 0
        imageView.layer.borderColor = selected ? Self.selectionBorder : nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = nil
        imageView.layer.borderWidth = 0
    }
}
