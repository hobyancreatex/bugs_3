//
//  InsectDetailHeroPageIndicatorView.swift
//  Bugs
//

import UIKit

/// Индикатор страниц на герое: h=20, выбранный 30×20 (#3AA176), остальные 20×20 (#524C43 40%).
final class InsectDetailHeroPageIndicatorView: UIView {

    var onSelectPage: ((Int) -> Void)?

    private let stackView: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 6
        s.distribution = .fill
        return s
    }()

    private var buttons: [UIButton] = []
    private var widthConstraints: [NSLayoutConstraint] = []

    private static let segmentHeight: CGFloat = 20
    private static let selectedWidth: CGFloat = 30
    private static let unselectedWidth: CGFloat = 20
    private static let titleFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
    private static let selectedFill = UIColor(red: 58 / 255, green: 161 / 255, blue: 118 / 255, alpha: 1)
    private static let unselectedFill = UIColor(red: 82 / 255, green: 76 / 255, blue: 67 / 255, alpha: 0.4)

    init(pageCount: Int) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = true

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        for i in 0..<pageCount {
            let b = UIButton(type: .custom)
            b.translatesAutoresizingMaskIntoConstraints = false
            b.tag = i
            b.setTitle("\(i + 1)", for: .normal)
            b.titleLabel?.font = Self.titleFont
            b.setTitleColor(.white, for: .normal)
            b.layer.masksToBounds = true
            b.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)

            let w = b.widthAnchor.constraint(equalToConstant: Self.unselectedWidth)
            widthConstraints.append(w)
            NSLayoutConstraint.activate([
                b.heightAnchor.constraint(equalToConstant: Self.segmentHeight),
                w,
            ])
            buttons.append(b)
            stackView.addArrangedSubview(b)
        }

        applySelection(index: 0, animated: false)
    }

    required init?(coder: NSCoder) {
        nil
    }

    @objc
    private func segmentTapped(_ sender: UIButton) {
        onSelectPage?(sender.tag)
    }

    func setSelectedIndex(_ index: Int, animated: Bool) {
        let maxI = max(0, buttons.count - 1)
        let clamped = min(max(0, index), maxI)
        applySelection(index: clamped, animated: animated)
    }

    private func applySelection(index activeIndex: Int, animated: Bool) {
        let r = Self.segmentHeight / 2
        for (i, b) in buttons.enumerated() {
            let on = i == activeIndex
            b.backgroundColor = on ? Self.selectedFill : Self.unselectedFill
            b.layer.cornerRadius = r
            widthConstraints[i].constant = on ? Self.selectedWidth : Self.unselectedWidth
        }
        let updates = { self.layoutIfNeeded() }
        if animated {
            UIView.animate(withDuration: 0.2, animations: updates)
        } else {
            updates()
        }
    }
}
