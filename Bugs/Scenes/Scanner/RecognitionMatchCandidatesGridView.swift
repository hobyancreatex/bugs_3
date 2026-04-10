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

/// Сетка результатов: до 4 ячеек, только под реальные превью (1…4 — своя раскладка, без пустых слотов).
final class RecognitionMatchCandidatesGridView: UIView {

    var images: [UIImage] = [] {
        didSet {
            let n = min(4, images.count)
            for (i, cell) in cells.enumerated() {
                let on = i < n
                cell.isHidden = !on
                cell.image = on ? images[i] : nil
            }
            setNeedsLayout()
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
        cells.forEach { cell in
            cell.isHidden = true
            addSubview(cell)
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let maxW = bounds.width
        let maxH = bounds.height
        let n = min(4, images.count)
        let gap: CGFloat = 8

        guard n > 0 else {
            for cell in cells {
                cell.frame = .zero
            }
            return
        }

        let L = min(maxW, maxH)
        guard L > gap else {
            for cell in cells {
                cell.frame = .zero
            }
            return
        }

        let c = CGFloat((Int(L) - Int(gap)) / 2)
        guard c > 0 else {
            for cell in cells {
                cell.frame = .zero
            }
            return
        }

        let cornerRadius = c * 32 / 128

        let usedW: CGFloat
        let usedH: CGFloat
        switch n {
        case 1:
            usedW = c
            usedH = c
        case 2:
            usedW = c * 2 + gap
            usedH = c
        case 3, 4:
            usedW = c * 2 + gap
            usedH = c * 2 + gap
        default:
            usedW = c * 2 + gap
            usedH = c * 2 + gap
        }

        let originX = (maxW - usedW) / 2
        let originY = (maxH - usedH) / 2

        func place(_ idx: Int, x: CGFloat, y: CGFloat) {
            guard idx < cells.count else { return }
            let gridCell = cells[idx]
            gridCell.frame = CGRect(x: x, y: y, width: c, height: c)
            gridCell.layer.cornerRadius = cornerRadius
        }

        switch n {
        case 1:
            place(0, x: originX, y: originY)
        case 2:
            place(0, x: originX, y: originY)
            place(1, x: originX + c + gap, y: originY)
        case 3:
            place(0, x: originX, y: originY)
            place(1, x: originX + c + gap, y: originY)
            let bottomX = originX + (usedW - c) / 2
            place(2, x: bottomX, y: originY + c + gap)
        case 4:
            place(0, x: originX, y: originY)
            place(1, x: originX + c + gap, y: originY)
            place(2, x: originX, y: originY + c + gap)
            place(3, x: originX + c + gap, y: originY + c + gap)
        default:
            break
        }

        for idx in n..<cells.count {
            cells[idx].frame = .zero
        }
    }
}
