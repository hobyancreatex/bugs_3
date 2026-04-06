//
//  AIConsultantChatViewController.swift
//  Bugs
//

import InputBarAccessoryView
import MessageKit
import UIKit

private struct ChatSender: SenderType {
    let senderId: String
    let displayName: String
}

private struct ChatMessage: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    let kind: MessageKind
}

private enum AIChatPalette {
    static let incomingBubble = UIColor(red: 186 / 255, green: 174 / 255, blue: 71 / 255, alpha: 0.15)
    static let outgoingBubble = UIColor(red: 58 / 255, green: 161 / 255, blue: 118 / 255, alpha: 1)
    static let incomingText = UIColor.appTextPrimary
    static let inputFieldBackground = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
    static let bubbleCornerRadius: CGFloat = 20
    /// Минимальная высота пузыря (контейнер текста), pt: 16 + строка ~22 + 16.
    static let minimumMessageContainerHeight: CGFloat = 54
}

/// Поднимает минимальную высоту текстового пузыря до заданного значения.
private final class AIChatTextMessageSizeCalculator: TextMessageSizeCalculator {

    override func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        var size = super.messageContainerSize(for: message, at: indexPath)
        size.height = max(size.height, AIChatPalette.minimumMessageContainerHeight)
        return size
    }
}

private func bubbleStyle(outgoing: Bool) -> MessageStyle {
    .custom { container in
        container.layer.cornerRadius = AIChatPalette.bubbleCornerRadius
        container.layer.cornerCurve = .continuous
        if outgoing {
            container.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner,
            ]
        } else {
            container.layer.maskedCorners = [
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner,
            ]
        }
    }
}

/// Large avatar shown only above the first message section.
private final class AIChatAvatarHeaderReusableView: MessageReusableView {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerCurve = .continuous
        iv.layer.cornerRadius = 50
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
        imageView.image = UIImage(named: "home_popular_insect")
    }

    required init?(coder: NSCoder) {
        nil
    }
}

final class AIConsultantChatViewController: MessagesViewController {

    private static let avatarHeaderHeight: CGFloat = 128

    private let aiSender = ChatSender(senderId: "ai.consultant", displayName: "AI")
    private let userSender = ChatSender(senderId: "user", displayName: "Me")

    private var messages: [ChatMessage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        navigationItem.title = L10n.string("ai_chat.title")
        configureNavigationBar()
        configureBackButton()
        seedStarterMessages()
        registerHeader()
        configureMessageCollectionView()
        configureInputBar()
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func seedStarterMessages() {
        let now = Date()
        messages = [
            ChatMessage(
                sender: aiSender,
                messageId: "stub-ai",
                sentDate: now.addingTimeInterval(-120),
                kind: .text(L10n.string("ai_chat.stub.ai"))
            ),
            ChatMessage(
                sender: userSender,
                messageId: "stub-user",
                sentDate: now.addingTimeInterval(-60),
                kind: .text(L10n.string("ai_chat.stub.user"))
            ),
        ]
    }

    private func registerHeader() {
        messagesCollectionView.register(
            AIChatAvatarHeaderReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: String(describing: AIChatAvatarHeaderReusableView.self)
        )
    }

    private func configureMessageCollectionView() {
        messagesCollectionView.backgroundColor = .clear
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        maintainPositionOnInputBarHeightChanged = true
        scrollsToLastItemOnKeyboardBeginsEditing = true
        let layout = messagesCollectionView.messagesCollectionViewFlowLayout
        let textCalc = AIChatTextMessageSizeCalculator(layout: layout)
        textCalc.messageLabelFont = .systemFont(ofSize: 16, weight: .regular)
        textCalc.incomingMessageLabelInsets = UIEdgeInsets(top: 16, left: 18, bottom: 16, right: 14)
        textCalc.outgoingMessageLabelInsets = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 18)
        layout.textMessageSizeCalculator = textCalc
        messagesCollectionView.register(
            CenteredTextMessageCell.self,
            forCellWithReuseIdentifier: String(describing: CenteredTextMessageCell.self)
        )
    }

