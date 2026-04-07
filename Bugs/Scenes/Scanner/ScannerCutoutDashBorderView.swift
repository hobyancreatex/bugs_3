//
//  ScannerCutoutDashBorderView.swift
//  Bugs
//

import UIKit

/// Пунктир по периметру выреза (#FFFFF5, 2 pt, штрих 12, промежуток 6). Не участвует в hit-testing.
final class ScannerCutoutDashBorderView: UIView {

    var bottomReservedHeight: CGFloat = 106 {
        didSet { setNeedsLayout() }
    }

    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        layer.addSublayer(shape)
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor(red: 1, green: 1, blue: 245 / 255, alpha: 1).cgColor
        shape.lineWidth = 2
        shape.lineDashPattern = [12, 6] as [NSNumber]
        shape.lineCap = .round
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let cutout = ScannerViewportLayout.cutoutFrame(
            in: bounds,
            safeArea: safeAreaInsets,
            bottomReserved: bottomReservedHeight
        )
        let path = UIBezierPath(roundedRect: cutout, cornerRadius: ScannerViewportLayout.cornerRadius)
        shape.path = path.cgPath
        shape.frame = bounds
    }
}
