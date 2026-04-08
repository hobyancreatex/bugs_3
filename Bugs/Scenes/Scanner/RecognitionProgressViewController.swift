//
//  RecognitionProgressViewController.swift
//  Bugs
//

import UIKit

/// Прогресс распознавания: фото на фоне, полноэкранный блюр как на сканере, закрытие и центральный стек.
final class RecognitionProgressViewController: UIViewController {

    private let backgroundImage: UIImage
    private let iconAssetName: String

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

    private let progressIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
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

    /// - Parameters:
    ///   - backgroundImage: Кадр с камеры или из галереи.
    ///   - iconAssetName: Иллюстрация над текстом (по умолчанию та же, что в популярных на главной).
    init(backgroundImage: UIImage, iconAssetName: String = "home_popular_insect") {
        self.backgroundImage = backgroundImage
        self.iconAssetName = iconAssetName
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
        progressIconView.image = UIImage(named: iconAssetName)
        messageLabel.text = L10n.string("scanner.recognition_progress.message")
        closeButton.setImage(Self.scaledCloseImage(), for: .normal)
        closeButton.accessibilityLabel = L10n.string("scanner.close.accessibility")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        centerStack.addArrangedSubview(progressIconView)
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

            progressIconView.widthAnchor.constraint(equalToConstant: 88),
            progressIconView.heightAnchor.constraint(equalToConstant: 88),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
