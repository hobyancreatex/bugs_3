//
//  InsectDetailViewController.swift
//  Bugs
//

import AVFoundation
import UIKit

protocol InsectDetailDisplayLogic: AnyObject {
    /// `hidesScroll` — только при `active == true`: скрыть контент (первое открытие) или показать лоадер поверх карточки (обновление).
    func displayLoading(_ active: Bool, hidesScroll: Bool)
    func displayDetail(viewModel: InsectDetail.Load.ViewModel)
    func displayAddToCollectionResult(_ viewModel: InsectDetail.AddToCollection.ViewModel)
    func displayRemoveFromCollectionResult(_ viewModel: InsectDetail.RemoveFromCollection.ViewModel)
}

final class InsectDetailViewController: UIViewController, InsectDetailDisplayLogic {

    var interactor: InsectDetailBusinessLogic?

    /// Если true — в «Моей коллекции»: показываем удаление сверху справа. Иначе — градиент «В коллекцию» снизу.
    var isInCollection = false

    /// Если true — скрываем свою кнопку «назад» (например, в горизонтальном пейджере результатов).
    var suppressesBackButton = false

    /// JPEG с распознавания (тот же запрос, что и `classification/`): «В коллекцию» без повторного выбора фото.
    var prefilledCollectionJPEG: Data?

    /// Число страниц в пейджере распознавания; при > 1 показываем индикатор на герое.
    var recognitionPagerPageCount: Int = 0 {
        didSet {
            if isViewLoaded {
                refreshHeroPageIndicator()
            }
        }
    }

    /// Выбор страницы в пейджере (свайп или тап по индикатору).
    var recognitionPageSelectHandler: ((Int) -> Void)?

    private var recognitionPagerSelectedIndex: Int = 0
    private var heroPageIndicator: InsectDetailHeroPageIndicatorView?

    private var isPresentingAddToCollectionFlow = false
    private var isRemovingFromCollection = false
    /// Есть id вида с API — можно вызывать `POST collection/`.
    private var isAddToCollectionAvailableFromAPI = false
    /// Коллекция по этому виду есть (ответ `GET insects/` или только что создали).
    private var isListedInUserCollection = false
    private var addToCollectionLoadingView: UIView?
    private var addToCollectionSuccessOverlay: InsectDetailAddToCollectionSuccessOverlay?

    private var galleryAssetNames: [String] = []
    private var galleryImageURLs: [URL?] = []
    private var userCollectionPhotos: [InsectDetail.UserCollectionPhoto] = []
    private var heroAssetName: String = ""
    private var heroImageURL: URL?

    private let contentLoadingOverlay = ContentLoadingOverlayView()

    private var galleryCollectionHeightConstraint: NSLayoutConstraint!
    private var myCollectionHeightConstraint: NSLayoutConstraint!
    private var descriptionPlaqueTopToAliasesConstraint: NSLayoutConstraint!
    private var descriptionPlaqueTopToMyCollectionStackConstraint: NSLayoutConstraint!
    private var myCollectionStackTopConstraint: NSLayoutConstraint!
    private var myCollectionStackHeightZeroConstraint: NSLayoutConstraint!

