//
//  HomeCategoryCell.swift
//  Bugs
//

import UIKit

final class HomeCategoryCell: UICollectionViewCell {

    static let reuseIdentifier = "HomeCategoryCell"

    private let circleView: UIView = {
        let v = UIView()
        v.backgroundColor = .appCategoryCircle
        v.layer.cornerRadius = 28
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
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
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(circleView)
        circleView.addSubview(iconView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            circleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            circleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 56),
            circleView.heightAnchor.constraint(equalToConstant: 56),

            iconView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(with viewModel: Home.CategoryCellViewModel) {
        contentView.alpha = 1
        isUserInteractionEnabled = true
        titleLabel.text = viewModel.title
        RemoteImageLoader.load(
            into: iconView,
            placeholderAssetName: viewModel.imageAssetName,
            url: viewModel.imageURL
        )
    }

    /// Invisible cell that keeps grid slot (Library incomplete rows).
    func configureAsSpacer() {
        RemoteImageLoader.cancelLoad(for: iconView)
        contentView.alpha = 0
        isUserInteractionEnabled = false
        titleLabel.text = nil
        iconView.image = nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        RemoteImageLoader.cancelLoad(for: iconView)
        contentView.alpha = 1
        isUserInteractionEnabled = true
        titleLabel.text = nil
        iconView.image = nil
    }
}
