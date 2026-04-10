//
//  RecognitionProgressViewController.swift
//  Bugs
//

import Lottie
import UIKit

/// Прогресс распознавания: фото на фоне, полноэкранный блюр как на сканере, по центру — Lottie «loading» как на лаунче (зациклено).
final class RecognitionProgressViewController: UIViewController {

    private let backgroundImage: UIImage

    private var classificationTask: Task<Void, Never>?
    private var didStartClassification = false

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let blurOverlay = ScannerStyleFullBlurOverlayView()

    private let closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let centerStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 12
        return s
    }()

    private let loadingAnimationView: LottieAnimationView = {
        let v = LottieAnimationView(name: "loading", bundle: .main)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        v.contentMode = .scaleAspectFit
        v.loopMode = .loop
        v.backgroundBehavior = .pauseAndRestore
        return v
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    /// - Parameter backgroundImage: Кадр с камеры или из галереи.
    init(backgroundImage: UIImage) {
        self.backgroundImage = backgroundImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = .black

        imageView.image = backgroundImage
        messageLabel.text = L10n.string("scanner.recognition_progress.message")
        closeButton.setImage(Self.scaledCloseImage(), for: .normal)
        closeButton.accessibilityLabel = L10n.string("scanner.close.accessibility")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        centerStack.addArrangedSubview(loadingAnimationView)
        centerStack.addArrangedSubview(messageLabel)

        view.addSubview(imageView)
        view.addSubview(blurOverlay)
        view.addSubview(centerStack)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            blurOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            blurOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            centerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            centerStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            centerStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            loadingAnimationView.widthAnchor.constraint(equalToConstant: 88),
            loadingAnimationView.heightAnchor.constraint(equalToConstant: 88),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadingAnimationView.play()
        startClassificationIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        loadingAnimationView.pause()
        classificationTask?.cancel()
        classificationTask = nil
    }

    private func startClassificationIfNeeded() {
        guard !didStartClassification else { return }
        didStartClassification = true

        classificationTask = Task { [weak self] in
            guard let self else { return }
            guard let jpeg = Self.jpegDataForClassificationUpload(self.backgroundImage) else {
                await MainActor.run { self.navigateAfterFailure() }
                return
            }
            do {
                let data = try await CollectAPIClient.shared.postClassification(imageJPEGData: jpeg)
                await MainActor.run { self.navigateAfterSuccess(responseData: data) }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run { self.navigateAfterFailure() }
            }
        }
    }

    private func navigateAfterSuccess(responseData: Data) {
        let candidates: [RecognitionClassificationCandidate]
        do {
            let root = try CollectClassificationParsing.decode(responseData)
            candidates = CollectClassificationParsing.candidates(from: root)
        } catch {
            navigateAfterFailure()
            return
        }
        guard !candidates.isEmpty else {
            navigateAfterFailure()
            return
        }
        guard let nav = navigationController, nav.topViewController === self else { return }
        _ = SubscriptionManager.shared.checkSubscriptionStatus()
        if SubscriptionAccess.shared.isPremiumActive {
            let pager = RecognitionResultsPagerViewController(candidates: candidates)
            nav.pushViewController(pager, animated: true)
            return
        }
        let match = RecognitionMatchFoundViewController(userPhoto: backgroundImage, candidates: candidates)
        nav.pushViewController(match, animated: true)
    }

    private func navigateAfterFailure() {
        guard let nav = navigationController, nav.topViewController === self else { return }
        nav.pushViewController(RecognitionNoMatchViewController(), animated: true)
    }

    /// Длинная сторона не больше 2048 pt, JPEG ~0.88 — умеренный размер тела запроса.
    private static func jpegDataForClassificationUpload(_ image: UIImage) -> Data? {
        let maxSide: CGFloat = 2048
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return scaled.jpegData(compressionQuality: 0.88)
    }

    @objc
    private func closeTapped() {
        // Закрываем весь флоу сканера (представленный nav), а не возврат на камеру.
        navigationController?.dismiss(animated: true) ?? dismiss(animated: true)
    }

    private static func scaledCloseImage() -> UIImage? {
        guard let img = UIImage(named: "scanner_close") else { return nil }
        let side: CGFloat = 32
        let format = UIGraphicsImageRendererFormat()
        format.scale = UITraitCollection.current.displayScale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: CGSize(width: side, height: side)))
        }
    }
}
