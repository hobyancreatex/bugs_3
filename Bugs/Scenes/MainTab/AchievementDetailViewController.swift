//
//  AchievementDetailViewController.swift
//  Bugs
//

import UIKit

struct AchievementDetailViewModel {
    /// Заголовок под иконкой (жирный 24 pt).
    let title: String
    /// Категория: в бейдже при выполненном достижении; в нижнем тексте «ещё N» при незавершённом.
    let categoryName: String
    let imageURL: URL?
    let currentCount: Int
    let maxCount: Int
    let isCompleted: Bool
}

/// Модалка достижения: по центру экрана, фон #FDFFF3, два состояния (есть / нет).
final class AchievementDetailViewController: UIViewController {

    private let viewModel: AchievementDetailViewModel

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .appBackground
        v.layer.cornerRadius = 28
        v.clipsToBounds = true
        return v
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.accessibilityLabel = L10n.string("profile.achievement.close.accessibility")
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let img = UIImage(systemName: "xmark", withConfiguration: cfg)
        b.setImage(img, for: .normal)
        b.tintColor = UIColor.appPaywallPriceHighlight
        b.backgroundColor = .white
        b.layer.cornerRadius = 18
        b.layer.borderWidth = 1.5
        b.layer.borderColor = UIColor.appPaywallPriceHighlight.cgColor
        return b
    }()

    private let iconCircle: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .appCategoryCircle
        v.layer.cornerRadius = 74
        v.clipsToBounds = true
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .appTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let pillView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.appPaywallPriceHighlight
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        return v
    }()

    private let pillLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let footerHeadingLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .appTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let footerBodyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .appTextSecondary
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private lazy var footerTextStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [footerHeadingLabel, footerBodyLabel])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .center
        s.spacing = 7
        return s
    }()

    private var spacerBeforePill: UIView!

    private lazy var mainStack: UIStackView = {
        let beforePill = spacer(height: 20)
        spacerBeforePill = beforePill
        let s = UIStackView(arrangedSubviews: [
            iconCircle,
            spacer(height: 12),
            titleLabel,
            beforePill,
            pillView,
            spacer(height: 20),
            footerTextStack,
        ])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .center
        return s
    }()

    init(viewModel: AchievementDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .clear

        iconCircle.addSubview(iconView)
        pillView.addSubview(pillLabel)

        view.addSubview(dimView)
        view.addSubview(cardView)
        cardView.addSubview(mainStack)
        cardView.addSubview(closeButton)

        let dimTap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        dimView.addGestureRecognizer(dimTap)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 60),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -60),
            cardView.widthAnchor.constraint(lessThanOrEqualToConstant: 340),
            cardView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -120).withPriority(.init(999)),

            closeButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -28),

            iconCircle.widthAnchor.constraint(equalToConstant: 148),
            iconCircle.heightAnchor.constraint(equalToConstant: 148),

            iconView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 120),
            iconView.heightAnchor.constraint(equalToConstant: 120),

            pillView.heightAnchor.constraint(equalToConstant: 24),
            pillView.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            pillView.widthAnchor.constraint(equalTo: pillLabel.widthAnchor, constant: 20),

            pillLabel.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 10),
            pillLabel.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -10),
            pillLabel.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
            footerTextStack.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            footerTextStack.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
            footerHeadingLabel.leadingAnchor.constraint(equalTo: footerTextStack.leadingAnchor),
            footerHeadingLabel.trailingAnchor.constraint(equalTo: footerTextStack.trailingAnchor),
            footerBodyLabel.leadingAnchor.constraint(equalTo: footerTextStack.leadingAnchor),
            footerBodyLabel.trailingAnchor.constraint(equalTo: footerTextStack.trailingAnchor),
        ])

        applyViewModel()
        RemoteImageLoader.load(
            into: iconView,
            url: viewModel.imageURL,
            animatedTransition: true,
            applyGrayscale: false
        )
    }

    private func applyViewModel() {
        titleLabel.text = viewModel.title

        let showPill: Bool
        if viewModel.isCompleted {
            showPill = false
            pillLabel.text = nil
            footerHeadingLabel.text = L10n.string("profile.achievement.completed_heading")
            footerBodyLabel.text = L10n.string("profile.achievement.completed_body")
            footerBodyLabel.isHidden = false
        } else {
            showPill = viewModel.maxCount > 0
            pillLabel.text = showPill ? "\(viewModel.currentCount)/\(viewModel.maxCount)" : nil
            footerHeadingLabel.text = L10n.string("profile.achievement.unlock_heading")
            let remaining = max(0, viewModel.maxCount - viewModel.currentCount)
            if remaining > 0, !viewModel.categoryName.isEmpty {
                footerBodyLabel.text = L10n.format(
                    "profile.achievement.identify_more",
                    Int64(remaining),
                    viewModel.categoryName
                )
                footerBodyLabel.isHidden = false
            } else {
                footerBodyLabel.text = nil
                footerBodyLabel.isHidden = true
            }
        }

        pillView.isHidden = !showPill
        spacerBeforePill.isHidden = !showPill
    }

    @objc
    private func closeTapped() {
        dismiss(animated: true)
    }

    private func spacer(height: CGFloat) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }
}

private extension NSLayoutConstraint {
    func withPriority(_ p: UILayoutPriority) -> NSLayoutConstraint {
        priority = p
        return self
    }
}
