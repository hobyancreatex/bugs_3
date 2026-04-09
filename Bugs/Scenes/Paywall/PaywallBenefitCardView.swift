//
//  PaywallBenefitCardView.swift
//  Bugs
//

import UIKit

/// Карточка бенефита на пейволе: 80 pt, радиус 24, тинт #BAAE47 @ 6 %.
final class PaywallBenefitCardView: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let captionLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .appTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 2
        l.lineBreakMode = .byTruncatingTail
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        l.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return l
    }()

    init(imageName: String, captionKey: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .appInsectListCellTint
        layer.cornerRadius = 24
        clipsToBounds = true

        iconView.image = UIImage(named: imageName)
        captionLabel.text = L10n.string(captionKey)

        let stack = UIStackView(arrangedSubviews: [iconView, captionLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4

        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 80),

            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }
}
