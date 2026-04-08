//
//  RecognitionMatchCandidatesGridView.swift
//  Bugs
//

import UIKit

/// Ячейка сетки: фото, при `premiumGate` — лёгкий блюр и замок 68×68 (картинка заполняет весь квадрат).
private final class RecognitionMatchGridCell: UIView {

    private let photoView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    /// Лёгкий блюр: под ним просвечивают цвета и силуэт (без ослабления alpha).
    private let blurView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        v.isUserInteractionEnabled = false
        return v
    }()

    private let lockImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = false
        iv.image = UIImage(named: "recognition_match_lock")
        return iv
    }()

    private var premiumGateActive = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubview(photoView)
        addSubview(blurView)
        addSubview(lockImageView)
        applyGateVisibility()
    }

    required init?(coder: NSCoder) {
        nil
    }

    var image: UIImage? {
        get { photoView.image }
        set { photoView.image = newValue }
    }

    func setPremiumGateActive(_ active: Bool) {
        premiumGateActive = active
        applyGateVisibility()
    }

    private func applyGateVisibility() {
        blurView.isHidden = !premiumGateActive
        lockImageView.isHidden = !premiumGateActive
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        photoView.frame = bounds
        blurView.frame = bounds

        let cellSide = min(bounds.width, bounds.height)
        let lockSide = min(68, max(0, cellSide - 4))
        lockImageView.bounds = CGRect(x: 0, y: 0, width: lockSide, height: lockSide)
        lockImageView.center = CGPoint(x: bounds.midX, y: bounds.midY)

        let r = layer.cornerRadius
        blurView.layer.cornerRadius = r
        blurView.clipsToBounds = true
    }
}

/// Сетка 2×2: `L = min(доступная ширина, доступная высота)`, ячейка `(L − 8) / 2`, зазор 8.
final class RecognitionMatchCandidatesGridView: UIView {

    var images: [UIImage] = [] {
        didSet {
            for (i, cell) in cells.enumerated() {
                cell.image = i < images.count ? images[i] : nil
            }
        }
    }

    /// Без подписки: лёгкий блюр и замок в каждой ячейке.
    var showsPremiumGate: Bool = false {
        didSet {
            guard oldValue != showsPremiumGate else { return }
            cells.forEach { $0.setPremiumGateActive(showsPremiumGate) }
        }
    }

    private let cells: [RecognitionMatchGridCell] = (0..<4).map { _ in RecognitionMatchGridCell() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        cells.forEach { addSubview($0) }
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let maxW = bounds.width
        let maxH = bounds.height
        let L = min(maxW, maxH)
        guard L > 8 else {
            for cell in cells {
                cell.frame = .zero
            }
            return
        }
        let cell = ((L - 8) / 2).rounded(.down)
        let usedL = cell * 2 + 8
        let originX = (bounds.width - usedL) / 2
        let originY = (bounds.height - usedL) / 2
        let cornerRadius = cell * 32 / 128

        for (idx, gridCell) in cells.enumerated() {
            let row = idx / 2
            let col = idx % 2
            let x = originX + CGFloat(col) * (cell + 8)
            let y = originY + CGFloat(row) * (cell + 8)
            gridCell.frame = CGRect(x: x, y: y, width: cell, height: cell)
            gridCell.layer.cornerRadius = cornerRadius
        }
    }
}
