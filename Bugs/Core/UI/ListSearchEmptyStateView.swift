//
//  ListSearchEmptyStateView.swift
//  Bugs
//

import UIKit

/// Vertical stack: 86×86 image (centered), 16pt, multiline title + subtitle (8pt) with full horizontal width for wrapping.
final class ListSearchEmptyStateView: UIView {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private var imageWidthConstraint: NSLayoutConstraint!
    private var imageHeightConstraint: NSLayoutConstraint!
    private var imageContainerHeightConstraint: NSLayoutConstraint!

    private let imageContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .appTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .appTextSecondary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var textStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 8
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var rootStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [imageContainer, textStack])
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 16
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        let defaultSide: CGFloat = 86
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: defaultSide)
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: defaultSide)
        imageContainerHeightConstraint = imageContainer.heightAnchor.constraint(equalToConstant: defaultSide)

        imageContainer.addSubview(imageView)
        addSubview(rootStack)
        NSLayoutConstraint.activate([
            imageWidthConstraint,
            imageHeightConstraint,
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            imageContainerHeightConstraint,

            rootStack.topAnchor.constraint(equalTo: topAnchor),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
        imageView.image = UIImage(named: "list_search_empty")
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(title: String, subtitle: String) {
        configure(title: title, subtitle: subtitle, imageAssetName: "list_search_empty", imageSide: 86)
    }

    /// Каталог поиска: `list_search_empty`. Профиль и др.: свой ассет и размер иллюстрации (pt).
    func configure(title: String, subtitle: String, imageAssetName: String, imageSide: CGFloat) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        if let img = UIImage(named: imageAssetName) {
            imageView.image = img
        } else {
            imageView.image = UIImage(named: "list_search_empty")
        }
        imageWidthConstraint.constant = imageSide
        imageHeightConstraint.constant = imageSide
        imageContainerHeightConstraint.constant = imageSide
    }
}
