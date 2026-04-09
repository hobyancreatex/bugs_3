//
//  GradientRoundedCTAControl.swift
//  Bugs
//

import QuartzCore
import UIKit

/// Кнопка «В коллекцию»: градиент и тень через слои, без отдельных фоновых `UIView`.
final class GradientRoundedCTAControl: UIButton {

    private static let pulseAnimationKey = "subscriptionPulseScale"
    private static let pulseScaleFrom: CGFloat = 1.0
    private static let pulseScaleTo: CGFloat = 1.045
    private static let pulseDuration: CFTimeInterval = 0.9

    /// Лёгкая пульсация масштаба; после сворачивания приложения возобновляется на `didBecomeActive`.
    var isPulseAnimationEnabled: Bool = false {
        didSet {
            if isPulseAnimationEnabled {
                startPulseIfAppropriate()
            } else {
                removePulseAnimation()
            }
        }
    }

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

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
        if isPulseAnimationEnabled,
           window != nil,
           layer.animation(forKey: Self.pulseAnimationKey) == nil {
            startPulseIfAppropriate()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if isPulseAnimationEnabled {
            if window != nil {
                startPulseIfAppropriate()
            } else {
                removePulseAnimation()
            }
        }
    }

    override var isHidden: Bool {
        didSet {
            guard isPulseAnimationEnabled else { return }
            if isHidden {
                removePulseAnimation()
            } else {
                startPulseIfAppropriate()
            }
        }
    }

    override var alpha: CGFloat {
        didSet {
            guard isPulseAnimationEnabled else { return }
            if alpha < 0.02 {
                removePulseAnimation()
            } else {
                startPulseIfAppropriate()
            }
        }
    }

    @objc
    private func handleAppDidBecomeActive() {
        guard isPulseAnimationEnabled else { return }
        startPulseIfAppropriate()
    }

    private func startPulseIfAppropriate() {
        guard isPulseAnimationEnabled,
              window != nil,
              !isHidden,
              alpha > 0.02,
              bounds.width > 1,
              bounds.height > 1
        else { return }

        removePulseAnimation()

        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = Self.pulseScaleFrom
        anim.toValue = Self.pulseScaleTo
        anim.duration = Self.pulseDuration
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: Self.pulseAnimationKey)
    }

    private func removePulseAnimation() {
        layer.removeAnimation(forKey: Self.pulseAnimationKey)
        layer.transform = CATransform3DIdentity
    }
}
