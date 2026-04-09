//
//  OnboardingBenefitRowView.swift
//  Bugs
//

import UIKit

/// Строка бенефита: фон #BAAE47 @ 6 %, скругление 24, текст + галочка как на экране совпадения.
final class OnboardingBenefitRowView: UIView {

    private static let labelTopInsetRegular: CGFloat = 22.5
    private static let labelTopInsetCompactScreen: CGFloat = 4
    private static let compactScreenHeightThreshold: CGFloat = 700

    private var titleLabelTopConstraint: NSLayoutConstraint!
    /// Высота ряда = высота лейбла + отступ сверху + такой же снизу (без `titleLabel.bottom`).
    private var rowHeightExtraConstraint: NSLayoutConstraint!

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .appTextPrimary
        l.numberOfLines = 0
        return l
    }()

    private let checkView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "insect_detail_status_harmless"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    init(text: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .appInsectListCellTint
        layer.cornerRadius = 24
        clipsToBounds = true
        titleLabel.text = text

        addSubview(titleLabel)
        addSubview(checkView)

        let topInset = Self.labelTopInsetRegular
        titleLabelTopConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: topInset)
        rowHeightExtraConstraint = heightAnchor.constraint(
            equalTo: titleLabel.heightAnchor,
            constant: topInset * 2
        )

        NSLayoutConstraint.activate([
            checkView.widthAnchor.constraint(equalToConstant: 20),
            checkView.heightAnchor.constraint(equalToConstant: 20),
            checkView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            checkView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            titleLabelTopConstraint,
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: checkView.leadingAnchor, constant: -8),

            rowHeightExtraConstraint,
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = window?.windowScene?.screen.bounds.height ?? UIScreen.main.bounds.height
        let topInset = h < Self.compactScreenHeightThreshold ? Self.labelTopInsetCompactScreen : Self.labelTopInsetRegular
        if titleLabelTopConstraint.constant != topInset {
            titleLabelTopConstraint.constant = topInset
        }
        let rowExtra = topInset * 2
        if rowHeightExtraConstraint.constant != rowExtra {
            rowHeightExtraConstraint.constant = rowExtra
        }
    }

    required init?(coder: NSCoder) {
        nil
    }
}