    private let deleteFromCollectionButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(.insectDetailDeleteFromCollection(), for: .normal)
        b.tintColor = .appCollectionDelete
        b.adjustsImageWhenHighlighted = true
        b.accessibilityLabel = L10n.string("insect.detail.remove_from_collection.accessibility")
        return b
    }()

    private let addToCollectionControl = GradientRoundedCTAControl()

    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.bounces = false
        s.alwaysBounceVertical = false
        s.showsVerticalScrollIndicator = true
        s.contentInsetAdjustmentBehavior = .never
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 60
        iv.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return iv
    }()

    private lazy var galleryLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.itemSize = CGSize(width: 128, height: 128)
        l.minimumLineSpacing = 4
        l.minimumInteritemSpacing = 0
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return l
    }()

    private lazy var galleryCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: galleryLayout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(InsectDetailGalleryCell.self, forCellWithReuseIdentifier: InsectDetailGalleryCell.reuseIdentifier)
        return cv
    }()

    private let myCollectionPlaque = InsectSectionHeaderPlaqueView()

    private lazy var myCollectionHeaderRow: UIStackView = {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [myCollectionPlaque, spacer])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 0
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()

    private lazy var myCollectionLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .horizontal
        l.itemSize = CGSize(width: 80, height: 80)
        l.minimumLineSpacing = 7
        l.minimumInteritemSpacing = 0
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return l
    }()

    private lazy var myCollectionCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: myCollectionLayout)
        cv.backgroundColor = .clear
        cv.clipsToBounds = false
        cv.showsHorizontalScrollIndicator = false
        cv.alwaysBounceHorizontal = true
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(InsectDetailMyCollectionCell.self, forCellWithReuseIdentifier: InsectDetailMyCollectionCell.reuseIdentifier)
        return cv
    }()

    private lazy var myCollectionStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [myCollectionHeaderRow, myCollectionCollectionView])
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setImage(UIImage(named: "library_nav_back"), for: .normal)
        b.imageView?.contentMode = .scaleAspectFit
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textColor = .appTextPrimary
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let leftStatusIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let leftStatusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .appTextPrimary
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let widespreadLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .appTextPrimary
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let statusRowStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 18
        s.distribution = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        s.clipsToBounds = true
        return s
    }()

    private let aliasesLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descriptionPlaque = InsectSectionHeaderPlaqueView()

    private let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.isSelectable = true
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.linkTextAttributes = [
            .foregroundColor: UIColor.appReadMore,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ]
        return tv
    }()

    private var descriptionHeightConstraint: NSLayoutConstraint!
    private var descriptionBodyText = ""
    private var descriptionReadMoreTitle = ""
    private var descriptionReadLessTitle = ""
    private var isDescriptionExpanded = false
    private var lastDescriptionLayoutWidth: CGFloat = 0
    /// Заголовок по центру верхней полосы при прокрутке (научное имя).
    private var navigationScrollTitle = ""
    /// Показана ли полоса с фоном и заголовком (гистерезис на границе скролла).
    private var scrollNavigationBarTitleVisible = false

    private let scrollTitleChromeBackgroundView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .appBackground
        v.alpha = 0
        v.isUserInteractionEnabled = false
        return v
    }()

    private let scrollNavTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .appTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.alpha = 0
        l.isUserInteractionEnabled = false
        return l
    }()

    private let characteristicsPlaque = InsectSectionHeaderPlaqueView()

    private lazy var characteristicsTableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.separatorStyle = .none
        t.isScrollEnabled = false
        t.backgroundColor = .clear
        t.dataSource = self
        t.delegate = self
        t.estimatedRowHeight = 49
        t.rowHeight = UITableView.automaticDimension
        t.translatesAutoresizingMaskIntoConstraints = false
        t.register(InsectDetailCharacteristicCell.self, forCellReuseIdentifier: InsectDetailCharacteristicCell.reuseIdentifier)
        if #available(iOS 15.0, *) {
            t.sectionHeaderTopPadding = 0
        }
        return t
    }()

    private var characteristicsTableHeightConstraint: NSLayoutConstraint!
    private var characteristicsRows: [(title: String, value: String)] = []
    private var lastCharacteristicsLayoutWidth: CGFloat = 0

    private let classificationPlaque = InsectSectionHeaderPlaqueView()

    private lazy var classificationTableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.separatorStyle = .none
        t.isScrollEnabled = false
        t.backgroundColor = .clear
        t.dataSource = self
        t.delegate = self
        t.estimatedRowHeight = 49
        t.rowHeight = UITableView.automaticDimension
        t.translatesAutoresizingMaskIntoConstraints = false
        t.register(InsectDetailCharacteristicCell.self, forCellReuseIdentifier: InsectDetailCharacteristicCell.reuseIdentifier)
        if #available(iOS 15.0, *) {
            t.sectionHeaderTopPadding = 0
        }
        return t
    }()

    private var classificationTableHeightConstraint: NSLayoutConstraint!
    private var classificationRows: [(title: String, value: String)] = []
    private var lastClassificationLayoutWidth: CGFloat = 0

    private let bitesPlaque = InsectSectionHeaderPlaqueView()
    private let bitesBlockHolder = UIView()
    private let bitesBlockView = InsectDetailBitesBlockView()

    private lazy var bitesColumnStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [bitesPlaque, bitesBlockHolder])
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private var bitesColumnStackTopConstraint: NSLayoutConstraint!
    private var classificationTopToBitesColumnConstraint: NSLayoutConstraint!
    private var bitesBlockHolderWidthConstraint: NSLayoutConstraint!
    private var showsBitesSection = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        scrollView.backgroundColor = .appBackground
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        deleteFromCollectionButton.addTarget(self, action: #selector(deleteFromCollectionTapped), for: .touchUpInside)
        addToCollectionControl.addTarget(self, action: #selector(addToCollectionTapped), for: .touchUpInside)
        let addTitle = L10n.string("insect.detail.add_to_collection")
        addToCollectionControl.setTitle(addTitle, for: .normal)
        addToCollectionControl.accessibilityLabel = addTitle
        buildLayout()
        scrollView.delegate = self
        refreshHeroPageIndicator()
        heroImageView.isUserInteractionEnabled = true
        heroImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(heroImageTapped)))
        backButton.isHidden = suppressesBackButton
        applyCollectionChrome()
        interactor?.loadDetail(request: InsectDetail.Load.Request())
    }

    func updateRecognitionPagerSelection(index: Int, animated: Bool) {
        recognitionPagerSelectedIndex = index
        heroPageIndicator?.setSelectedIndex(index, animated: animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        applySubscriptionStatusForAppearance()
        syncScrollTitleChromeVisibility(animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restoreInteractivePopGestureIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            cancelAddToCollectionFlow()
        }
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    deinit {
        cancelAddToCollectionFlow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !descriptionBodyText.isEmpty {
            let w = descriptionTextView.bounds.width
            if w > 0, abs(w - lastDescriptionLayoutWidth) > 0.5 || lastDescriptionLayoutWidth == 0 {
                lastDescriptionLayoutWidth = w
                applyDescriptionLayout(width: w)
            }
        }
        if !characteristicsRows.isEmpty {
            let cw = characteristicsTableView.bounds.width
            if cw > 0, abs(cw - lastCharacteristicsLayoutWidth) > 0.5 {
                lastCharacteristicsLayoutWidth = cw
                characteristicsTableView.reloadData()
                characteristicsTableView.layoutIfNeeded()
                updateCharacteristicsTableHeight()
            }
        }
        if !classificationRows.isEmpty {
            let clw = classificationTableView.bounds.width
            if clw > 0, abs(clw - lastClassificationLayoutWidth) > 0.5 {
                lastClassificationLayoutWidth = clw
                classificationTableView.reloadData()
                classificationTableView.layoutIfNeeded()
                updateClassificationTableHeight()
            }
        }
        updateScrollInsetForAddToCollectionButton()
        syncScrollTitleChromeVisibility(animated: false)
    }

    private func refreshHeroPageIndicator() {
        heroPageIndicator?.removeFromSuperview()
        heroPageIndicator = nil
        guard recognitionPagerPageCount > 1 else { return }
        let ind = InsectDetailHeroPageIndicatorView(pageCount: recognitionPagerPageCount)
        ind.onSelectPage = { [weak self] i in
            self?.recognitionPageSelectHandler?(i)
        }
        ind.setSelectedIndex(recognitionPagerSelectedIndex, animated: false)
        heroImageView.addSubview(ind)
        heroImageView.bringSubviewToFront(ind)
        NSLayoutConstraint.activate([
            ind.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor, constant: -30),
            ind.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -20),
        ])
        heroPageIndicator = ind
    }

    private func buildLayout() {
        view.addSubview(scrollView)
        view.addSubview(contentLoadingOverlay)
        view.addSubview(scrollTitleChromeBackgroundView)
        view.addSubview(scrollNavTitleLabel)
        scrollView.addSubview(contentView)
        contentView.addSubview(heroImageView)
        contentView.addSubview(galleryCollectionView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusRowStack)
        contentView.addSubview(aliasesLabel)
        contentView.addSubview(myCollectionStack)
        contentView.addSubview(descriptionPlaque)
        contentView.addSubview(descriptionTextView)
        contentView.addSubview(characteristicsPlaque)
        contentView.addSubview(characteristicsTableView)
        bitesBlockHolder.translatesAutoresizingMaskIntoConstraints = false
        bitesBlockHolder.addSubview(bitesBlockView)
        contentView.addSubview(bitesColumnStack)
        contentView.addSubview(classificationPlaque)
        contentView.addSubview(classificationTableView)
        view.addSubview(backButton)
        view.addSubview(deleteFromCollectionButton)
        view.addSubview(addToCollectionControl)

        NSLayoutConstraint.activate([
            leftStatusIconView.widthAnchor.constraint(equalToConstant: 20),
            leftStatusIconView.heightAnchor.constraint(equalToConstant: 20)
        ])
        let widespreadIcon = InsectDetailViewController.statusIconView(named: "insect_detail_status_widespread")
        let leftStatusInner = UIStackView(arrangedSubviews: [leftStatusIconView, leftStatusLabel])
        leftStatusInner.axis = .horizontal
        leftStatusInner.alignment = .center
        leftStatusInner.spacing = 4
        leftStatusInner.translatesAutoresizingMaskIntoConstraints = false
        let widespreadInner = UIStackView(arrangedSubviews: [widespreadIcon, widespreadLabel])
        widespreadInner.axis = .horizontal
        widespreadInner.alignment = .center
        widespreadInner.spacing = 4
        widespreadInner.translatesAutoresizingMaskIntoConstraints = false
        statusRowStack.addArrangedSubview(leftStatusInner)
        statusRowStack.addArrangedSubview(widespreadInner)

        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalTo: heroImageView.widthAnchor, multiplier: 344.0 / 390.0),

            galleryCollectionView.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: 4),
            galleryCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            galleryCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: galleryCollectionView.bottomAnchor, constant: 20),

            contentLoadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            contentLoadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentLoadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentLoadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            statusRowStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            statusRowStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusRowStack.trailingAnchor.constraint(lessThanOrEqualTo: titleLabel.trailingAnchor),
            statusRowStack.heightAnchor.constraint(equalToConstant: 20),

            aliasesLabel.topAnchor.constraint(equalTo: statusRowStack.bottomAnchor, constant: 12),
            aliasesLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            aliasesLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            myCollectionStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            myCollectionStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            descriptionPlaque.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

            descriptionTextView.topAnchor.constraint(equalTo: descriptionPlaque.bottomAnchor, constant: 12),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            characteristicsPlaque.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            characteristicsPlaque.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

            characteristicsTableView.topAnchor.constraint(equalTo: characteristicsPlaque.bottomAnchor, constant: 12),
            characteristicsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            characteristicsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            bitesColumnStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bitesColumnStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            bitesBlockView.topAnchor.constraint(equalTo: bitesBlockHolder.topAnchor),
            bitesBlockView.bottomAnchor.constraint(equalTo: bitesBlockHolder.bottomAnchor),
            bitesBlockView.leadingAnchor.constraint(equalTo: bitesBlockHolder.leadingAnchor, constant: 16),
            bitesBlockView.trailingAnchor.constraint(equalTo: bitesBlockHolder.trailingAnchor, constant: -16),

            classificationPlaque.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),

            classificationTableView.topAnchor.constraint(equalTo: classificationPlaque.bottomAnchor, constant: 12),
            classificationTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            classificationTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            contentView.bottomAnchor.constraint(equalTo: classificationTableView.bottomAnchor, constant: 24)
        ])

        galleryCollectionHeightConstraint = galleryCollectionView.heightAnchor.constraint(equalToConstant: 128)
        galleryCollectionHeightConstraint.isActive = true
        myCollectionHeightConstraint = myCollectionCollectionView.heightAnchor.constraint(equalToConstant: 80)
        myCollectionHeightConstraint.isActive = true

        descriptionPlaqueTopToAliasesConstraint = descriptionPlaque.topAnchor.constraint(
            equalTo: aliasesLabel.bottomAnchor,
            constant: 20
        )
        descriptionPlaqueTopToMyCollectionStackConstraint = descriptionPlaque.topAnchor.constraint(
            equalTo: myCollectionStack.bottomAnchor,
            constant: 20
        )
        myCollectionStackTopConstraint = myCollectionStack.topAnchor.constraint(
            equalTo: aliasesLabel.bottomAnchor,
            constant: 0
        )
        myCollectionStackHeightZeroConstraint = myCollectionStack.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            descriptionPlaqueTopToAliasesConstraint,
            myCollectionStackTopConstraint,
            myCollectionStackHeightZeroConstraint,
        ])
        descriptionPlaqueTopToMyCollectionStackConstraint.isActive = false

        NSLayoutConstraint.activate([
            deleteFromCollectionButton.widthAnchor.constraint(equalToConstant: 32),
            deleteFromCollectionButton.heightAnchor.constraint(equalToConstant: 32),
            deleteFromCollectionButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            deleteFromCollectionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            scrollTitleChromeBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollTitleChromeBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollTitleChromeBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollTitleChromeBackgroundView.bottomAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),

            scrollNavTitleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            scrollNavTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            scrollNavTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: deleteFromCollectionButton.leadingAnchor, constant: -8),

            addToCollectionControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 46),
            addToCollectionControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -46),
            addToCollectionControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addToCollectionControl.heightAnchor.constraint(equalToConstant: 56)
        ])
        let scrollTitleCenterX = scrollNavTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        scrollTitleCenterX.priority = UILayoutPriority(999)
        scrollTitleCenterX.isActive = true

        view.bringSubviewToFront(contentLoadingOverlay)
        view.bringSubviewToFront(scrollTitleChromeBackgroundView)
        view.bringSubviewToFront(scrollNavTitleLabel)
        if !suppressesBackButton {
            view.bringSubviewToFront(backButton)
        }
        view.bringSubviewToFront(deleteFromCollectionButton)
        view.bringSubviewToFront(addToCollectionControl)

        descriptionHeightConstraint = descriptionTextView.heightAnchor.constraint(equalToConstant: 1)
        descriptionHeightConstraint.isActive = true
        characteristicsTableHeightConstraint = characteristicsTableView.heightAnchor.constraint(equalToConstant: 1)
        characteristicsTableHeightConstraint.isActive = true
        classificationTableHeightConstraint = classificationTableView.heightAnchor.constraint(equalToConstant: 1)
        classificationTableHeightConstraint.isActive = true

        bitesColumnStackTopConstraint = bitesColumnStack.topAnchor.constraint(
            equalTo: characteristicsTableView.bottomAnchor,
            constant: 0
        )
        classificationTopToBitesColumnConstraint = classificationPlaque.topAnchor.constraint(
            equalTo: bitesColumnStack.bottomAnchor,
            constant: 20
        )
        bitesBlockHolderWidthConstraint = bitesBlockHolder.widthAnchor.constraint(equalTo: contentView.widthAnchor)
        NSLayoutConstraint.activate([
            bitesColumnStackTopConstraint,
            classificationTopToBitesColumnConstraint,
            bitesBlockHolderWidthConstraint,
        ])
        bitesPlaque.isHidden = true
        bitesBlockHolder.isHidden = true
        bitesColumnStackTopConstraint.constant = 0
        myCollectionHeaderRow.isHidden = true
        myCollectionCollectionView.isHidden = true
        myCollectionHeightConstraint.constant = 0
    }

    private static func statusIconView(named: String) -> UIImageView {
        let iv = UIImageView(image: UIImage(named: named))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iv.widthAnchor.constraint(equalToConstant: 20),
            iv.heightAnchor.constraint(equalToConstant: 20)
        ])
        return iv
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func applyCollectionChrome() {
        let showRemove = isInCollection || isListedInUserCollection
        deleteFromCollectionButton.isHidden = !showRemove
        addToCollectionControl.isHidden = false
        updateScrollInsetForAddToCollectionButton()
    }

    /// Полноэкранный слой поверх всего (в т.ч. «Назад» у `RecognitionResultsPagerViewController`, не только `self.view`).
    private var addToCollectionFullscreenHost: UIView {
        navigationController?.view ?? view
    }

    /// Скролл на весь экран; кнопка поверх. Нижний inset, чтобы последний контент можно было прокрутить выше кнопки.
    private func updateScrollInsetForAddToCollectionButton() {
        let visibleBottom = scrollView.frame.maxY
        let buttonTop = addToCollectionControl.frame.minY
        let overlap = max(0, visibleBottom - buttonTop)
        let breathingRoom: CGFloat = 20
        let inset = overlap + breathingRoom
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc
    private func deleteFromCollectionTapped() {
        guard isInCollection || isListedInUserCollection else { return }
        guard presentedViewController == nil else { return }
        guard !isRemovingFromCollection, !isPresentingAddToCollectionFlow else { return }

        let alert = UIAlertController(
            title: L10n.string("insect.detail.remove_from_collection.confirm.title"),
            message: L10n.string("insect.detail.remove_from_collection.confirm.message"),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.string("insect.detail.remove_from_collection.confirm.cancel"),
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.string("insect.detail.remove_from_collection.confirm.delete"),
                style: .destructive
            ) { [weak self] _ in
                self?.performRemoveFromCollectionAfterConfirmation()
            }
        )
        present(alert, animated: true)
    }

    private func performRemoveFromCollectionAfterConfirmation() {
        guard isInCollection || isListedInUserCollection else { return }
        guard presentedViewController == nil else { return }
        guard !isRemovingFromCollection else { return }
        isRemovingFromCollection = true
        installAddToCollectionLoadingDim()
        interactor?.removeFromCollection(request: .init())
    }

    @objc
    private func addToCollectionTapped() {
        guard isAddToCollectionAvailableFromAPI || isListedInUserCollection || isInCollection else { return }
        guard SubscriptionAccess.shared.isPremiumActive else {
            presentPaywallFullScreen()
            return
        }
        guard presentedViewController == nil else { return }
        guard !isPresentingAddToCollectionFlow else { return }

        if let jpeg = prefilledCollectionJPEG, !jpeg.isEmpty {
            isPresentingAddToCollectionFlow = true
            installAddToCollectionLoadingDim()
            interactor?.addToCollection(request: .init(jpegData: jpeg))
            return
        }

        let sheet = UIAlertController(
            title: L10n.string("insect.detail.add_to_collection.sheet.title"),
            message: nil,
            preferredStyle: .actionSheet
        )
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(
                UIAlertAction(
                    title: L10n.string("insect.detail.add_to_collection.source.camera"),
                    style: .default
                ) { [weak self] _ in
                    self?.presentCameraPickerForCollectionIfAllowed()
                }
            )
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            sheet.addAction(
                UIAlertAction(
                    title: L10n.string("insect.detail.add_to_collection.source.library"),
                    style: .default
                ) { [weak self] _ in
                    self?.presentImagePickerForCollection(sourceType: .photoLibrary)
                }
            )
        }
        sheet.addAction(
            UIAlertAction(
                title: L10n.string("insect.detail.add_to_collection.cancel"),
                style: .cancel
            )
        )
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = addToCollectionControl
            pop.sourceRect = addToCollectionControl.bounds
        }
        present(sheet, animated: true)
    }

    private func presentCameraPickerForCollectionIfAllowed() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            presentImagePickerForCollection(sourceType: .camera)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.presentImagePickerForCollection(sourceType: .camera)
                    } else {
                        self.presentCameraAccessDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            presentCameraAccessDeniedAlert()
        @unknown default:
            presentCameraAccessDeniedAlert()
        }
    }

    private func presentCameraAccessDeniedAlert() {
        let alert = UIAlertController(
            title: L10n.string("insect.detail.camera.access_denied.title"),
            message: L10n.string("insect.detail.camera.access_denied.message"),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.string("insect.detail.camera.access_denied.cancel"),
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: L10n.string("insect.detail.camera.access_denied.settings"),
                style: .default
            ) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        )
        present(alert, animated: true)
    }

    private func presentImagePickerForCollection(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    private func syncScrollTitleChromeVisibility(animated: Bool) {
        guard !navigationScrollTitle.isEmpty, titleLabel.bounds.height > 0 else {
            if scrollNavigationBarTitleVisible {
                scrollNavigationBarTitleVisible = false
                applyScrollTitleChromeVisible(false, animated: animated)
            }
            return
        }
        let anchor = max(0, titleLabel.frame.maxY - view.safeAreaInsets.top - 16)
        let hysteresis: CGFloat = 12
        let targetShow: Bool
        if scrollNavigationBarTitleVisible {
            targetShow = scrollView.contentOffset.y > anchor - hysteresis
        } else {
            targetShow = scrollView.contentOffset.y > anchor + hysteresis
        }
        guard targetShow != scrollNavigationBarTitleVisible else { return }
        scrollNavigationBarTitleVisible = targetShow
        applyScrollTitleChromeVisible(targetShow, animated: animated)
    }

    private func applyScrollTitleChromeVisible(_ visible: Bool, animated: Bool) {
        scrollNavTitleLabel.text = navigationScrollTitle
        let updates = {
            self.scrollTitleChromeBackgroundView.alpha = visible ? 1 : 0
            self.scrollNavTitleLabel.alpha = visible ? 1 : 0
        }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: updates)
        } else {
            updates()
        }
    }

    private func installAddToCollectionLoadingDim() {
        removeAddToCollectionLoading()
        let dim = UIView()
        dim.translatesAutoresizingMaskIntoConstraints = false
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .white
        spinner.startAnimating()
        dim.addSubview(spinner)
        let host = addToCollectionFullscreenHost
        host.addSubview(dim)
        NSLayoutConstraint.activate([
            dim.topAnchor.constraint(equalTo: host.topAnchor),
            dim.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            dim.bottomAnchor.constraint(equalTo: host.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: dim.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: dim.centerYAnchor),
        ])
        host.bringSubviewToFront(dim)
        addToCollectionLoadingView = dim
    }

    private func removeAddToCollectionLoading() {
        addToCollectionLoadingView?.removeFromSuperview()
        addToCollectionLoadingView = nil
    }

    private func cancelAddToCollectionFlow() {
        removeAddToCollectionLoading()
        if let overlay = addToCollectionSuccessOverlay {
            overlay.cancelAutoDismiss()
            overlay.removeFromSuperview()
            addToCollectionSuccessOverlay = nil
        }
        isPresentingAddToCollectionFlow = false
        isRemovingFromCollection = false
    }

    private func presentAddToCollectionSuccessOverlay() {
        let overlay = InsectDetailAddToCollectionSuccessOverlay(
            title: L10n.string("insect.detail.add_to_collection.success.title"),
            subtitle: L10n.string("insect.detail.add_to_collection.success.subtitle"),
            imageAssetName: "bug_happy",
            imageSide: 120
        )
        overlay.onDismiss = { [weak self] in
            self?.addToCollectionSuccessOverlay = nil
            self?.isPresentingAddToCollectionFlow = false
        }
        addToCollectionSuccessOverlay = overlay
        overlay.alpha = 0
        let host = addToCollectionFullscreenHost
        host.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: host.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        host.bringSubviewToFront(overlay)
        host.layoutIfNeeded()

        let showDuration: TimeInterval = 0.45
        UIView.transition(with: host, duration: showDuration, options: .transitionCrossDissolve, animations: {
            overlay.alpha = 1
        }, completion: { _ in
            overlay.scheduleAutoDismiss(after: 3)
        })
    }

    func displayLoading(_ active: Bool, hidesScroll: Bool) {
        guard active else {
            contentLoadingOverlay.setActive(false)
            scrollView.isHidden = false
            view.bringSubviewToFront(scrollTitleChromeBackgroundView)
            view.bringSubviewToFront(scrollNavTitleLabel)
            if !suppressesBackButton {
                view.bringSubviewToFront(backButton)
            }
            view.bringSubviewToFront(deleteFromCollectionButton)
            view.bringSubviewToFront(addToCollectionControl)
            return
        }
        contentLoadingOverlay.setActive(true, dimmedBackground: !hidesScroll)
        scrollView.isHidden = hidesScroll
        view.bringSubviewToFront(contentLoadingOverlay)
        if !suppressesBackButton {
            view.bringSubviewToFront(backButton)
        }
        view.bringSubviewToFront(deleteFromCollectionButton)
        view.bringSubviewToFront(addToCollectionControl)
    }

    func displayAddToCollectionResult(_ viewModel: InsectDetail.AddToCollection.ViewModel) {
        removeAddToCollectionLoading()
        switch viewModel {
        case .success:
            prefilledCollectionJPEG = nil
            isListedInUserCollection = true
            isAddToCollectionAvailableFromAPI = true
            applyCollectionChrome()
            interactor?.loadDetail(request: InsectDetail.Load.Request(showsLoadingOverlay: false))
            presentAddToCollectionSuccessOverlay()
        case .failure(let title, let message):
            isPresentingAddToCollectionFlow = false
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: L10n.string("insect.detail.add_to_collection.alert.ok"),
                    style: .default
                )
            )
            present(alert, animated: true)
        }
    }

    func displayRemoveFromCollectionResult(_ viewModel: InsectDetail.RemoveFromCollection.ViewModel) {
        removeAddToCollectionLoading()
        isRemovingFromCollection = false
        switch viewModel {
        case .success:
            isListedInUserCollection = false
            if !isInCollection {
                isAddToCollectionAvailableFromAPI = true
            }
            applyCollectionChrome()
            interactor?.loadDetail(request: InsectDetail.Load.Request(showsLoadingOverlay: false))
        case .failure(let title, let message):
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(
                    title: L10n.string("insect.detail.add_to_collection.alert.ok"),
                    style: .default
                )
            )
            present(alert, animated: true)
        }
    }

    func displayDetail(viewModel: InsectDetail.Load.ViewModel) {
        contentLoadingOverlay.setActive(false, dimmedBackground: false)
        scrollView.isHidden = false
        isListedInUserCollection = viewModel.isInUserCollection
        if viewModel.isDetailPayloadFromServer, !viewModel.isInUserCollection {
            isInCollection = false
        }
        isAddToCollectionAvailableFromAPI = viewModel.isAddToCollectionAvailable
        applyCollectionChrome()
        heroAssetName = viewModel.heroImageAssetName
        heroImageURL = viewModel.heroImageURL
        RemoteImageLoader.load(
            into: heroImageView,
            url: viewModel.heroImageURL,
            animatedTransition: false
        )
        galleryAssetNames = viewModel.galleryImageAssetNames
        galleryImageURLs = viewModel.galleryImageURLs
        userCollectionPhotos = viewModel.userCollectionPhotos
        let gh: CGFloat = viewModel.galleryImageAssetNames.isEmpty ? 0 : 128
        galleryCollectionHeightConstraint.constant = gh
        galleryCollectionView.isHidden = viewModel.galleryImageAssetNames.isEmpty
        galleryCollectionView.reloadData()
        let showsMyCollection = !viewModel.userCollectionPhotos.isEmpty
        myCollectionHeaderRow.isHidden = !showsMyCollection
        myCollectionCollectionView.isHidden = !showsMyCollection
        myCollectionHeightConstraint.constant = showsMyCollection ? 80 : 0
        myCollectionStackHeightZeroConstraint.isActive = !showsMyCollection
        myCollectionStackTopConstraint.constant = showsMyCollection ? 20 : 0
        descriptionPlaqueTopToAliasesConstraint.isActive = !showsMyCollection
        descriptionPlaqueTopToMyCollectionStackConstraint.isActive = showsMyCollection
        if showsMyCollection {
            myCollectionPlaque.setTitle(L10n.string("profile.segment.collection"))
        }
        /// Всегда сбрасываем ячейки: иначе после добавления фото остаётся старый item count / reuse «+» рядом с новым слотом.
        myCollectionCollectionView.reloadData()
        titleLabel.text = viewModel.scientificTitle
        applyLeftHazardStatus(viewModel.leftHazardStatus, text: viewModel.leftStatusText)
        widespreadLabel.text = viewModel.widespreadStatusText
        applyAliases(prefix: viewModel.alsoKnownPrefix, names: viewModel.alsoKnownNames)
        descriptionBodyText = viewModel.descriptionBody
        descriptionReadMoreTitle = viewModel.readMoreTitle
        descriptionReadLessTitle = viewModel.readLessTitle
        navigationScrollTitle = viewModel.scientificTitle
        scrollNavigationBarTitleVisible = false
        applyScrollTitleChromeVisible(false, animated: false)
        isDescriptionExpanded = false
        lastDescriptionLayoutWidth = 0
        descriptionPlaque.setTitle(viewModel.descriptionSectionTitle)
        descriptionTextView.delegate = self
        characteristicsRows = viewModel.characteristicRows
        characteristicsPlaque.setTitle(viewModel.characteristicsSectionTitle)
        lastCharacteristicsLayoutWidth = 0
        characteristicsTableView.reloadData()
        classificationRows = viewModel.classificationRows
        classificationPlaque.setTitle(viewModel.classificationSectionTitle)
        lastClassificationLayoutWidth = 0
        classificationTableView.reloadData()

        showsBitesSection = viewModel.showsBitesSection
        bitesPlaque.isHidden = !viewModel.showsBitesSection
        bitesBlockHolder.isHidden = !viewModel.showsBitesSection
        bitesColumnStackTopConstraint.constant = viewModel.showsBitesSection ? 20 : 0
        bitesPlaque.setTitle(viewModel.bitesSectionTitle)
        if viewModel.showsBitesSection {
            bitesBlockView.configure(
                intro: viewModel.bitesIntro,
                firstAidTitle: viewModel.bitesFirstAidTitle,
                bullets: viewModel.bitesBulletLines,
                imageURLs: viewModel.bitePhotoURLs
            )
        } else {
            bitesBlockView.configure(intro: "", firstAidTitle: "", bullets: [], imageURLs: [])
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
        updateCharacteristicsTableHeight()
        updateClassificationTableHeight()
    }

    private func updateCharacteristicsTableHeight() {
        guard !characteristicsRows.isEmpty else {
            characteristicsTableHeightConstraint.constant = 0
            return
        }
        let relaxed: CGFloat = 50_000
        characteristicsTableHeightConstraint.constant = relaxed
        view.layoutIfNeeded()
        characteristicsTableView.layoutIfNeeded()
        let h = characteristicsTableView.contentSize.height
        characteristicsTableHeightConstraint.constant = max(1, ceil(h))
    }

    private func updateClassificationTableHeight() {
        guard !classificationRows.isEmpty else {
            classificationTableHeightConstraint.constant = 0
            return
        }
        let relaxed: CGFloat = 50_000
        classificationTableHeightConstraint.constant = relaxed
        view.layoutIfNeeded()
        classificationTableView.layoutIfNeeded()
        let h = classificationTableView.contentSize.height
        classificationTableHeightConstraint.constant = max(1, ceil(h))
    }

    private func applyDescriptionLayout(width: CGFloat) {
        guard width > 0 else { return }
        if isDescriptionExpanded {
            if InsectDetailDescriptionComposer.isTextLongEnoughToCollapse(fullText: descriptionBodyText, width: width) {
                descriptionTextView.attributedText = InsectDetailDescriptionComposer.expandedAttributedWithReadLess(
                    fullText: descriptionBodyText,
                    readLessTitle: descriptionReadLessTitle
                )
            } else {
                descriptionTextView.attributedText = InsectDetailDescriptionComposer.expandedAttributed(fullText: descriptionBodyText)
            }
        } else {
            descriptionTextView.attributedText = InsectDetailDescriptionComposer.collapsedAttributed(
                fullText: descriptionBodyText,
                width: width,
                readMoreTitle: descriptionReadMoreTitle
            )
        }
        // `UITextView.sizeThatFits` часто даёт лишнюю высоту снизу; высота по `boundingRect` совпадает с версткой текста.
        let attr = descriptionTextView.attributedText
        let textHeight: CGFloat
        if let attr, attr.length > 0 {
            textHeight = ceil(
                attr.boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height
            )
        } else {
            textHeight = 1
        }
        descriptionHeightConstraint.constant = max(1, textHeight)
    }

    private func applyLeftHazardStatus(_ status: InsectDetail.LeftHazardStatus, text: String) {
        leftStatusIconView.image = UIImage(named: status.imageAssetName)
        leftStatusLabel.text = text
        switch status {
        case .harmless:
            leftStatusLabel.textColor = .appHarmlessGreen
        case .poisonous:
            leftStatusLabel.textColor = .appPoisonousRed
        case .toxic:
            leftStatusLabel.textColor = .appToxicOrange
        }
    }

    @objc
    private func heroImageTapped() {
        presentImageGallery(initialURL: heroImageURL, initialAssetName: heroAssetName)
    }

    /// Сначала полноэкранная галерея по реальным URL; если их нет — по ассетам (stub).
    private func presentImageGallery(initialURL: URL? = nil, initialAssetName: String? = nil) {
        let urls = Self.orderedUniqueURLs(hero: heroImageURL, gallery: galleryImageURLs)
        if !urls.isEmpty {
            let idx = Self.indexOfURL(initialURL, in: urls) ?? 0
            let vc = InsectImageGalleryViewController(imageURLs: urls, initialIndex: idx)
            present(vc, animated: true)
            return
        }
        let names = Self.orderedUniqueImageNames(hero: heroAssetName, gallery: galleryAssetNames)
        guard !names.isEmpty else { return }
        let idx: Int
        if let initial = initialAssetName, let i = names.firstIndex(of: initial) {
            idx = i
        } else {
            idx = 0
        }
        let vc = InsectImageGalleryViewController(imageAssetNames: names, initialIndex: idx)
        present(vc, animated: true)
    }

    private static func orderedUniqueURLs(hero: URL?, gallery: [URL?]) -> [URL] {
        var seen = Set<String>()
        var out: [URL] = []
        let sequence: [URL?] = [hero] + gallery
        for u in sequence {
            guard let u else { continue }
            let key = u.absoluteString
            guard seen.insert(key).inserted else { continue }
            out.append(u)
        }
        return out
    }

    private static func indexOfURL(_ url: URL?, in urls: [URL]) -> Int? {
        guard let url else { return nil }
        let key = url.absoluteString
        return urls.firstIndex { $0.absoluteString == key }
    }

    private static func orderedUniqueImageNames(hero: String, gallery: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for name in [hero] + gallery where seen.insert(name).inserted {
            out.append(name)
        }
        return out
    }

    private func applyAliases(prefix: String, names: String) {
        let m = NSMutableAttributedString()
        m.append(NSAttributedString(
            string: prefix,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.appTextSecondary
            ]
        ))
        m.append(NSAttributedString(
            string: names,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.appTextPrimary
            ]
        ))
        aliasesLabel.attributedText = m
    }
}

