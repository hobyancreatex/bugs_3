//
//  OnboardingIntroPageCollectionViewCell.swift
//  Bugs
//

import UIKit

/// Первая страница: `bug_happy` (гибкая высота), заголовок, подзаголовок, стек бенефитов.
final class OnboardingIntroPageCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "OnboardingIntroPageCollectionViewCell"

    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.image = UIImage(named: "bug_happy")
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return iv
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
        l.textColor = .appTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let benefitsStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 12
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .appBackground

        contentView.addSubview(heroImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(benefitsStack)

        let benefitKeys = [
            "onboarding.intro.benefit.identify",
            "onboarding.intro.benefit.collection",
            "onboarding.intro.benefit.achievements",
            "onboarding.intro.benefit.ai",
            "onboarding.intro.benefit.articles",
        ]
        for key in benefitKeys {
            benefitsStack.addArrangedSubview(OnboardingBenefitRowView(text: L10n.string(key)))
        }

        NSLayoutConstraint.activate([
            benefitsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            benefitsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            benefitsStack.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -138),

            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            subtitleLabel.bottomAnchor.constraint(equalTo: benefitsStack.topAnchor, constant: -19),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -16),

            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroImageView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 12),
            heroImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -6),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure() {
        titleLabel.text = L10n.string("onboarding.intro.title")
        subtitleLabel.text = L10n.string("onboarding.intro.subtitle")
    }
}
