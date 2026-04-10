//
//  HomePopularInsectCell.swift
//  Bugs
//

import UIKit

final class HomePopularInsectCell: UICollectionViewCell {

    static let reuseIdentifier = "HomePopularInsectCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .appPopularCardTint
        v.layer.cornerRadius = 28
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let insectImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 28
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .appTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.85
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let badgeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardView)
        cardView.addSubview(insectImageView)
        insectImageView.addSubview(badgeImageView)
        cardView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            insectImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            insectImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            insectImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            insectImageView.heightAnchor.constraint(equalToConstant: 101),

            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: insectImageView.bottomAnchor, constant: 8),

            badgeImageView.topAnchor.constraint(equalTo: insectImageView.topAnchor),
            badgeImageView.trailingAnchor.constraint(equalTo: insectImageView.trailingAnchor),
            badgeImageView.widthAnchor.constraint(equalToConstant: 33),
            badgeImageView.heightAnchor.constraint(equalToConstant: 33)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        insectImageView.bringSubviewToFront(badgeImageView)
    }

    func configure(with viewModel: Home.PopularInsectCellViewModel) {
        titleLabel.text = viewModel.title
        RemoteImageLoader.load(
            into: insectImageView,
            placeholderAssetName: viewModel.imageAssetName,
            url: viewModel.imageURL
        )
        if viewModel.badgeAssetName.isEmpty {
            badgeImageView.image = nil
            badgeImageView.isHidden = true
        } else {
            badgeImageView.isHidden = false
            badgeImageView.image = UIImage(named: viewModel.badgeAssetName)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        RemoteImageLoader.cancelLoad(for: insectImageView)
        titleLabel.text = nil
        insectImageView.image = nil
        badgeImageView.image = nil
        badgeImageView.isHidden = false
    }
}
