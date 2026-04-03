//
//  InsectDetailGalleryCell.swift
//  Bugs
//

import UIKit

final class InsectDetailGalleryCell: UICollectionViewCell {

    static let reuseIdentifier = "InsectDetailGalleryCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 32
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(imageAssetName: String) {
        imageView.image = UIImage(named: imageAssetName)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
