//
//  InsectDetailCharacteristicCell.swift
//  Bugs
//

import UIKit

final class InsectDetailCharacteristicCell: UITableViewCell {

    static let reuseIdentifier = "InsectDetailCharacteristicCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .appCharacteristicTitle
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .appCharacteristicValue
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let leftWrapper: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let rightWrapper: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let rowStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .top
        s.spacing = 0
        s.distribution = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        leftWrapper.addSubview(titleLabel)
        rightWrapper.addSubview(valueLabel)
        rowStack.addArrangedSubview(leftWrapper)
        rowStack.addArrangedSubview(rightWrapper)
        contentView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: rowStack.bottomAnchor, constant: 8),

            leftWrapper.widthAnchor.constraint(equalTo: rowStack.widthAnchor, multiplier: 0.35),
            rightWrapper.widthAnchor.constraint(equalTo: rowStack.widthAnchor, multiplier: 0.65),

            titleLabel.topAnchor.constraint(equalTo: leftWrapper.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: leftWrapper.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: leftWrapper.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: leftWrapper.trailingAnchor),

            valueLabel.topAnchor.constraint(equalTo: rightWrapper.topAnchor, constant: 8),
            valueLabel.bottomAnchor.constraint(equalTo: rightWrapper.bottomAnchor, constant: -8),
            valueLabel.leadingAnchor.constraint(equalTo: rightWrapper.leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: rightWrapper.trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        valueLabel.text = nil
        contentView.backgroundColor = .clear
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let w = targetSize.width > 0 ? targetSize.width : bounds.width
        let fit = contentView.systemLayoutSizeFitting(
            CGSize(width: w, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: w, height: max(49, ceil(fit.height)))
    }

    func configure(title: String, value: String, rowIndex: Int) {
        titleLabel.text = title
        valueLabel.text = value
        let tinted = rowIndex % 2 == 0
        contentView.backgroundColor = tinted ? .appCharacteristicsRowAlternate : .clear
        setNeedsLayout()
    }
}