extension InsectDetailViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === galleryCollectionView {
            return galleryAssetNames.count
        }
        if collectionView === myCollectionCollectionView {
            guard !userCollectionPhotos.isEmpty else { return 0 }
            return userCollectionPhotos.count + 1
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === myCollectionCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: InsectDetailMyCollectionCell.reuseIdentifier,
                for: indexPath
            ) as? InsectDetailMyCollectionCell else {
                return UICollectionViewCell()
            }
            if indexPath.item < userCollectionPhotos.count {
                cell.configureImage(url: userCollectionPhotos[indexPath.item].url)
            } else {
                cell.configureAddAction()
            }
            return cell
        }
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: InsectDetailGalleryCell.reuseIdentifier,
            for: indexPath
        ) as? InsectDetailGalleryCell else {
            return UICollectionViewCell()
        }
        let url = indexPath.item < galleryImageURLs.count ? galleryImageURLs[indexPath.item] : nil
        cell.configure(imageURL: url)
        return cell
    }
}

extension InsectDetailViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === myCollectionCollectionView {
            if indexPath.item < userCollectionPhotos.count {
                let vc = UserCollectionPhotoGalleryViewController(
                    photos: userCollectionPhotos,
                    initialIndex: indexPath.item
                ) { [weak self] in
                    self?.interactor?.loadDetail(request: InsectDetail.Load.Request(showsLoadingOverlay: false))
                }
                present(vc, animated: true)
                return
            }
            if indexPath.item == userCollectionPhotos.count {
                addToCollectionTapped()
            }
            return
        }
        guard collectionView === galleryCollectionView else { return }
        guard indexPath.item < galleryAssetNames.count else { return }
        let url = indexPath.item < galleryImageURLs.count ? galleryImageURLs[indexPath.item] : nil
        let name = galleryAssetNames[indexPath.item]
        presentImageGallery(initialURL: url, initialAssetName: name)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if collectionView === myCollectionCollectionView {
            return CGSize(width: 80, height: 80)
        }
        return CGSize(width: 128, height: 128)
    }
}

