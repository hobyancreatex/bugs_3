//
//  InsectImageGalleryCells.swift
//  Bugs
//

import UIKit

final class InsectImageGalleryPageCell: UICollectionViewCell {

    static let reuseIdentifier = "InsectImageGalleryPageCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .appBackground
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configureRemote(url: URL) {
        RemoteImageLoader.load(into: imageView, url: url)
    }

    func configureLocal(image: UIImage?) {
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = image
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = nil
    }
}

final class InsectImageGalleryThumbnailCell: UICollectionViewCell {

    static let reuseIdentifier = "InsectImageGalleryThumbnailCell"

    private static let selectionBorder = UIColor.appReadMore.cgColor
    private static let borderWidth: CGFloat = 3

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configureRemote(url: URL, selected: Bool) {
        RemoteImageLoader.load(into: imageView, url: url)
        applySelection(selected: selected)
    }

    func configureLocal(image: UIImage?, selected: Bool) {
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = image
        applySelection(selected: selected)
    }

    func applySelection(selected: Bool) {
        imageView.layer.borderWidth = selected ? Self.borderWidth : 0
        imageView.layer.borderColor = selected ? Self.selectionBorder : nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = nil
        imageView.layer.borderWidth = 0
    }
}
