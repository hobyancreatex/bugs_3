//
//  OnboardingBenefitRowView.swift
//  Bugs
//

import UIKit

/// Строка бенефита: фон #BAAE47 @ 6 %, скругление 24, текст + галочка как на экране совпадения.
final class OnboardingBenefitRowView: UIView {

    /// Фиксированные вертикальные отступы: высота ряда одинаковая для всех плашек; длинный текст поджимается по ширине.
    private static let labelVerticalInset: CGFloat = 16

    private var titleLabelTopConstraint: NSLayoutConstraint!
    /// Высота ряда = высота лейбла + отступ сверху + такой же снизу (без `titleLabel.bottom`).
    private var rowHeightExtraConstraint: NSLayoutConstraint!

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .appTextPrimary
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.72
        l.baselineAdjustment = .alignCenters
        l.lineBreakMode = .byTruncatingTail
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
        // В вертикальном UIStackView не даем ряду растягиваться: лишнее место должна забирать hero-картинка.
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.text = text

        addSubview(titleLabel)
        addSubview(checkView)

        let topInset = Self.labelVerticalInset
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

    required init?(coder: NSCoder) {
        nil
    }
}
