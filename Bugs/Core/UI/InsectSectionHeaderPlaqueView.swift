//
//  InsectSectionHeaderPlaqueView.swift
//  Bugs
//

import UIKit

/// Горизонтальная плашка 28 pt: прижата к левому краю, скругление только справа (радиус 14).
final class InsectSectionHeaderPlaqueView: UIView {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .appSectionPlaqueTeal
        layer.cornerRadius = 14
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        clipsToBounds = true
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setTitle(_ text: String) {
        titleLabel.text = text
    }
}
