//
//  InsectDetailAddToCollectionSuccessOverlay.swift
//  Bugs
//

import UIKit

/// Полноэкранный блюр как на сканере + центральный стек (иллюстрация как у пустой коллекции, белый текст).
final class InsectDetailAddToCollectionSuccessOverlay: UIView {

    private var autoDismissWorkItem: DispatchWorkItem?
    private var isDismissing = false

    var onDismiss: (() -> Void)?

    private let blurHost: ScannerStyleFullBlurOverlayView = {
        let v = ScannerStyleFullBlurOverlayView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private lazy var textStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 8
        return s
    }()

    private lazy var contentStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [imageView, textStack])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 16
        return s
    }()

    private let imageSide: CGFloat

    init(title: String, subtitle: String, imageAssetName: String = "profile_collection_empty", imageSide: CGFloat = 120) {
        self.imageSide = imageSide
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = true
        accessibilityLabel = "\(title). \(subtitle)"

        titleLabel.text = title
        subtitleLabel.text = subtitle
        imageView.image = UIImage(named: imageAssetName) ?? UIImage(named: "list_search_empty")

        addSubview(blurHost)
        addSubview(contentStack)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            blurHost.topAnchor.constraint(equalTo: topAnchor),
            blurHost.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurHost.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurHost.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView.widthAnchor.constraint(equalToConstant: imageSide),
            imageView.heightAnchor.constraint(equalToConstant: imageSide),

            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func scheduleAutoDismiss(after delay: TimeInterval = 3) {
        autoDismissWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.dismissAndNotify()
        }
        autoDismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func cancelAutoDismiss() {
        autoDismissWorkItem?.cancel()
        autoDismissWorkItem = nil
    }

    @objc
    private func handleTap() {
        dismissAndNotify()
    }

    private func dismissAndNotify() {
        guard !isDismissing else { return }
        isDismissing = true
        cancelAutoDismiss()
        guard let host = superview else {
            isDismissing = false
            onDismiss?()
            return
        }
        let hideDuration: TimeInterval = 0.35
        UIView.transition(with: host, duration: hideDuration, options: .transitionCrossDissolve, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            self.alpha = 1
            self.isDismissing = false
            self.onDismiss?()
        })
    }
}
