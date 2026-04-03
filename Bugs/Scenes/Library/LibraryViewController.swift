//
//  LibraryViewController.swift
//  Bugs
//

import UIKit

protocol LibraryDisplayLogic: AnyObject {
    func displayCategories(viewModel: Library.Present.ViewModel)
}

final class LibraryViewController: UIViewController, LibraryDisplayLogic {

    var interactor: LibraryBusinessLogic?

    private var cellItems: [Library.CellItem] = []
    private var lastCollectionWidthForLayout: CGFloat = 0

    private let insetSearchField = InsetSearchFieldView()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: LibraryCompositionalLayoutBuilder.makeLayout())
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.dataSource = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInsetAdjustmentBehavior = .always
        cv.register(HomeCategoryCell.self, forCellWithReuseIdentifier: HomeCategoryCell.reuseIdentifier)
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        navigationItem.title = L10n.string("library.title")
        configureNavigationBar()
        configureBackButton()
        configureSearchField()
        buildLayout()
        insetSearchField.setAttributedPlaceholder(
            NSAttributedString(
                string: L10n.string("home.search.placeholder"),
                attributes: [.foregroundColor: UIColor.placeholderText]
            )
        )
        interactor?.presentCategories(request: Library.Present.Request(searchQuery: ""))
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

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            insetSearchField.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),
            insetSearchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            insetSearchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: insetSearchField.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
        ])
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func searchTextChanged() {
        let q = insetSearchField.textField.text ?? ""
        interactor?.presentCategories(request: Library.Present.Request(searchQuery: q))
    }

    func displayCategories(viewModel: Library.Present.ViewModel) {
        cellItems = viewModel.cellItems
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

extension LibraryViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension LibraryViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cellItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomeCategoryCell.reuseIdentifier,
            for: indexPath
        ) as? HomeCategoryCell else {
            return UICollectionViewCell()
        }
        switch cellItems[indexPath.item] {
        case let .category(title, imageAssetName):
            cell.configure(with: Home.CategoryCellViewModel(title: title, imageAssetName: imageAssetName))
        case .spacer:
            cell.configureAsSpacer()
        }
        return cell
    }
}
