//
//  RecognitionNoMatchViewController.swift
//  Bugs
//

import UIKit

/// Нет результата распознавания: светлый фон, иллюстрация по центру, CTA «Попробовать снова».
final class RecognitionNoMatchViewController: UIViewController {

    private let illustrationView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "scanner_no_match_illustration")
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 20, weight: .semibold)
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

    private let centerStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 16
        return s
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let tryAgainButton: GradientRoundedCTAControl = {
        let b = GradientRoundedCTAControl()
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .appBackground

        titleLabel.text = L10n.string("scanner.recognition_no_match.title")
        subtitleLabel.text = L10n.string("scanner.recognition_no_match.subtitle")
        tryAgainButton.setTitle(L10n.string("scanner.recognition_no_match.try_again"), for: .normal)

        closeButton.setImage(Self.lightCloseImage(), for: .normal)
        closeButton.accessibilityLabel = L10n.string("scanner.close.accessibility")
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        tryAgainButton.addTarget(self, action: #selector(tryAgainTapped), for: .touchUpInside)

        centerStack.addArrangedSubview(illustrationView)
        centerStack.setCustomSpacing(20, after: illustrationView)
        centerStack.addArrangedSubview(titleLabel)
        centerStack.setCustomSpacing(8, after: titleLabel)
        centerStack.addArrangedSubview(subtitleLabel)

        view.addSubview(centerStack)
        view.addSubview(tryAgainButton)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            tryAgainButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 46),
            tryAgainButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -46),
            tryAgainButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            tryAgainButton.heightAnchor.constraint(equalToConstant: 56),

            centerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            centerStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            centerStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            centerStack.bottomAnchor.constraint(lessThanOrEqualTo: tryAgainButton.topAnchor, constant: -24),

            illustrationView.widthAnchor.constraint(lessThanOrEqualToConstant: 280),
            illustrationView.heightAnchor.constraint(lessThanOrEqualToConstant: 220),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableInteractivePopGestureIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        restoreInteractivePopGestureIfNeeded()
    }

    @objc
    private func closeTapped() {
        navigationController?.dismiss(animated: true) ?? dismiss(animated: true)
    }

    @objc
    private func tryAgainTapped() {
        navigationController?.popToRootViewController(animated: true)
    }

    /// Круг с обводкой и крестом (#3AA176), для светлого фона.
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