extension InsectDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === characteristicsTableView {
            return characteristicsRows.count
        }
        if tableView === classificationTableView {
            return classificationRows.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: InsectDetailCharacteristicCell.reuseIdentifier,
            for: indexPath
        ) as? InsectDetailCharacteristicCell else {
            return UITableViewCell()
        }
        let row: (title: String, value: String)
        if tableView === characteristicsTableView {
            row = characteristicsRows[indexPath.row]
        } else if tableView === classificationTableView {
            row = classificationRows[indexPath.row]
        } else {
            return UITableViewCell()
        }
        cell.configure(title: row.title, value: row.value, rowIndex: indexPath.row)
        return cell
    }
}

extension InsectDetailViewController: UITableViewDelegate {}

extension InsectDetailViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        syncScrollTitleChromeVisibility(animated: false)
    }
}

extension InsectDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            guard let image, let jpeg = image.jpegData(compressionQuality: 0.3), !jpeg.isEmpty else {
                return
            }
            self.isPresentingAddToCollectionFlow = true
            self.installAddToCollectionLoadingDim()
            self.interactor?.addToCollection(request: .init(jpegData: jpeg))
        }
    }
}

extension InsectDetailViewController: UITextViewDelegate {

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if URL == InsectDetailDescriptionComposer.readMoreURL {
            isDescriptionExpanded = true
            let w = lastDescriptionLayoutWidth > 0 ? lastDescriptionLayoutWidth : textView.bounds.width
            applyDescriptionLayout(width: w)
            return false
        }
        if URL == InsectDetailDescriptionComposer.readLessURL {
            isDescriptionExpanded = false
            let w = lastDescriptionLayoutWidth > 0 ? lastDescriptionLayoutWidth : textView.bounds.width
            applyDescriptionLayout(width: w)
            return false
        }
        return true
    }
}
