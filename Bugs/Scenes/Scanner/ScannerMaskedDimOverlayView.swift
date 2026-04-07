//
//  ScannerMaskedDimOverlayView.swift
//  Bugs
//

import UIKit

/// Лёгкое размытие + слабый тинт #063A24 с «дыркой» под вырез. Маска на общем контейнере blur+tint.
final class ScannerMaskedDimOverlayView: UIView {

    var bottomReservedHeight: CGFloat = 106 {
        didSet { setNeedsLayout() }
    }

    var onTapDimmedArea: (() -> Void)?

    private let contentHost: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = false
        return v
    }()

    private let blurView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let tintView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 6 / 255, green: 58 / 255, blue: 36 / 255, alpha: 0.22)
        return v
    }()

    private let holeMask = CAShapeLayer()

    private(set) var cutoutFrameInBounds: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isOpaque = false
        backgroundColor = .clear

        addSubview(contentHost)
        contentHost.addSubview(blurView)
        contentHost.addSubview(tintView)

        NSLayoutConstraint.activate([
            contentHost.topAnchor.constraint(equalTo: topAnchor),
            contentHost.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentHost.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentHost.bottomAnchor.constraint(equalTo: bottomAnchor),

            blurView.topAnchor.constraint(equalTo: contentHost.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: contentHost.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: contentHost.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: contentHost.bottomAnchor),

            tintView.topAnchor.constraint(equalTo: contentHost.topAnchor),
            tintView.leadingAnchor.constraint(equalTo: contentHost.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: contentHost.trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: contentHost.bottomAnchor),
        ])

        holeMask.fillRule = .evenOdd
        contentHost.layer.mask = holeMask

        let tap = UITapGestureRecognizer(target: self, action: #selector(dimTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let b = contentHost.bounds
        holeMask.frame = b

        let cutout = ScannerViewportLayout.cutoutFrame(
            in: bounds,
            safeArea: safeAreaInsets,
            bottomReserved: bottomReservedHeight
        )
        cutoutFrameInBounds = cutout

        let outer = UIBezierPath(rect: b)
        let inner = UIBezierPath(roundedRect: cutout, cornerRadius: ScannerViewportLayout.cornerRadius)
        outer.append(inner)
        outer.usesEvenOddFillRule = true
        holeMask.path = outer.cgPath
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if cutoutFrameInBounds.contains(point) {
            return false
        }
        return super.point(inside: point, with: event)
    }

    @objc
    private func dimTap() {
        onTapDimmedArea?()
    }
}
