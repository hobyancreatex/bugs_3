//
//  OnboardingBenefitRowView.swift
//  Bugs
//

import UIKit

/// Строка бенефита: фон #BAAE47 @ 6 %, скругление 24, текст + галочка как на экране совпадения.
final class OnboardingBenefitRowView: UIView {

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

        NSLayoutConstraint.activate([
            checkView.widthAnchor.constraint(equalToConstant: 20),
            checkView.heightAnchor.constraint(equalToConstant: 20),
            checkView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            checkView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 22.5),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -22.5),
            titleLabel.trailingAnchor.constraint(equalTo: checkView.leadingAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }
}
