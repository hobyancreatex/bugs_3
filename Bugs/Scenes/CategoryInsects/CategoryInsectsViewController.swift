//
//  CategoryInsectsViewController.swift
//  Bugs
//

import UIKit

protocol CategoryInsectsDisplayLogic: AnyObject {
    func displayInsects(viewModel: CategoryInsects.Present.ViewModel)
}

final class CategoryInsectsViewController: UIViewController, CategoryInsectsDisplayLogic {

    var interactor: CategoryInsectsBusinessLogic?

    let categoryLocalizationKey: String

    private static let loadMoreFooterReuseId = "CategoryInsectsLoadMoreFooter"
    private let loadMoreIndicatorTag = 9_001

    private var rows: [CategoryInsects.InsectCellViewModel] = []
    private var isLoadingMore = false
    private var isInitialListLoading = false
    private var lastCollectionWidthForLayout: CGFloat = 0

    private let insetSearchField = InsetSearchFieldView()

    private let emptySearchStateView: ListSearchEmptyStateView = {
        let v = ListSearchEmptyStateView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let contentLoadingOverlay = ContentLoadingOverlayView()

    private lazy var listLayout: UICollectionViewFlowLayout = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .vertical
        l.minimumLineSpacing = 12
        l.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: listLayout)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(CategoryInsectsCell.self, forCellWithReuseIdentifier: CategoryInsectsCell.reuseIdentifier)
        cv.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: Self.loadMoreFooterReuseId
        )
        return cv
    }()

    init(categoryLocalizationKey: String) {
        self.categoryLocalizationKey = categoryLocalizationKey
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        navigationItem.title = categoryLocalizationKey.contains(".")
            ? L10n.string(categoryLocalizationKey)
            : categoryLocalizationKey
        configureNavigationBar()
        configureBackButton()
        configureSearchField()
        buildLayout()
        emptySearchStateView.configure(
            title: L10n.string("list.search_empty.title"),
            subtitle: L10n.string("list.search_empty.subtitle")
        )
        insetSearchField.setAttributedPlaceholder(
            NSAttributedString(
                string: L10n.string("home.search.placeholder"),
                attributes: [.foregroundColor: UIColor.placeholderText]
            )
        )
        interactor?.presentInsects(request: CategoryInsects.Present.Request(searchQuery: ""))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
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
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }

    private func configureSearchField() {
        insetSearchField.setTextInputEnabled(true)
        insetSearchField.textField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        insetSearchField.textField.delegate = self
    }

    private func buildLayout() {
        view.addSubview(insetSearchField)
        view.addSubview(collectionView)
        view.addSubview(emptySearchStateView)
        view.addSubview(contentLoadingOverlay)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            insetSearchField.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),
            insetSearchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            insetSearchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: insetSearchField.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            emptySearchStateView.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: 32),
            emptySearchStateView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: 24),
            emptySearchStateView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -24),

            contentLoadingOverlay.topAnchor.constraint(equalTo: insetSearchField.bottomAnchor, constant: 20),
            contentLoadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentLoadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentLoadingOverlay.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
        ])
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func searchTextChanged() {
        let q = insetSearchField.textField.text ?? ""
        interactor?.presentInsects(request: CategoryInsects.Present.Request(searchQuery: q))
    }

    func displayInsects(viewModel: CategoryInsects.Present.ViewModel) {
        contentLoadingOverlay.setActive(viewModel.isLoading)
        isInitialListLoading = viewModel.isLoading
        if viewModel.isLoading {
            isLoadingMore = false
            collectionView.isHidden = true
            emptySearchStateView.isHidden = true
            return
        }

        isLoadingMore = viewModel.isLoadingMore
        rows = viewModel.rows
        emptySearchStateView.isHidden = !viewModel.showsEmptySearchState
        collectionView.isHidden = viewModel.showsEmptySearchState
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = collectionView.bounds.width
        guard w > 1 else { return }
        if abs(w - lastCollectionWidthForLayout) > 0.5 {
            lastCollectionWidthForLayout = w
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

extension CategoryInsectsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension CategoryInsectsViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        rows.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CategoryInsectsCell.reuseIdentifier,
            for: indexPath
        ) as? CategoryInsectsCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: rows[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: Self.loadMoreFooterReuseId,
            for: indexPath
        )
        guard kind == UICollectionView.elementKindSectionFooter else { return view }
        let spinner: UIActivityIndicatorView
        if let existing = view.viewWithTag(loadMoreIndicatorTag) as? UIActivityIndicatorView {
            spinner = existing
        } else {
            let s = UIActivityIndicatorView(style: .medium)
            s.tag = loadMoreIndicatorTag
            s.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(s)
            NSLayoutConstraint.activate([
                s.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                s.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
            spinner = s
        }
        spinner.startAnimating()
        return view
    }
}

extension CategoryInsectsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let horizontalInset: CGFloat = 32
        let w = max(0, collectionView.bounds.width - horizontalInset)
        return CGSize(width: w, height: 104)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard isLoadingMore else { return .zero }
        let w = max(0, collectionView.bounds.width)
        return CGSize(width: w, height: 44)
    }
}

extension CategoryInsectsViewController: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if let insectCell = cell as? CategoryInsectsCell {
            insectCell.cancelCoverImageLoadIfNeeded()
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard !isInitialListLoading, !isLoadingMore, !rows.isEmpty else { return }
        let threshold = 5
        let triggerIndex = max(0, rows.count - threshold)
        if indexPath.item >= triggerIndex {
            interactor?.loadMoreInsects()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let row = rows[indexPath.item]
        let detail = InsectDetailConfigurator.assemble(
            heroImageAssetName: row.imageAssetName,
            heroImageURL: row.imageURL,
            insectId: row.insectId,
            isInCollection: false
        )
        navigationController?.pushViewController(detail, animated: true)
    }
}
