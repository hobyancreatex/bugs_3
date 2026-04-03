//
//  CategoryInsectsCell.swift
//  Bugs
//

import UIKit

final class CategoryInsectsCell: UICollectionViewCell {

    static let reuseIdentifier = "CategoryInsectsCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .appInsectListCellTint
        v.layer.cornerRadius = 24
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 28
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .appTextPrimary
        l.numberOfLines = 2
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .appTextSecondary
        l.numberOfLines = 2
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var textStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .fill
        s.distribution = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "insect_list_chevron"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardView)
        cardView.addSubview(coverImageView)
        cardView.addSubview(textStack)
        cardView.addSubview(chevronView)

        let imageSide: CGFloat = 72

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            coverImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            coverImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: imageSide),
            coverImageView.heightAnchor.constraint(equalToConstant: imageSide),

            chevronView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 20),
            chevronView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            textStack.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        subtitleLabel.text = nil
        coverImageView.image = nil
    }

    func configure(with viewModel: CategoryInsects.InsectCellViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        coverImageView.image = UIImage(named: viewModel.imageAssetName)
    }
}
