//
//  ScannerTipsViewController.swift
//  Bugs
//
//  Иллюстрации — PDF в ассетах (замените заглушки своими файлами):
//  scanner_tip_1_wrong, scanner_tip_1_right … scanner_tip_4_wrong, scanner_tip_4_right
//

import UIKit

/// Подсказки по съёмке для сканера: sheet со скроллом, пара иллюстраций на каждый пункт (маркеры только в ассетах).
final class ScannerTipsViewController: UIViewController {

    private enum Metrics {
        static let horizontalInset: CGFloat = 20
        /// Отступ кнопки закрытия от верха контента скролла.
        static let closeTopInset: CGFloat = 25
        /// Отступ вводного текста от нижнего края кнопки закрытия.
        static let introOffsetFromClose: CGFloat = 20
        static let titleCloseSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 28
        static let pairSpacing: CGFloat = 12
        static let imageCornerRadius: CGFloat = 16
        static let closeButtonSide: CGFloat = 32
        static let fontSize: CGFloat = 16
        /// #272734
        static let screenTitleColor = UIColor(red: 39 / 255, green: 39 / 255, blue: 52 / 255, alpha: 1)
        static let bodyTextColor = UIColor.black
    }

    private struct TipSpec {
        let titleKey: String
        let wrongAsset: String
        let rightAsset: String
    }

    private static let tips: [TipSpec] = [
        TipSpec(titleKey: "scanner.tips.1.title", wrongAsset: "scanner_tip_1_wrong", rightAsset: "scanner_tip_1_right"),
        TipSpec(titleKey: "scanner.tips.2.title", wrongAsset: "scanner_tip_2_wrong", rightAsset: "scanner_tip_2_right"),
        TipSpec(titleKey: "scanner.tips.3.title", wrongAsset: "scanner_tip_3_wrong", rightAsset: "scanner_tip_3_right"),
        TipSpec(titleKey: "scanner.tips.4.title", wrongAsset: "scanner_tip_4_wrong", rightAsset: "scanner_tip_4_right"),
    ]

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.alwaysBounceVertical = true
        return s
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.spacing = Metrics.sectionSpacing
        s.alignment = .fill
        return s
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        overrideUserInterfaceStyle = .light

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(makeTopSection())

        for spec in Self.tips {
            contentStack.addArrangedSubview(makeTipSection(spec: spec))
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: Metrics.horizontalInset),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -Metrics.horizontalInset),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * Metrics.horizontalInset),
        ])
    }

    private func makeTopSection() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = L10n.string("scanner.tips.title")
        let titleMetrics = UIFontMetrics(forTextStyle: .body)
        title.font = titleMetrics.scaledFont(for: UIFont.systemFont(ofSize: Metrics.fontSize, weight: .bold))
        title.textColor = Metrics.screenTitleColor
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0

        let close = UIButton(type: .custom)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.setImage(Self.scaledImage(named: "scanner_close", side: Metrics.closeButtonSide), for: .normal)
        close.accessibilityLabel = L10n.string("scanner.close.accessibility")
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        let intro = UILabel()
        intro.translatesAutoresizingMaskIntoConstraints = false
        intro.text = L10n.string("scanner.tips.intro")
        let introMetrics = UIFontMetrics(forTextStyle: .body)
        intro.font = introMetrics.scaledFont(for: UIFont.systemFont(ofSize: Metrics.fontSize, weight: .regular))
        intro.textColor = Metrics.bodyTextColor
        intro.numberOfLines = 0
        intro.adjustsFontForContentSizeCategory = true

        container.addSubview(title)
        container.addSubview(close)
        container.addSubview(intro)

        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: container.topAnchor, constant: Metrics.closeTopInset),
            close.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            close.widthAnchor.constraint(equalToConstant: Metrics.closeButtonSide),
            close.heightAnchor.constraint(equalToConstant: Metrics.closeButtonSide),

            title.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            title.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            title.trailingAnchor.constraint(lessThanOrEqualTo: close.leadingAnchor, constant: -Metrics.titleCloseSpacing),

            intro.topAnchor.constraint(equalTo: close.bottomAnchor, constant: Metrics.introOffsetFromClose),
            intro.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            intro.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            intro.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    private func makeTipSection(spec: TipSpec) -> UIView {
        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = L10n.string(spec.titleKey)
        let tipMetrics = UIFontMetrics(forTextStyle: .body)
        title.font = tipMetrics.scaledFont(for: UIFont.systemFont(ofSize: Metrics.fontSize, weight: .regular))
        title.textColor = Metrics.bodyTextColor
        title.numberOfLines = 0
        title.adjustsFontForContentSizeCategory = true

        let pairRow = UIStackView()
        pairRow.translatesAutoresizingMaskIntoConstraints = false
        pairRow.axis = .horizontal
        pairRow.spacing = Metrics.pairSpacing
        pairRow.distribution = .fillEqually
        pairRow.alignment = .fill

        pairRow.addArrangedSubview(comparisonCell(assetName: spec.wrongAsset))
        pairRow.addArrangedSubview(comparisonCell(assetName: spec.rightAsset))

        block.addSubview(title)
        block.addSubview(pairRow)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: block.topAnchor),
            title.leadingAnchor.constraint(equalTo: block.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: block.trailingAnchor),

            pairRow.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            pairRow.leadingAnchor.constraint(equalTo: block.leadingAnchor),
            pairRow.trailingAnchor.constraint(equalTo: block.trailingAnchor),
            pairRow.bottomAnchor.constraint(equalTo: block.bottomAnchor),
        ])
        return block
    }

    private func comparisonCell(assetName: String) -> UIView {
        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        wrap.backgroundColor = UIColor(white: 0.94, alpha: 1)
        wrap.layer.cornerRadius = Metrics.imageCornerRadius
        wrap.clipsToBounds = true

        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        if let img = UIImage(named: assetName) {
            iv.image = img
            wrap.backgroundColor = .clear
        }

        wrap.addSubview(iv)

        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: wrap.topAnchor),
            iv.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            iv.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),

            wrap.heightAnchor.constraint(equalTo: wrap.widthAnchor),
        ])
        return wrap
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
    }

    private static func scaledImage(named: String, side: CGFloat) -> UIImage? {
        guard let img = UIImage(named: named) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = UITraitCollection.current.displayScale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: CGSize(width: side, height: side)))
        }
    }
}