    private func configureInputBar() {
        messageInputBar.delegate = self
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.backgroundView.backgroundColor = .white
        messageInputBar.backgroundColor = .white

        let tv = messageInputBar.inputTextView
        tv.backgroundColor = AIChatPalette.inputFieldBackground
        tv.layer.cornerRadius = 22
        tv.layer.cornerCurve = .continuous
        tv.font = .systemFont(ofSize: 16, weight: .regular)
        // Симметричные вертикальные отступы (без правки inset из layoutSubviews — это давало цикл раскладки / падение).
        let insetY: CGFloat = 11
        tv.textContainerInset = UIEdgeInsets(top: insetY, left: 14, bottom: insetY, right: 14)
        tv.placeholder = L10n.string("ai_chat.input.placeholder")
        tv.placeholderTextColor = .placeholderText
        tv.tintColor = AIChatPalette.outgoingBubble

        let send = ChatFullBleedSendButton()
        send.configure {
            $0.setSize(CGSize(width: 48, height: 48), animated: false)
            $0.isEnabled = false
        }.onTouchUpInside {
            $0.inputBarAccessoryView?.didSelectSendButton()
        }
        if let icon = UIImage(named: "chat_send") {
            send.setImage(icon.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        send.adjustsImageWhenHighlighted = false

        messageInputBar.sendButton = send
        messageInputBar.setStackViewItems([send], forStack: .right, animated: false)
        messageInputBar.setRightStackViewWidthConstant(to: 48, animated: false)
        messageInputBar.middleContentViewPadding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        messageInputBar.padding = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    }
}

extension AIConsultantChatViewController: MessagesDataSource {

    var currentSender: SenderType {
        userSender
    }

    func messageForItem(at indexPath: IndexPath, in _: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }

    func numberOfSections(in _: MessagesCollectionView) -> Int {
        messages.count
    }

    func textCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell? {
        let cell = messagesCollectionView.dequeueReusableCell(
            CenteredTextMessageCell.self,
            for: indexPath
        )
        cell.configure(with: message, at: indexPath, and: messagesCollectionView)
        return cell
    }
}

extension AIConsultantChatViewController: MessagesDisplayDelegate {

    func messageStyle(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> MessageStyle {
        bubbleStyle(outgoing: isFromCurrentSender(message: message))
    }

    func backgroundColor(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UIColor {
        isFromCurrentSender(message: message) ? AIChatPalette.outgoingBubble : AIChatPalette.incomingBubble
    }

    func textColor(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UIColor {
        isFromCurrentSender(message: message) ? .white : AIChatPalette.incomingText
    }

    func messageHeaderView(for indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
        guard indexPath.section == 0 else {
            return messagesCollectionView.dequeueReusableHeaderView(MessageReusableView.self, for: indexPath)
        }
        return messagesCollectionView.dequeueReusableHeaderView(
            AIChatAvatarHeaderReusableView.self,
            for: indexPath
        )
    }
}

extension AIConsultantChatViewController: MessagesLayoutDelegate {

    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        guard section == 0 else { return .zero }
        let w = messagesCollectionView.bounds.width > 1
            ? messagesCollectionView.bounds.width
            : view.bounds.width
        return CGSize(width: w, height: Self.avatarHeaderHeight)
    }

    func avatarSize(for _: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> CGSize? {
        .zero
    }
}

extension AIConsultantChatViewController: MessageCellDelegate {}

extension AIConsultantChatViewController: InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newMessage = ChatMessage(
            sender: userSender,
            messageId: UUID().uuidString,
            sentDate: Date(),
            kind: .text(trimmed)
        )
        let newSection = messages.count
        messages.append(newMessage)
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()

        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([newSection])
        }, completion: { [weak self] _ in
            self?.messagesCollectionView.scrollToLastItem(animated: true)
        })
    }
}
