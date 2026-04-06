//
//  GradientRoundedCTAControl.swift
//  Bugs
//

import UIKit

/// Кнопка «В коллекцию»: градиент и тень через слои, без отдельных фоновых `UIView`.
final class GradientRoundedCTAControl: UIButton {

    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.appReadMore.cgColor,
            UIColor.appCollectionCtaGradientEnd.cgColor
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        g.cornerRadius = 16
        g.masksToBounds = true
        return g
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.insertSublayer(gradientLayer, at: 0)

        setTitleColor(.white, for: .normal)
        setTitleColor(.white.withAlphaComponent(0.85), for: .highlighted)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel?.textAlignment = .center
        titleLabel?.lineBreakMode = .byTruncatingTail
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 16
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 16).cgPath
        if let label = titleLabel {
            bringSubviewToFront(label)
        }
        if let iv = imageView {
            bringSubviewToFront(iv)
        }
    }
}
