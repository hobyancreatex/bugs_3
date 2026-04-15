//
//  InsectDetailMyCollectionCell.swift
//  Bugs
//

import UIKit

/// #3AA176 — пунктир ячейки «+» и запасная иконка.
private enum InsectDetailMyCollectionAddStyle {
    static let stroke = UIColor(red: 58 / 255, green: 161 / 255, blue: 118 / 255, alpha: 1)
}

/// Пунктир по периметру ячейки «+»: 2 pt, штрих 5, промежуток 3 (отдельный UIView поверх центра).
private final class InsectDetailMyCollectionDashOverlayView: UIView {

    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = false
        layer.addSublayer(shape)
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = InsectDetailMyCollectionAddStyle.stroke.cgColor
        shape.lineWidth = 2
        shape.lineDashPattern = [5, 3] as [NSNumber]
        shape.lineCap = .butt
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let lw = shape.lineWidth
        let rect = bounds.insetBy(dx: lw / 2, dy: lw / 2)
        let radius = min(24, rect.width / 2, rect.height / 2)
        shape.frame = bounds
        shape.path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
    }
}

final class InsectDetailMyCollectionCell: UICollectionViewCell {

    static let reuseIdentifier = "InsectDetailMyCollectionCell"

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

    private let dashOverlay = InsectDetailMyCollectionDashOverlayView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        contentView.clipsToBounds = false
        contentView.backgroundColor = .clear
        contentView.addSubview(imageView)
        contentView.addSubview(addContainer)
        addContainer.addSubview(centerAddImageView)
        addContainer.addSubview(dashOverlay)

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
            centerAddImageView.widthAnchor.constraint(equalToConstant: 20),
            centerAddImageView.heightAnchor.constraint(equalToConstant: 20),

            dashOverlay.topAnchor.constraint(equalTo: addContainer.topAnchor),
            dashOverlay.leadingAnchor.constraint(equalTo: addContainer.leadingAnchor),
            dashOverlay.trailingAnchor.constraint(equalTo: addContainer.trailingAnchor),
            dashOverlay.bottomAnchor.constraint(equalTo: addContainer.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        nil
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
        dashOverlay.setNeedsLayout()
    }

    private func applyAddCenterImage() {
        if let img = UIImage(named: Self.addCenterImageAssetName) {
            centerAddImageView.image = img.withRenderingMode(.alwaysOriginal)
            centerAddImageView.tintColor = nil
        } else {
            centerAddImageView.image = UIImage(systemName: "plus")?.withRenderingMode(.alwaysTemplate)
            centerAddImageView.tintColor = InsectDetailMyCollectionAddStyle.stroke
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
