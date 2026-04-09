//
//  ArticleDetailViewController.swift
//  Bugs
//

import UIKit

/// Экран статьи: логика как в CoinRecognizer (герой + блоки заголовок/текст), оформление под Bugs.
final class ArticleDetailViewController: UIViewController {

    private let viewModel: Home.ArticleDetailViewModel

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.alwaysBounceVertical = true
        s.showsVerticalScrollIndicator = true
        s.contentInsetAdjustmentBehavior = .automatic
        return s
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 0
        return s
    }()

    init(viewModel: Home.ArticleDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        overrideUserInterfaceStyle = .light
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = viewModel.title
        configureNavigationBar()
        configureBackButton()

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let heroHeight: CGFloat = 232
        let heroContainer = UIView()
        heroContainer.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.clipsToBounds = true
        heroContainer.layer.cornerRadius = 32
        heroContainer.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        heroContainer.backgroundColor = .appCategoryCircle

        let heroImageView = UIImageView()
        heroImageView.translatesAutoresizingMaskIntoConstraints = false
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.image = UIImage(named: viewModel.heroImageAssetName)
        heroContainer.addSubview(heroImageView)

        contentStack.addArrangedSubview(heroContainer)
        NSLayoutConstraint.activate([
            heroContainer.heightAnchor.constraint(equalToConstant: heroHeight),
            heroImageView.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: heroContainer.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: heroContainer.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor),
        ])

        let textChrome = UIView()
        textChrome.translatesAutoresizingMaskIntoConstraints = false
        let innerStack = UIStackView()
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        innerStack.axis = .vertical
        innerStack.spacing = 12
        innerStack.alignment = .fill
        textChrome.addSubview(innerStack)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .appTextPrimary
        titleLabel.numberOfLines = 0
        titleLabel.text = viewModel.title

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .appTextSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = viewModel.subtitle

        let titleBlock = Self.hInsetWrap(
            arrangedSubviews: [titleLabel, subtitleLabel],
            axis: .vertical,
            spacing: 12,
            inset: 16
        )
        innerStack.addArrangedSubview(titleBlock)

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
        innerStack.addArrangedSubview(spacer)

        for (index, block) in viewModel.blocks.enumerated() {
            if let sectionTitle = block.sectionTitle {
                let plaque = InsectSectionHeaderPlaqueView()
                plaque.setTitle(sectionTitle)
                innerStack.addArrangedSubview(Self.rowWithLeadingAlignedSubview(plaque))
            }
            let body = UILabel()
            body.translatesAutoresizingMaskIntoConstraints = false
            body.font = .systemFont(ofSize: 16, weight: .regular)
            body.textColor = .appDescriptionBody
            body.numberOfLines = 0
            body.text = block.body
            innerStack.addArrangedSubview(Self.hInsetWrap(single: body, inset: 16))

            if index < viewModel.blocks.count - 1 {
                let gap = UIView()
                gap.translatesAutoresizingMaskIntoConstraints = false
                gap.heightAnchor.constraint(equalToConstant: 20).isActive = true
                innerStack.addArrangedSubview(gap)
            }
        }

        contentStack.addArrangedSubview(textChrome)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            innerStack.topAnchor.constraint(equalTo: textChrome.topAnchor, constant: 20),
            innerStack.leadingAnchor.constraint(equalTo: textChrome.leadingAnchor),
            innerStack.trailingAnchor.constraint(equalTo: textChrome.trailingAnchor),
            innerStack.bottomAnchor.constraint(equalTo: textChrome.bottomAnchor, constant: -32),
        ])
    }

    /// Строка на всю ширину стека: `subview` слева, ширина по контенту (как плашки на карточке насекомого).
    private static func rowWithLeadingAlignedSubview(_ subview: UIView) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.backgroundColor = .clear
        subview.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(subview)
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            subview.topAnchor.constraint(equalTo: row.topAnchor),
            subview.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        return row
    }

    private static func hInsetWrap(single: UIView, inset: CGFloat) -> UIView {
        hInsetWrap(arrangedSubviews: [single], axis: .vertical, spacing: 0, inset: inset)
    }

    private static func hInsetWrap(
        arrangedSubviews: [UIView],
        axis: NSLayoutConstraint.Axis,
        spacing: CGFloat,
        inset: CGFloat
    ) -> UIView {
        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = axis
        stack.spacing = spacing
        stack.alignment = .fill
        wrap.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -inset),
            stack.topAnchor.constraint(equalTo: wrap.topAnchor),
            stack.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
        ])
        return wrap
    }

    private func configureNavigationBar() {
        if let nav = navigationController?.navigationBar {
            AppNavigationBarAppearance.apply(to: nav)
        }
    }

    private func configureBackButton() {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "library_nav_back"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32),
        ])
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
