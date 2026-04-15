//
//  InsectDetailMyCollectionCell.swift
//  Bugs
//

import UIKit

final class InsectDetailMyCollectionCell: UICollectionViewCell {

    static let reuseIdentifier = "InsectDetailMyCollectionCell"

    /// Добавьте `insect_detail_my_collection_add` в Assets (PDF/PNG); пока файла нет — показываем SF Symbol.
    private static let addCenterImageAssetName = "insect_detail_my_collection_add"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 24
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let addContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 24
        v.backgroundColor = .clear
        v.clipsToBounds = false
        return v
    }()

    private let centerAddImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// Как у рамки выреза на распознавании: 2 pt, штрих 12, промежуток 6, скруглённые концы.
    private let dashLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.appReadMore.cgColor
        shape.lineWidth = 2
        shape.lineDashPattern = [12, 6] as [NSNumber]
        shape.lineCap = .round
        return shape
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(imageView)
        contentView.addSubview(addContainer)
        addContainer.layer.addSublayer(dashLayer)
        addContainer.addSubview(centerAddImageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            addContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            addContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            addContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            addContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            centerAddImageView.centerXAnchor.constraint(equalTo: addContainer.centerXAnchor),
            centerAddImageView.centerYAnchor.constraint(equalTo: addContainer.centerYAnchor),
            centerAddImageView.widthAnchor.constraint(equalToConstant: 36),
            centerAddImageView.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashLayer.frame = addContainer.bounds
        let inset = dashLayer.lineWidth / 2
        let rect = addContainer.bounds.insetBy(dx: inset, dy: inset)
        let radius: CGFloat = 24
        let path = UIBezierPath(roundedRect: rect, cornerRadius: min(radius, rect.width / 2, rect.height / 2))
        dashLayer.path = path.cgPath
    }

    func configureImage(url: URL?) {
        addContainer.isHidden = true
        imageView.isHidden = false
        RemoteImageLoader.load(into: imageView, url: url)
    }

    func configureAddAction() {
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = nil
        imageView.isHidden = true
        addContainer.isHidden = false
        applyAddCenterImage()
    }

    private func applyAddCenterImage() {
        if let img = UIImage(named: Self.addCenterImageAssetName) {
            centerAddImageView.image = img
            centerAddImageView.tintColor = nil
        } else {
            centerAddImageView.image = UIImage(systemName: "plus.circle.fill")?.withRenderingMode(.alwaysTemplate)
            centerAddImageView.tintColor = .appReadMore
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        RemoteImageLoader.cancelLoad(for: imageView)
        imageView.image = nil
        imageView.isHidden = false
        addContainer.isHidden = true
    }
}
