//
//  RecognitionMatchFoundViewController.swift
//  Bugs
//

import UIKit

/// Экран «найдены совпадения»: превью кадра, чекмарки, сетка кандидатов 2×2, CTA.
/// Без подписки — в каждой ячейке плотный блюр, тёмный круг и замок; CTA открывает пейвол.
final class RecognitionMatchFoundViewController: UIViewController {

    private let userPhoto: UIImage
    private let candidates: [RecognitionClassificationCandidate]
    private let classificationSourceJPEG: Data?

    private let closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let userThumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 32
        return iv
    }()

    private let checksStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 4
        s.distribution = .equalSpacing
        return s
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .appTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .appTextSecondary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let gridContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        v.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return v
    }()

    private let candidatesGrid = RecognitionMatchCandidatesGridView()

    private let seeResultButton: GradientRoundedCTAControl = {
        let b = GradientRoundedCTAControl()
        return b
    }()

    private var premiumObserver: NSObjectProtocol?

    /// - Parameters:
    ///   - userPhoto: Кадр пользователя (как на экране загрузки).
    ///   - candidates: До четырёх кандидатов для сетки и пейджера (URL с API или ассеты-заглушки).
    ///   - classificationSourceJPEG: JPEG, отправленный в `classification/`; для добавления в коллекцию без нового выбора фото.
    init(
        userPhoto: UIImage,
        candidates: [RecognitionClassificationCandidate],
        classificationSourceJPEG: Data? = nil
    ) {
        self.userPhoto = userPhoto
        self.candidates = candidates
        self.classificationSourceJPEG = classificationSourceJPEG
        super.init(nibName: nil, bundle: nil)
    }

    /// Заглушка по ассетам (порядок: герой, затем сетка).
    convenience init(userPhoto: UIImage, candidateAssetNames: [String], resultHeroAssetName: String = "home_popular_insect") {
        var ordered: [String] = []
        for name in [resultHeroAssetName] + candidateAssetNames where !ordered.contains(name) {
            ordered.append(name)
        }
        if ordered.isEmpty {
            ordered = ["home_popular_insect"]
        }
        self.init(
            userPhoto: userPhoto,
            candidates: RecognitionClassificationCandidate.fromLegacyAssetNames(ordered),
            classificationSourceJPEG: nil
        )
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        if let premiumObserver {
            NotificationCenter.default.removeObserver(premiumObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .appBackground

        userThumbnailView.image = userPhoto
        titleLabel.text = L10n.string("scanner.recognition_match.title")
        subtitleLabel.text = L10n.string("scanner.recognition_match.subtitle")
        seeResultButton.setTitle(L10n.string("scanner.recognition_match.see_result"), for: .normal)

        closeButton.setImage(Self.lightCloseImage(), for: .normal)
        closeButton.accessibilityLabel = L10n.string("scanner.close.accessibility")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        seeResultButton.addTarget(self, action: #selector(seeResultTapped), for: .touchUpInside)

        let checkIcon = UIImage(named: "insect_detail_status_harmless")
        for _ in 0..<3 {
            let iv = UIImageView(image: checkIcon)
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.contentMode = .scaleAspectFit
            NSLayoutConstraint.activate([
                iv.widthAnchor.constraint(equalToConstant: 24),
                iv.heightAnchor.constraint(equalToConstant: 24),
            ])
            checksStack.addArrangedSubview(iv)
        }

        candidatesGrid.translatesAutoresizingMaskIntoConstraints = false
        gridContainer.addSubview(candidatesGrid)

        view.addSubview(closeButton)
        view.addSubview(userThumbnailView)
        view.addSubview(checksStack)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(gridContainer)
        view.addSubview(seeResultButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            userThumbnailView.topAnchor.constraint(equalTo: closeButton.topAnchor),
            userThumbnailView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            userThumbnailView.widthAnchor.constraint(equalToConstant: 128),
            userThumbnailView.heightAnchor.constraint(equalToConstant: 128),

            checksStack.topAnchor.constraint(equalTo: userThumbnailView.bottomAnchor, constant: 12),
            checksStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: checksStack.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            gridContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            gridContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            gridContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            gridContainer.bottomAnchor.constraint(equalTo: seeResultButton.topAnchor, constant: -43),

            candidatesGrid.topAnchor.constraint(equalTo: gridContainer.topAnchor),
            candidatesGrid.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor),
            candidatesGrid.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor),
            candidatesGrid.bottomAnchor.constraint(equalTo: gridContainer.bottomAnchor),

            seeResultButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 46),
            seeResultButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -46),
            seeResultButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            seeResultButton.heightAnchor.constraint(equalToConstant: 56),
        ])

        premiumObserver = NotificationCenter.default.addObserver(
            forName: SubscriptionAccess.premiumStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSubscriptionGatedUI()
        }

        updateSubscriptionGatedUI()

        Task { [weak self] in
            guard let self else { return }
            let images = await Self.gridThumbnails(for: self.candidates)
            await MainActor.run { self.candidatesGrid.images = images }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateSubscriptionGatedUI()
    }

    private func updateSubscriptionGatedUI() {
        let locked = !SubscriptionAccess.shared.isPremiumActive
        candidatesGrid.showsPremiumGate = locked
    }

    @objc
    private func closeTapped() {
        navigationController?.dismiss(animated: true) ?? dismiss(animated: true)
    }

    @objc
    private func seeResultTapped() {
        if SubscriptionAccess.shared.isPremiumActive {
            openRecognitionResult()
        } else {
            presentPaywallFullScreen()
        }
    }

    private func openRecognitionResult() {
        let pager = RecognitionResultsPagerViewController(
            candidates: candidates,
            classificationSourceJPEG: classificationSourceJPEG
        )
        navigationController?.pushViewController(pager, animated: true)
    }

    /// Только успешно загруженные превью по кандидатам API (или ассетам заглушки), без дозаполнения до 4.
    private static func gridThumbnails(for candidates: [RecognitionClassificationCandidate]) async -> [UIImage] {
        let slice = Array(candidates.prefix(4))
        var images: [UIImage] = []
        for c in slice {
            if let url = c.thumbnailURL ?? c.heroImageURL, let img = await loadImage(from: url) {
                images.append(img)
            } else if let name = c.thumbnailAssetName, let img = UIImage(named: name) {
                images.append(img)
            }
        }
        return images
    }

    private static func loadImage(from url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else { return nil }
            return UIImage(data: data)
        } catch {
            return nil
        }
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
