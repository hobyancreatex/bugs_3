//
//  ScannerTipsViewController.swift
//  Bugs
//
//  Иллюстрации — PDF в ассетах (замените заглушки своими файлами):
//  scanner_tip_1_wrong, scanner_tip_1_right … scanner_tip_4_wrong, scanner_tip_4_right
//

import UIKit

/// Подсказки по съёмке для сканера: sheet со скроллом, пара «плохо / хорошо» на каждый пункт.
final class ScannerTipsViewController: UIViewController {

    private enum Metrics {
        static let horizontalInset: CGFloat = 20
        static let topInset: CGFloat = 8
        static let titleCloseSpacing: CGFloat = 12
        static let introBottomSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 28
        static let pairSpacing: CGFloat = 12
        static let imageCornerRadius: CGFloat = 16
        static let closeButtonSide: CGFloat = 32
        static let badgeSize: CGFloat = 24
        static let badgeInset: CGFloat = 8
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

        let header = makeHeaderRow()
        let intro = makeIntroLabel()

        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(Metrics.introBottomSpacing, after: header)
        contentStack.addArrangedSubview(intro)

        for spec in Self.tips {
            contentStack.addArrangedSubview(makeTipSection(spec: spec))
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Metrics.topInset),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: Metrics.horizontalInset),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -Metrics.horizontalInset),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * Metrics.horizontalInset),
        ])
    }

    private func makeHeaderRow() -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = L10n.string("scanner.tips.title")
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = UIColor.appSectionTitle
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0

        let close = UIButton(type: .custom)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.setImage(Self.scaledImage(named: "scanner_close", side: Metrics.closeButtonSide), for: .normal)
        close.accessibilityLabel = L10n.string("scanner.close.accessibility")
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        row.addSubview(title)
        row.addSubview(close)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            title.topAnchor.constraint(equalTo: row.topAnchor),
            title.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            title.trailingAnchor.constraint(lessThanOrEqualTo: close.leadingAnchor, constant: -Metrics.titleCloseSpacing),

            close.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            close.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            close.widthAnchor.constraint(equalToConstant: Metrics.closeButtonSide),
            close.heightAnchor.constraint(equalToConstant: Metrics.closeButtonSide),
        ])
        return row
    }

    private func makeIntroLabel() -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = L10n.string("scanner.tips.intro")
        l.font = .preferredFont(forTextStyle: .body)
        l.textColor = UIColor.appTextPrimary
        l.numberOfLines = 0
        l.adjustsFontForContentSizeCategory = true
        return l
    }

    private func makeTipSection(spec: TipSpec) -> UIView {
        let block = UIView()
        block.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = L10n.string(spec.titleKey)
        let bodyMetrics = UIFontMetrics(forTextStyle: .body)
        title.font = bodyMetrics.scaledFont(for: UIFont.systemFont(ofSize: 17, weight: .semibold))
        title.textColor = UIColor.appTextPrimary
        title.numberOfLines = 0
        title.adjustsFontForContentSizeCategory = true

        let pairRow = UIStackView()
        pairRow.translatesAutoresizingMaskIntoConstraints = false
        pairRow.axis = .horizontal
        pairRow.spacing = Metrics.pairSpacing
        pairRow.distribution = .fillEqually
        pairRow.alignment = .fill

        pairRow.addArrangedSubview(comparisonCell(assetName: spec.wrongAsset, isPositive: false))
        pairRow.addArrangedSubview(comparisonCell(assetName: spec.rightAsset, isPositive: true))

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

    private func comparisonCell(assetName: String, isPositive: Bool) -> UIView {
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

        let badge = badgeView(isPositive: isPositive)
        wrap.addSubview(badge)

        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: wrap.topAnchor),
            iv.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            iv.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),

            wrap.heightAnchor.constraint(equalTo: wrap.widthAnchor),

            badge.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -Metrics.badgeInset),
            badge.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -Metrics.badgeInset),
            badge.widthAnchor.constraint(equalToConstant: Metrics.badgeSize),
            badge.heightAnchor.constraint(equalToConstant: Metrics.badgeSize),
        ])
        return wrap
    }

    private func badgeView(isPositive: Bool) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = isPositive ? UIColor.appHarmlessGreen : UIColor.appPoisonousRed
        v.layer.cornerRadius = Metrics.badgeSize / 2

        let symbolName = isPositive ? "checkmark" : "xmark"
        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        let iv = UIImageView(image: UIImage(systemName: symbolName, withConfiguration: cfg))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit

        v.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 14),
            iv.heightAnchor.constraint(equalToConstant: 14),
        ])
        return v
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
