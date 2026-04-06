//
//  InsectDetailCharacteristicCell.swift
//  Bugs
//

import UIKit

final class InsectDetailCharacteristicCell: UITableViewCell {

    static let reuseIdentifier = "InsectDetailCharacteristicCell"

    private var modelTitle = ""
    private var modelValue = ""

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .appCharacteristicTitle
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .appCharacteristicValue
        l.numberOfLines = 0
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
        s.alignment = .center
        s.spacing = 0
        s.distribution = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private var compactHeightConstraint: NSLayoutConstraint!
    private var rowStackTopExpand: NSLayoutConstraint!
    private var rowStackBottomExpand: NSLayoutConstraint!
    private var rowStackCenterYCompact: NSLayoutConstraint!
    private var rowStackTopCompactGE: NSLayoutConstraint!
    private var rowStackBottomCompactLE: NSLayoutConstraint!
    private var titleTopConstraint: NSLayoutConstraint!
    private var titleBottomConstraint: NSLayoutConstraint!
    private var valueTopConstraint: NSLayoutConstraint!
    private var valueBottomConstraint: NSLayoutConstraint!

    private var layoutIsCompact = false

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

        rowStackTopExpand = rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        rowStackBottomExpand = contentView.bottomAnchor.constraint(equalTo: rowStack.bottomAnchor, constant: 8)
        rowStackCenterYCompact = rowStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        rowStackTopCompactGE = rowStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 4)
        rowStackBottomCompactLE = rowStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4)
        compactHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 49)

        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: leftWrapper.topAnchor, constant: 8)
        titleBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: leftWrapper.bottomAnchor, constant: -8)
        valueTopConstraint = valueLabel.topAnchor.constraint(equalTo: rightWrapper.topAnchor, constant: 8)
        valueBottomConstraint = valueLabel.bottomAnchor.constraint(equalTo: rightWrapper.bottomAnchor, constant: -8)

        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            leftWrapper.widthAnchor.constraint(equalTo: rowStack.widthAnchor, multiplier: 0.35),
            rightWrapper.widthAnchor.constraint(equalTo: rowStack.widthAnchor, multiplier: 0.65),

            titleTopConstraint,
            titleBottomConstraint,
            titleLabel.leadingAnchor.constraint(equalTo: leftWrapper.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: leftWrapper.trailingAnchor),

            valueTopConstraint,
            valueBottomConstraint,
            valueLabel.leadingAnchor.constraint(equalTo: rightWrapper.leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: rightWrapper.trailingAnchor, constant: -16)
        ])

        rowStackTopExpand.isActive = true
        rowStackBottomExpand.isActive = true
        compactHeightConstraint.isActive = false
        rowStackCenterYCompact.isActive = false
        rowStackTopCompactGE.isActive = false
        rowStackBottomCompactLE.isActive = false
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        modelTitle = ""
        modelValue = ""
        titleLabel.text = nil
        valueLabel.text = nil
        titleLabel.numberOfLines = 2
        valueLabel.numberOfLines = 2
        contentView.backgroundColor = .clear
        setExpandedLayoutConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyLineLimits(contentWidth: bounds.width)
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let w = targetSize.width > 0 ? targetSize.width : bounds.width
        applyLineLimits(contentWidth: w)
        if layoutIsCompact {
            return CGSize(width: w, height: 49)
        }
        let fit = contentView.systemLayoutSizeFitting(
            CGSize(width: w, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: w, height: max(49, ceil(fit.height)))
    }

    func configure(title: String, value: String, rowIndex: Int) {
        modelTitle = title
        modelValue = value
        titleLabel.text = title
        valueLabel.text = value
        let tinted = rowIndex % 2 == 0
        contentView.backgroundColor = tinted ? .appCharacteristicsRowAlternate : .clear
        setNeedsLayout()
    }

    private func applyLineLimits(contentWidth: CGFloat) {
        guard contentWidth > 0 else { return }
        let leftColW = contentWidth * 0.35
        let rightColW = contentWidth * 0.65
        let titleW = max(0, leftColW - 16)
        let valueW = max(0, rightColW - 16 - 16)

        let titleFont = titleLabel.font ?? .systemFont(ofSize: 14, weight: .semibold)
        let valueFont = valueLabel.font ?? .systemFont(ofSize: 14, weight: .regular)

        let titleLines = Self.lineCount(text: modelTitle, width: titleW, font: titleFont)
        let valueLines = Self.lineCount(text: modelValue, width: valueW, font: valueFont)
        let isCompact = titleLines < 3 && valueLines < 3

        titleLabel.numberOfLines = titleLines > 2 ? 0 : 2
        valueLabel.numberOfLines = valueLines > 2 ? 0 : 2

        if isCompact != layoutIsCompact {
            layoutIsCompact = isCompact
            if isCompact {
                setCompactLayoutConstraints()
            } else {
                setExpandedLayoutConstraints()
            }
        }
    }

    private func setCompactLayoutConstraints() {
        rowStackTopExpand.isActive = false
        rowStackBottomExpand.isActive = false
        rowStackCenterYCompact.isActive = true
        rowStackTopCompactGE.isActive = true
        rowStackBottomCompactLE.isActive = true
        compactHeightConstraint.isActive = true
        titleTopConstraint.constant = 0
        titleBottomConstraint.constant = 0
        valueTopConstraint.constant = 0
        valueBottomConstraint.constant = 0
    }

    private func setExpandedLayoutConstraints() {
        layoutIsCompact = false
        rowStackCenterYCompact.isActive = false
        rowStackTopCompactGE.isActive = false
        rowStackBottomCompactLE.isActive = false
        compactHeightConstraint.isActive = false
        rowStackTopExpand.isActive = true
        rowStackBottomExpand.isActive = true
        titleTopConstraint.constant = 8
        titleBottomConstraint.constant = -8
        valueTopConstraint.constant = 8
        valueBottomConstraint.constant = -8
    }

    private static func lineCount(text: String, width: CGFloat, font: UIFont) -> Int {
        guard !text.isEmpty, width > 0 else { return 0 }
        let h = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height
        return Int(ceil(h / font.lineHeight))
    }
}
