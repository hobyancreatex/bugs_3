//
//  RecognitionResultsPagerViewController.swift
//  Bugs
//

import UIKit

/// Несколько экранов детализации насекомого с горизонтальным свайпом; общая кнопка «назад».
final class RecognitionResultsPagerViewController: UIViewController {

    private static let fallbackHeroAssetName = "home_popular_insect"

    private let candidates: [RecognitionClassificationCandidate]
    /// Тот же JPEG, что ушёл в `classification/` — для «В коллекцию» без повторного выбора.
    private let classificationSourceJPEG: Data?

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.isPagingEnabled = true
        s.showsHorizontalScrollIndicator = false
        s.showsVerticalScrollIndicator = false
        s.bounces = true
        s.contentInsetAdjustmentBehavior = .never
        return s
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var insectDetailPages: [InsectDetailViewController] = []

    private var indicatorDisplayedPage: Int = -1

    private let backButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "library_nav_back"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        return b
    }()

    /// - Parameters:
    ///   - candidates: Результаты классификации (URL + id) или заглушки с `thumbnailAssetName`.
    ///   - classificationSourceJPEG: Данные фото с распознавания; передаются в карточку вида для коллекции.
    init(candidates: [RecognitionClassificationCandidate], classificationSourceJPEG: Data? = nil) {
        if candidates.isEmpty {
            self.candidates = RecognitionClassificationCandidate.fromLegacyAssetNames([Self.fallbackHeroAssetName])
        } else {
            self.candidates = candidates
        }
        self.classificationSourceJPEG = classificationSourceJPEG
        super.init(nibName: nil, bundle: nil)
    }

    /// Заглушка: только имена ассетов героя для каждого результата.
    convenience init(heroImageAssetNames: [String]) {
        let names = heroImageAssetNames.isEmpty ? [Self.fallbackHeroAssetName] : heroImageAssetNames
        self.init(candidates: RecognitionClassificationCandidate.fromLegacyAssetNames(names), classificationSourceJPEG: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        overrideUserInterfaceStyle = .light

        scrollView.delegate = self
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let pageCount = candidates.count

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])

        var previousPage: UIView?
        for candidate in candidates {
            let page = UIView()
            page.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(page)

            let assetName = candidate.thumbnailAssetName ?? Self.fallbackHeroAssetName
            let insectId = candidate.insectId.trimmingCharacters(in: .whitespacesAndNewlines)
            let detail = InsectDetailConfigurator.assemble(
                heroImageAssetName: assetName,
                heroImageURL: candidate.heroImageURL,
                insectId: insectId.isEmpty ? nil : insectId,
                isInCollection: false,
                prefilledCollectionJPEG: classificationSourceJPEG
            )
            if let insectDetail = detail as? InsectDetailViewController {
                insectDetail.suppressesBackButton = true
                insectDetail.recognitionPagerPageCount = pageCount
                insectDetail.recognitionPageSelectHandler = { [weak self] index in
                    self?.scrollToPage(index, animated: true)
                }
                insectDetailPages.append(insectDetail)
            }

            addChild(detail)
            page.addSubview(detail.view)
            detail.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                page.topAnchor.constraint(equalTo: contentView.topAnchor),
                page.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                page.widthAnchor.constraint(equalTo: view.widthAnchor),
                detail.view.topAnchor.constraint(equalTo: page.topAnchor),
                detail.view.leadingAnchor.constraint(equalTo: page.leadingAnchor),
                detail.view.trailingAnchor.constraint(equalTo: page.trailingAnchor),
                detail.view.bottomAnchor.constraint(equalTo: page.bottomAnchor),
            ])

            if let prev = previousPage {
                page.leadingAnchor.constraint(equalTo: prev.trailingAnchor).isActive = true
            } else {
                page.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            }

            detail.didMove(toParent: self)
            previousPage = page
        }

        if let last = previousPage {
            NSLayoutConstraint.activate([
                last.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
        }

        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
        ])
        view.bringSubviewToFront(backButton)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        syncPageIndicatorWithScroll(animated: false)
    }

    private func currentScrollPageIndex() -> Int {
        let w = scrollView.bounds.width
        guard w > 1 else { return 0 }
        let page = Int(round(scrollView.contentOffset.x / w))
        return min(max(0, page), candidates.count - 1)
    }

    private func scrollToPage(_ index: Int, animated: Bool) {
        let w = scrollView.bounds.width
        guard w > 0, index >= 0, index < candidates.count else { return }
        scrollView.setContentOffset(CGPoint(x: CGFloat(index) * w, y: 0), animated: animated)
        if !animated {
            indicatorDisplayedPage = index
            updateAllDetailPageIndicators(index: index, animated: false)
        }
    }

    private func updateAllDetailPageIndicators(index: Int, animated: Bool) {
        for d in insectDetailPages {
            d.updateRecognitionPagerSelection(index: index, animated: animated)
        }
    }

    private func syncPageIndicatorWithScroll(animated: Bool) {
        let p = currentScrollPageIndex()
        guard p != indicatorDisplayedPage else { return }
        indicatorDisplayedPage = p
        updateAllDetailPageIndicators(index: p, animated: animated)
    }

    @objc
    private func backTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
}

extension RecognitionResultsPagerViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        syncPageIndicatorWithScroll(animated: false)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncPageIndicatorWithScroll(animated: true)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncPageIndicatorWithScroll(animated: true)
    }
}
