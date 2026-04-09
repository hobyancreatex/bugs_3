//
//  OnboardingOutroPageCollectionViewCell.swift
//  Bugs
//

import UIKit

/// Вторая страница онбординга (без списка бенефитов).
final class OnboardingOutroPageCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "OnboardingOutroPageCollectionViewCell"

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .appBackground

        contentView.addSubview(heroImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

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
        titleLabel.text = L10n.string("onboarding.outro.title")
        subtitleLabel.text = L10n.string("onboarding.outro.subtitle")
    }
}
