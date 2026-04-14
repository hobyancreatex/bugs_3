//
//  SettingsViewController.swift
//  Bugs
//

import MessageUI
import UIKit

/// Настройки: те же группы и пункты, что в Coin Recognizer (support / feedback / security).
final class SettingsViewController: UIViewController {
    private var hiddenPremiumTapCount = 0

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
        view.addSubview(tableView)
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safe.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
        tableView.reloadData()
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
        presentSimpleAlert(title: L10n.string("common.done"), message: "Подписка теперь активна.")
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

    // MARK: - Actions (как в CoinRecognizer / SettingsPresenter)

    private func contactUs() {
        let email = L10n.string("settings.support.email")
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
        openURLString(L10n.string("settings.link.app_store"))
    }

    private func shareApp() {
        let urlString = L10n.string("settings.link.share")
        guard let url = URL(string: urlString) else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }

    private func privacyPolicy() {
        openURLString(L10n.string("settings.link.privacy"))
    }

    private func termsOfUse() {
        openURLString(L10n.string("settings.link.terms"))
    }

    private func showRefundConsentAlert() {
        RefundConsentFlow.present(from: self) {}
    }

    private func deleteAccount() {
        let alert = UIAlertController(
            title: "Удалить аккаунт?",
            message: "Это действие безвозвратно удалит аккаунт и локальные данные на этом устройстве. Продолжить?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
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
            presentSimpleAlert(title: L10n.string("common.done"), message: "Аккаунт удален.")
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
                configureCell(cell, titleKey: "settings.row.terms", symbolName: "trash")
                var content = cell.defaultContentConfiguration()
                content.text = "Удалить аккаунт"
                content.textProperties.color = .systemRed
                if let img = UIImage(systemName: "trash") {
                    content.image = img
                    content.imageProperties.tintColor = .systemRed
                }
                cell.contentConfiguration = content
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
