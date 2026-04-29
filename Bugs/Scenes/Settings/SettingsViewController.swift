//
//  SettingsViewController.swift
//  Bugs
//

import MessageUI
import UIKit

/// Настройки: те же группы и пункты, что в Coin Recognizer (support / feedback / security).
final class SettingsViewController: UIViewController {
    private var hiddenPremiumTapCount = 0
    private var bannerPriceText: String?
    private var hasLoadedBannerPrice = false

    private enum Section: Int, CaseIterable {
        case support
        case feedback
        case security

        var titleKey: String {
            switch self {
            case .support: return "settings.section.support"
            case .feedback: return "settings.section.feedback"
            case .security: return "settings.section.security"
            }
        }
    }

    private enum SupportRow: Int, CaseIterable {
        case contactUs
        case restore
    }

    private enum FeedbackRow: Int, CaseIterable {
        case rateApp
        case shareApp
    }

    private enum SecurityRow {
        case privacy
        case terms
        case refundConsent
        case deleteAccount
    }

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.backgroundColor = .appBackground
        t.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        t.sectionHeaderTopPadding = 8
        t.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return t
    }()

    private lazy var subscriptionBannerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 24
        v.clipsToBounds = true
        v.isUserInteractionEnabled = true
        return v
    }()

    private let subscriptionBannerGradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.appReadMore.cgColor,
            UIColor.appCollectionCtaGradientEnd.cgColor,
        ]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        return g
    }()

    private let subscriptionBannerTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.numberOfLines = 2
        l.lineBreakMode = .byWordWrapping
        l.textAlignment = .center
        l.text = L10n.string("paywall.headline")
        return l
    }()

    private let subscriptionBannerOfferLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor.white.withAlphaComponent(0.92)
        l.numberOfLines = 1
        l.textAlignment = .center
        return l
    }()

    private let subscriptionBannerButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .white
        b.layer.cornerRadius = 24
        b.setTitleColor(.appTextPrimary, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        b.setTitle(L10n.string("paywall.button.next"), for: .normal)
        b.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        return b
    }()

    private var tableTopToSafeConstraint: NSLayoutConstraint!
    private var tableTopToBannerConstraint: NSLayoutConstraint!
    private var subscriptionBannerHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        overrideUserInterfaceStyle = .light
        navigationItem.title = L10n.string("settings.title")
        configureNavigationBar()
        configureBackButton()
        configureHiddenPremiumActivatorButton()

        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(subscriptionBannerView)
        view.addSubview(tableView)
        let safe = view.safeAreaLayoutGuide
        subscriptionBannerHeightConstraint = subscriptionBannerView.heightAnchor.constraint(equalToConstant: 146)
        tableTopToSafeConstraint = tableView.topAnchor.constraint(equalTo: safe.topAnchor)
        tableTopToBannerConstraint = tableView.topAnchor.constraint(equalTo: subscriptionBannerView.bottomAnchor, constant: 8)
        NSLayoutConstraint.activate([
            subscriptionBannerView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 10),
            subscriptionBannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subscriptionBannerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -48),
            subscriptionBannerHeightConstraint,

            tableTopToSafeConstraint,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        configureSubscriptionBannerHeader()
        refreshSubscriptionBannerHeader()
        Task { await loadBannerPriceIfNeeded() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
        refreshSubscriptionBannerHeader()
        tableView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        subscriptionBannerGradientLayer.frame = subscriptionBannerView.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restoreInteractivePopGestureIfNeeded()
    }

    private func securityRows() -> [SecurityRow] {
        var rows: [SecurityRow] = [.privacy, .terms, .deleteAccount]
        if SubscriptionAccess.shared.isPremiumActive {
            rows.append(.refundConsent)
        }
        return rows
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

    private func configureHiddenPremiumActivatorButton() {
        let hiddenButton = UIButton(type: .custom)
        hiddenButton.translatesAutoresizingMaskIntoConstraints = false
        hiddenButton.alpha = 1
        hiddenButton.backgroundColor = .clear
        hiddenButton.layer.cornerRadius = 0
        hiddenButton.layer.borderWidth = 0
        hiddenButton.layer.borderColor = UIColor.clear.cgColor
        hiddenButton.setTitle(nil, for: .normal)
        hiddenButton.isAccessibilityElement = false
        hiddenButton.addTarget(self, action: #selector(hiddenPremiumActivatorTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            hiddenButton.widthAnchor.constraint(equalToConstant: 32),
            hiddenButton.heightAnchor.constraint(equalToConstant: 32),
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: hiddenButton)
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func hiddenPremiumActivatorTapped() {
        hiddenPremiumTapCount += 1
        guard hiddenPremiumTapCount >= 10 else { return }
        hiddenPremiumTapCount = 0
        SubscriptionAccess.shared.setPremiumActive(true)
        tableView.reloadData()
        presentSimpleAlert(
            title: L10n.string("common.done"),
            message: L10n.string("settings.debug.premium_activated")
        )
        refreshSubscriptionBannerHeader()
    }

    private func configureSubscriptionBannerHeader() {
        subscriptionBannerView.layer.insertSublayer(subscriptionBannerGradientLayer, at: 0)
        subscriptionBannerView.addSubview(subscriptionBannerTitleLabel)
        subscriptionBannerView.addSubview(subscriptionBannerOfferLabel)
        subscriptionBannerView.addSubview(subscriptionBannerButton)

        let bannerTap = UITapGestureRecognizer(target: self, action: #selector(subscriptionBannerTapped))
        subscriptionBannerView.addGestureRecognizer(bannerTap)
        subscriptionBannerButton.addTarget(self, action: #selector(subscriptionBannerTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            subscriptionBannerTitleLabel.topAnchor.constraint(equalTo: subscriptionBannerView.topAnchor, constant: 14),
            subscriptionBannerTitleLabel.leadingAnchor.constraint(equalTo: subscriptionBannerView.leadingAnchor, constant: 16),
            subscriptionBannerTitleLabel.trailingAnchor.constraint(equalTo: subscriptionBannerView.trailingAnchor, constant: -16),

            subscriptionBannerOfferLabel.topAnchor.constraint(equalTo: subscriptionBannerTitleLabel.bottomAnchor, constant: 6),
            subscriptionBannerOfferLabel.leadingAnchor.constraint(equalTo: subscriptionBannerView.leadingAnchor, constant: 16),
            subscriptionBannerOfferLabel.trailingAnchor.constraint(equalTo: subscriptionBannerView.trailingAnchor, constant: -16),

            subscriptionBannerButton.leadingAnchor.constraint(equalTo: subscriptionBannerView.leadingAnchor, constant: 16),
            subscriptionBannerButton.trailingAnchor.constraint(equalTo: subscriptionBannerView.trailingAnchor, constant: -16),
            subscriptionBannerButton.bottomAnchor.constraint(equalTo: subscriptionBannerView.bottomAnchor, constant: -12),
            subscriptionBannerButton.heightAnchor.constraint(equalToConstant: 50),
            subscriptionBannerButton.topAnchor.constraint(greaterThanOrEqualTo: subscriptionBannerOfferLabel.bottomAnchor, constant: 10),
        ])
        updateSubscriptionBannerOfferLabel()
    }

    private func refreshSubscriptionBannerHeader() {
        let showBanner = !SubscriptionAccess.shared.isPremiumActive
        subscriptionBannerView.isHidden = !showBanner
        subscriptionBannerHeightConstraint.constant = showBanner ? 146 : 0
        tableTopToBannerConstraint.isActive = showBanner
        tableTopToSafeConstraint.isActive = !showBanner
        view.layoutIfNeeded()
    }

    @MainActor
    private func loadBannerPriceIfNeeded() async {
        guard !hasLoadedBannerPrice else { return }
        hasLoadedBannerPrice = true
        do {
            let products = try await SubscriptionManager.shared.loadSubscriptionProducts()
            bannerPriceText = products.first?.displayPrice
        } catch {
            bannerPriceText = nil
        }
        updateSubscriptionBannerOfferLabel()
    }

    private func updateSubscriptionBannerOfferLabel() {
        let prefix = L10n.string("paywall.product.prefix")
        let price = bannerPriceText ?? "—"
        let suffix = L10n.string("paywall.product.suffix")
        subscriptionBannerOfferLabel.text = joinOfferParts(prefix: prefix, price: price, suffix: suffix)
    }

    private func joinOfferParts(prefix: String, price: String, suffix: String) -> String {
        let ws = CharacterSet.whitespacesAndNewlines
        let left = prefix.trimmingCharacters(in: ws)
        let right = suffix.trimmingCharacters(in: ws)
        guard !left.isEmpty || !right.isEmpty else { return price }
        if left.isEmpty { return "\(price) \(right)" }
        if right.isEmpty { return "\(left) \(price)" }
        return "\(left) \(price) \(right)"
    }

    @objc
    private func subscriptionBannerTapped() {
        presentPaywallFullScreen()
    }

    private func groupedCellBackground() -> UIBackgroundConfiguration {
        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = UIColor.white.withAlphaComponent(0.94)
        return bg
    }

    private func configureCell(_ cell: UITableViewCell, titleKey: String, symbolName: String?) {
        var content = cell.defaultContentConfiguration()
        content.text = L10n.string(titleKey)
        content.textProperties.font = .systemFont(ofSize: 16, weight: .regular)
        content.textProperties.color = .appTextPrimary
        if let symbolName, let img = UIImage(systemName: symbolName) {
            content.image = img
            content.imageProperties.tintColor = .appTextSecondary
            content.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        }
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.backgroundConfiguration = groupedCellBackground()
    }

    private func configureDestructiveCell(_ cell: UITableViewCell, titleKey: String, symbolName: String) {
        var content = cell.defaultContentConfiguration()
        content.text = L10n.string(titleKey)
        content.textProperties.font = .systemFont(ofSize: 16, weight: .regular)
        content.textProperties.color = .systemRed
        if let img = UIImage(systemName: symbolName) {
            content.image = img
            content.imageProperties.tintColor = .systemRed
            content.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        }
        cell.contentConfiguration = content
        cell.accessoryType = .none
        cell.backgroundConfiguration = groupedCellBackground()
    }

    // MARK: - Actions (как в CoinRecognizer / SettingsPresenter)

    private func contactUs() {
        let email = AppConfig.Support.email
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email])
            mail.setSubject(L10n.string("settings.support.mail_subject"))
            mail.setMessageBody(L10n.string("settings.support.mail_body"), isHTML: false)
            present(mail, animated: true)
        } else {
            let alert = UIAlertController(
                title: L10n.string("settings.support.mail_unavailable_title"),
                message: email,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: L10n.string("common.done"), style: .default))
            present(alert, animated: true)
        }
    }

    private func restorePurchases() {
        Task { await performRestorePurchases() }
    }

    @MainActor
    private func performRestorePurchases() async {
        guard NetworkReachability.shared.isConnected else {
            UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
            return
        }
        showCenterLoadingOverlay()
        defer { hideCenterLoadingOverlay() }

        do {
            try await SubscriptionManager.shared.restorePurchases()
            if SubscriptionManager.shared.isSubscriptionActive {
                presentSimpleAlert(
                    title: L10n.string("subscription.restore.title"),
                    message: L10n.string("subscription.restore.success")
                )
            } else {
                presentSimpleAlert(
                    title: L10n.string("subscription.restore.title"),
                    message: L10n.string("subscription.restore.nothing")
                )
            }
        } catch {
            presentSimpleAlert(
                title: L10n.string("common.error.title"),
                message: L10n.string("common.error.try_later")
            )
        }
    }

    private func presentSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.string("common.done"), style: .default))
        present(alert, animated: true)
    }

    private func rateApp() {
        openURLString(AppConfig.Marketing.appStoreWriteReviewURL)
    }

    private func shareApp() {
        let urlString = AppConfig.Marketing.shareAppURL
        guard let url = URL(string: urlString) else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }

    private func privacyPolicy() {
        openURLString(AppConfig.Marketing.privacyPolicyURL)
    }

    private func termsOfUse() {
        openURLString(AppConfig.Marketing.termsOfUseURL)
    }

    private func showRefundConsentAlert() {
        RefundConsentFlow.present(from: self) {}
    }

    private func deleteAccount() {
        let alert = UIAlertController(
            title: L10n.string("settings.delete_account.confirm.title"),
            message: L10n.string("settings.delete_account.confirm.message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.string("settings.delete_account.confirm.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.string("settings.delete_account.confirm.delete"), style: .destructive) { [weak self] _ in
            Task { await self?.performDeleteAccount() }
        })
        present(alert, animated: true)
    }

    @MainActor
    private func performDeleteAccount() async {
        guard NetworkReachability.shared.isConnected else {
            UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
            return
        }
        showCenterLoadingOverlay()
        defer { hideCenterLoadingOverlay() }
        do {
            try await CollectAPIClient.shared.terminateAccount()
            try? DeviceAuthKeychain.clearAllAuthData()
            CollectAPIAuthState.setToken(nil)
            await AuthBootstrapper.shared.bootstrapIfNeeded()
            presentSimpleAlert(
                title: L10n.string("common.done"),
                message: L10n.string("settings.delete_account.done")
            )
        } catch {
            UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
        }
    }

    private func openURLString(_ string: String) {
        guard let url = URL(string: string), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .support: return SupportRow.allCases.count
        case .feedback: return FeedbackRow.allCases.count
        case .security: return securityRows().count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch Section(rawValue: indexPath.section)! {
        case .support:
            switch SupportRow(rawValue: indexPath.row)! {
            case .contactUs:
                configureCell(cell, titleKey: "settings.row.contact_us", symbolName: "envelope")
            case .restore:
                configureCell(cell, titleKey: "settings.row.restore", symbolName: "arrow.clockwise")
            }
        case .feedback:
            switch FeedbackRow(rawValue: indexPath.row)! {
            case .rateApp:
                configureCell(cell, titleKey: "settings.row.rate_app", symbolName: "star.fill")
            case .shareApp:
                configureCell(cell, titleKey: "settings.row.share_app", symbolName: "square.and.arrow.up")
            }
        case .security:
            let row = securityRows()[indexPath.row]
            switch row {
            case .privacy:
                configureCell(cell, titleKey: "settings.row.privacy", symbolName: "lock.shield")
            case .terms:
                configureCell(cell, titleKey: "settings.row.terms", symbolName: "doc.text")
            case .refundConsent:
                configureCell(cell, titleKey: "settings.row.refund_consent", symbolName: "checkmark.shield.fill")
            case .deleteAccount:
                configureDestructiveCell(cell, titleKey: "settings.row.delete_account", symbolName: "trash")
            }
        }
        return cell
    }
}

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        container.backgroundColor = .clear
        let plaque = InsectSectionHeaderPlaqueView()
        plaque.setTitle(L10n.string(Section.allCases[section].titleKey))
        plaque.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(plaque)
        NSLayoutConstraint.activate([
            plaque.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            plaque.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
        ])
        return container
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section)! {
        case .support:
            switch SupportRow(rawValue: indexPath.row)! {
            case .contactUs: contactUs()
            case .restore: restorePurchases()
            }
        case .feedback:
            switch FeedbackRow(rawValue: indexPath.row)! {
            case .rateApp: rateApp()
            case .shareApp: shareApp()
            }
        case .security:
            switch securityRows()[indexPath.row] {
            case .privacy: privacyPolicy()
            case .terms: termsOfUse()
            case .refundConsent: showRefundConsentAlert()
            case .deleteAccount: deleteAccount()
            }
        }
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
