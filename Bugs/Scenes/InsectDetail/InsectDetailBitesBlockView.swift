//
//  InsectDetailBitesBlockView.swift
//  Bugs
//

import UIKit

/// Контент под бейджем «Укусы»: ввод, блок первой помощи с иконкой, маркеры, горизонтальная лента фото.
final class InsectDetailBitesBlockView: UIView {

    private static let introFont = UIFont.systemFont(ofSize: 16, weight: .regular)
    private static let firstAidFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
    private static let bulletsFont = UIFont.systemFont(ofSize: 14, weight: .regular)
    private static let bitesTextColor = UIColor.appTextPrimary

    private let introLabel: UILabel = {
        let l = UILabel()
        l.font = InsectDetailBitesBlockView.introFont
        l.textColor = InsectDetailBitesBlockView.bitesTextColor
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.adjustsFontForContentSizeCategory = true
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let firstAidIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }()

    private let firstAidTitleLabel: UILabel = {
        let l = UILabel()
        l.font = InsectDetailBitesBlockView.firstAidFont
        l.textColor = InsectDetailBitesBlockView.bitesTextColor
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.adjustsFontForContentSizeCategory = true
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var firstAidRow: UIStackView = {
        let s = UIStackView(arrangedSubviews: [firstAidIconView, firstAidTitleLabel])
        s.axis = .horizontal
        s.alignment = .top
        s.spacing = 8
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let bulletsLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.adjustsFontForContentSizeCategory = true
        l.setContentCompressionResistancePriority(.required, for: .vertical)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let photosScrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsHorizontalScrollIndicator = false
        s.alwaysBounceHorizontal = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let photosStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var textStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [introLabel, firstAidRow, bulletsLabel])
        s.axis = .vertical
        s.spacing = 12
        s.alignment = .fill
        s.distribution = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private var photosHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        applyFirstAidIcon()
        photosScrollView.addSubview(photosStack)
        addSubview(textStack)
        addSubview(photosScrollView)

        photosHeightConstraint = photosScrollView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            firstAidIconView.widthAnchor.constraint(equalToConstant: 24),
            firstAidIconView.heightAnchor.constraint(equalToConstant: 24),

            textStack.topAnchor.constraint(equalTo: topAnchor),
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            photosScrollView.topAnchor.constraint(equalTo: textStack.bottomAnchor, constant: 16),
            photosScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            photosScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            photosScrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            photosHeightConstraint,

            photosStack.topAnchor.constraint(equalTo: photosScrollView.contentLayoutGuide.topAnchor),
            photosStack.leadingAnchor.constraint(equalTo: photosScrollView.contentLayoutGuide.leadingAnchor),
            photosStack.trailingAnchor.constraint(equalTo: photosScrollView.contentLayoutGuide.trailingAnchor),
            photosStack.bottomAnchor.constraint(equalTo: photosScrollView.contentLayoutGuide.bottomAnchor),
            photosStack.heightAnchor.constraint(equalTo: photosScrollView.frameLayoutGuide.heightAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func applyFirstAidIcon() {
        if let asset = UIImage(named: "insect_detail_bites_first_aid") {
            firstAidIconView.image = asset.withRenderingMode(.alwaysOriginal)
            firstAidIconView.tintColor = nil
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            firstAidIconView.image = UIImage(systemName: "cross.case.fill", withConfiguration: config)
            firstAidIconView.tintColor = UIColor(red: 220 / 255, green: 60 / 255, blue: 60 / 255, alpha: 1)
        }
    }

    func configure(intro: String, firstAidTitle: String, bullets: [String], imageURLs: [URL]) {
        introLabel.text = intro
        introLabel.isHidden = intro.isEmpty

        firstAidTitleLabel.text = firstAidTitle
        let showFirstAid = !firstAidTitle.isEmpty
        firstAidIconView.isHidden = !showFirstAid
        firstAidRow.isHidden = !showFirstAid

        if bullets.isEmpty {
            bulletsLabel.attributedText = nil
            bulletsLabel.isHidden = true
        } else {
            bulletsLabel.isHidden = false
            bulletsLabel.attributedText = Self.bulletsAttributed(lines: bullets)
        }

        photosStack.arrangedSubviews.forEach { v in
            if let iv = v as? UIImageView {
                RemoteImageLoader.cancelLoad(for: iv)
            }
            photosStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        if imageURLs.isEmpty {
            photosScrollView.isHidden = true
            photosHeightConstraint.constant = 0
        } else {
            photosScrollView.isHidden = false
            let side: CGFloat = 96
            photosHeightConstraint.constant = side
            for url in imageURLs {
                let iv = UIImageView()
                iv.translatesAutoresizingMaskIntoConstraints = false
                iv.contentMode = .scaleAspectFill
                iv.clipsToBounds = true
                iv.layer.cornerRadius = 20
                iv.backgroundColor = .appInsectListCellTint
                NSLayoutConstraint.activate([
                    iv.widthAnchor.constraint(equalToConstant: side),
                    iv.heightAnchor.constraint(equalToConstant: side),
                ])
                RemoteImageLoader.load(into: iv, url: url)
                photosStack.addArrangedSubview(iv)
            }
        }
        setNeedsLayout()
    }

    private static func bulletsAttributed(lines: [String]) -> NSAttributedString {
        let bodyFont = Self.bulletsFont
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        paragraph.paragraphSpacing = 5
        let attrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: Self.bitesTextColor,
            .paragraphStyle: paragraph,
        ]
        let out = NSMutableAttributedString()
        for (idx, line) in lines.enumerated() {
            if idx > 0 { out.append(NSAttributedString(string: "\n", attributes: attrs)) }
            let bullet = "– \(line)"
            out.append(NSAttributedString(string: bullet, attributes: attrs))
        }
        return out
    }
}
