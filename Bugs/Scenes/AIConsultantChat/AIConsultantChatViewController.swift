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
        imageView.image = UIImage(named: "chat_avatar")
    }

    required init?(coder: NSCoder) {
        nil
    }
}

final class AIConsultantChatViewController: MessagesViewController {

    private static let avatarHeaderHeight: CGFloat = 128
    private static let streamingAIMessageId = "ai.streaming.placeholder"
    private static let typingMessageId = "ai.typing.placeholder"
    private static let freeMessagesLimit = 3
    private static let freeMessagesCountKey = "bugs.ai.free.message.count"

    /// Открытие с таббара модально: «Назад» закрывает экран через `dismiss`, а не `pop`.
    var presentsAsModalFromTabBar: Bool = false

    private let aiSender = ChatSender(senderId: "ai.consultant", displayName: "AI")
    private let userSender = ChatSender(senderId: "user", displayName: "Me")

    private var messages: [ChatMessage] = []
    private var chatId: Int?
    private let socket = CollectChatWebSocketClient()
    private var isStreamingAI = false
    private var aiStreamBuffer = ""
    private var typingDotsTask: Task<Void, Never>?

    /// Разрешаем рисовать чанки сокета: после завершения гейта открытия, после успешного POST, пока не придёт пустой delta или `applyDetail` не сбросит ленту.
    private var acceptingSocketStream = false

    /// После фона: алерт и закрытие чата по OK (см. `handleAppDidEnterBackground`).
    private var pendingConnectionLossAlert = false

    /// Пока `true`: данные чата подгружаем, но ленту не показываем; чанки WS только буферизуем до тишины или конца стрима.
    private var socketSettleGateActive = false
    private var socketSettleGateBeganAt: Date?
    private var socketSettleIdleWaitTask: Task<Void, Never>?

    private var backgroundObservers: [NSObjectProtocol] = []

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.hidesWhenStopped = true
        return v
    }()

    private var sendButton: ChatFullBleedSendButton? {
        messageInputBar.sendButton as? ChatFullBleedSendButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        navigationItem.title = L10n.string("ai_chat.title")
        configureNavigationBar()
        if presentsAsModalFromTabBar {
            configureModalDismissBackButton()
        } else if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = nil
        } else {
            configureBackButton()
        }
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        registerHeader()
        configureMessageCollectionView()
        configureInputBar()
        messageInputBar.isUserInteractionEnabled = false
        messagesCollectionView.isHidden = true
        loadingIndicator.startAnimating()
        messagesCollectionView.reloadData()
        registerAppLifecycleObservers()
        runBootstrap()
    }

    deinit {
        for o in backgroundObservers {
            NotificationCenter.default.removeObserver(o)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySubscriptionStatusForAppearance()
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if presentConnectionLossAlertIfNeeded() { return }
        guard chatId != nil else { return }
        guard presentedViewController == nil else { return }
        beginSocketSettleGate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if presentsAsModalFromTabBar {
            disableInteractivePopGestureIfNeeded()
        } else {
            restoreInteractivePopGestureIfNeeded()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        restoreInteractivePopGestureIfNeeded()
        socket.disconnect()
        if isChatActuallyLeavingHierarchy {
            socketSettleIdleWaitTask?.cancel()
            socketSettleIdleWaitTask = nil
            socketSettleGateActive = false
            socketSettleGateBeganAt = nil
            loadingIndicator.stopAnimating()
            acceptingSocketStream = false
            isStreamingAI = false
            aiStreamBuffer = ""
            stripStreamingPlaceholderIfNeeded()
        }
    }

    /// `false`, если экран только перекрыли модалкой/оверлеем — иначе сброс стрима рвёт ответ, хотя чанки в логе идут.
    private var isChatActuallyLeavingHierarchy: Bool {
        if isBeingDismissed || isMovingFromParent { return true }
        if let nav = navigationController {
            return !nav.viewControllers.contains(where: { $0 === self })
        }
        return false
    }

    private func registerAppLifecycleObservers() {
        let center = NotificationCenter.default
        backgroundObservers.append(center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        })
        backgroundObservers.append(center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.isViewLoaded else { return }
            _ = self.presentConnectionLossAlertIfNeeded()
        })
    }

    /// Чат модально в `UINavigationController`: реагируем только когда этот экран сверху.
    private var isChatScreenOnTop: Bool {
        isViewLoaded && view.window != nil && (navigationController?.topViewController === self)
    }

    private func handleAppDidEnterBackground() {
        guard isChatScreenOnTop, chatId != nil else { return }
        socket.disconnect()
        acceptingSocketStream = false
        isStreamingAI = false
        aiStreamBuffer = ""
        stripStreamingPlaceholderIfNeeded()
        messageInputBar.isUserInteractionEnabled = true
        pendingConnectionLossAlert = true
    }

    private func stripStreamingPlaceholderIfNeeded() {
        guard let idx = messages.lastIndex(where: { $0.messageId == Self.streamingAIMessageId }) else { return }
        messages.remove(at: idx)
        messagesCollectionView.reloadData()
    }

    private func stripTypingPlaceholderIfNeeded() {
        guard let idx = messages.lastIndex(where: { $0.messageId == Self.typingMessageId }) else { return }
        messages.remove(at: idx)
        messagesCollectionView.reloadData()
    }

    /// Лента скрыта: только проверка WS (тишина / конец стрима). Историю с API подтягиваем **после** этого в `completeSettleGateWithFreshMessages`.
    private func beginSocketSettleGate() {
        guard !socketSettleGateActive else { return }
        socketSettleGateActive = true
        socketSettleGateBeganAt = Date()
        messagesCollectionView.isHidden = true
        loadingIndicator.startAnimating()
        view.bringSubviewToFront(loadingIndicator)
        messageInputBar.isUserInteractionEnabled = false
        messagesCollectionView.isUserInteractionEnabled = false
        acceptingSocketStream = false
        isStreamingAI = false
        aiStreamBuffer = ""
        socketSettleIdleWaitTask?.cancel()
        socketSettleIdleWaitTask = nil
        Task { @MainActor [weak self] in
            self?.startWebSocket()
            self?.scheduleSocketSettleIdleFallback()
        }
    }

    /// 2 с без активного стрима после подключения — показываем ленту. Если уже шли непустые чанки, **не** закрываем гейт по таймеру (иначе хвост уходит в обычный `handleSocketText` и снова рисуется по кускам).
    private func scheduleSocketSettleIdleFallback() {
        socketSettleIdleWaitTask?.cancel()
        socketSettleIdleWaitTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                return
            }
            guard let self, self.socketSettleGateActive else { return }
            if let began = self.socketSettleGateBeganAt, Date().timeIntervalSince(began) > 120 {
                self.isStreamingAI = false
                self.aiStreamBuffer = ""
                self.acceptingSocketStream = false
                await self.completeSettleGateWithFreshMessages()
                return
            }
            if self.isStreamingAI {
                self.scheduleSocketSettleIdleFallback()
                return
            }
            await self.completeSettleGateWithFreshMessages()
        }
    }

    @MainActor
    private func completeSettleGateWithFreshMessages() async {
        guard socketSettleGateActive else { return }
        await refetchChatFromServerSilently(updateCollectionView: false)
        // После пустого delta ответ может ещё не попасть в GET — один короткий повтор.
        if messages.isEmpty, chatId != nil {
            try? await Task.sleep(nanoseconds: 350_000_000)
            await refetchChatFromServerSilently(updateCollectionView: false)
        }
        revealChatAfterSettleGate()
    }

    /// Всегда обновляет UI (без `guard socketSettleGateActive`): иначе при двух почти одновременных `completeSettleGate…` (idle + пустой delta) второй `applyDetail` обновляет `messages`, а `reloadData` не вызывается — лента пустая.
    private func revealChatAfterSettleGate() {
        socketSettleIdleWaitTask?.cancel()
        socketSettleIdleWaitTask = nil
        socketSettleGateActive = false
        socketSettleGateBeganAt = nil
        loadingIndicator.stopAnimating()
        messagesCollectionView.isHidden = false
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: false)
        messagesCollectionView.isUserInteractionEnabled = true
        messageInputBar.isUserInteractionEnabled = true
        acceptingSocketStream = true
    }

    private func handleSocketTextWhileSettleGate(delta: String) {
        if delta.isEmpty {
            if isStreamingAI {
                socketSettleIdleWaitTask?.cancel()
                socketSettleIdleWaitTask = nil
                isStreamingAI = false
                aiStreamBuffer = ""
                acceptingSocketStream = false
                Task { @MainActor [weak self] in
                    await self?.completeSettleGateWithFreshMessages()
                }
            }
            return
        }
        socketSettleIdleWaitTask?.cancel()
        socketSettleIdleWaitTask = nil
        if !isStreamingAI {
            isStreamingAI = true
            aiStreamBuffer = delta
        } else {
            aiStreamBuffer += delta
        }
        scheduleSocketSettleIdleFallback()
    }

    /// `true`, если показали алерт (экран чата после OK закрывается — гейт не запускаем).
    @discardableResult
    private func presentConnectionLossAlertIfNeeded() -> Bool {
        guard pendingConnectionLossAlert else { return false }
        guard isChatScreenOnTop, chatId != nil else { return false }
        guard presentedViewController == nil else { return false } // не трогаем `pending`, покажем после снятия чужой модалки
        pendingConnectionLossAlert = false
        let a = UIAlertController(title: nil, message: L10n.string("ai_chat.alert.connection_lost.message"), preferredStyle: .alert)
        a.addAction(UIAlertAction(title: L10n.string("ai_chat.alert.connection_lost.action"), style: .default) { [weak self] _ in
            self?.closeChatAfterConnectionLoss()
        })
        present(a, animated: true)
        return true
    }

    private func closeChatAfterConnectionLoss() {
        if presentsAsModalFromTabBar {
            navigationController?.dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func runBootstrap() {
        Task { @MainActor in
            do {
                let detail = try await CollectChatBootstrapper.loadOrCreateChat(
                    seedMessage: L10n.string("ai_chat.seed_creation_message")
                )
                chatId = detail.id
                messages = []
                messagesCollectionView.reloadData()
                beginSocketSettleGate()
            } catch CollectChatFlowError.noAuthToken {
                loadingIndicator.stopAnimating()
                messagesCollectionView.isHidden = false
                messageInputBar.isUserInteractionEnabled = true
                UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
            } catch {
                loadingIndicator.stopAnimating()
                messagesCollectionView.isHidden = false
                messageInputBar.isUserInteractionEnabled = true
                UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
            }
        }
    }

    private func applyDetail(_ detail: CollectChatDetailDTO) {
        acceptingSocketStream = false
        isStreamingAI = false
        aiStreamBuffer = ""

        var sorted = detail.messages.sorted(by: { $0.id < $1.id })
        // Не показываем сид при создании чата, но только если после удаления остаётся история — иначе лента пустая (типично сразу после POST + GET).
        if sorted.count > 1, let first = sorted.first, first.sender != nil {
            sorted.removeFirst()
        }
        messages = sorted.map { dto in
            let isUser = dto.sender != nil
            let sender: SenderType = isUser ? userSender : aiSender
            let date = Self.parseChatDate(dto.createdAt) ?? Date()
            return ChatMessage(
                sender: sender,
                messageId: "api-\(dto.id)",
                sentDate: date,
                kind: .text(dto.text)
            )
        }
    }

    private static func parseChatDate(_ s: String) -> Date? {
        let withFrac = ISO8601DateFormatter()
        withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFrac.date(from: s) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: s)
    }

    private func startWebSocket() {
        socket.connect { [weak self] text in
            self?.handleSocketText(text)
        }
    }

    /// Декодирование как в legacy; запасной разбор — если прилетит другой JSON, а в консоли уже виден текст.
    private static func parseSocketStreamPayload(_ text: String, expectedChatId: Int) -> (matchesChat: Bool, delta: String) {
        guard let data = text.data(using: .utf8) else { return (false, "") }
        let decoder = JSONDecoder()
        if let chunk = try? decoder.decode(CollectChatSocketChunk.self, from: data) {
            guard chunk.chatID == expectedChatId else { return (false, "") }
            let d = chunk.chunk.choices.first?.delta.content ?? ""
            return (true, d)
        }
        if let env = try? decoder.decode(CollectChatInsectsEnvelope<CollectChatSocketChunk>.self, from: data) {
            let chunk = env.insectsPayload
            guard chunk.chatID == expectedChatId else { return (false, "") }
            let d = chunk.chunk.choices.first?.delta.content ?? ""
            return (true, d)
        }
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return (false, "") }
        let candidates = Self.socketJSONCandidateObjects(root)
        for obj in candidates {
            guard let cid = Self.jsonIntForSocket(obj["chat_id"]), cid == expectedChatId else { continue }
            if let d = Self.deltaStringFromChunkObject(obj["chunk"]) { return (true, d) }
        }
        for obj in candidates {
            guard Self.jsonIntForSocket(obj["chat_id"]) == nil else { continue }
            if let d = Self.deltaStringFromChunkObject(obj["chunk"]), !d.isEmpty { return (true, d) }
        }
        return (false, "")
    }

    /// Все словари, где может лежать пара `chat_id` + `chunk` (корень, `insects_payload`, вложенные поля).
    private static func socketJSONCandidateObjects(_ root: [String: Any]) -> [[String: Any]] {
        var out: [[String: Any]] = [root]
        let nestedKeys = ["insects_payload", "data", "payload", "result", "message"]
        for k in nestedKeys {
            if let d = root[k] as? [String: Any] { out.append(d) }
        }
        if let payload = root["insects_payload"] as? [String: Any] {
            for k in nestedKeys where k != "insects_payload" {
                if let d = payload[k] as? [String: Any] { out.append(d) }
            }
        }
        return out
    }

    private static func deltaStringFromChunkObject(_ chunk: Any?) -> String? {
        guard let ch = chunk as? [String: Any] else { return nil }
        let choices = ch["choices"] as? [[String: Any]] ?? []
        guard let first = choices.first, let deltaObj = first["delta"] as? [String: Any] else { return nil }
        return deltaObj["content"] as? String ?? ""
    }

    private static func jsonIntForSocket(_ value: Any?) -> Int? {
        switch value {
        case let i as Int: return i
        case let i as Int64: return Int(i)
        case let d as Double: return Int(d)
        case let n as NSNumber: return n.intValue
        case let s as String: return Int(s)
        default: return nil
        }
    }

    private func handleSocketText(_ text: String) {
        guard let chatId else { return }
        let parsed = Self.parseSocketStreamPayload(text, expectedChatId: chatId)
        guard parsed.matchesChat else { return }

        if socketSettleGateActive {
            handleSocketTextWhileSettleGate(delta: parsed.delta)
            return
        }

        let delta = parsed.delta
        // Пустые delta в начале стрима (роль, служебные кадры) — не конец ответа; конец — пустой кадр уже во время показа стрима.
        if delta.isEmpty {
            if isStreamingAI {
                isStreamingAI = false
                aiStreamBuffer = ""
                acceptingSocketStream = false
                stopTypingAnimation()
                setSendLoadingState(false)
                messageInputBar.isUserInteractionEnabled = true
                Task { @MainActor [weak self] in
                    await self?.refetchChatFromServerSilently()
                }
            }
            return
        }

        if !isStreamingAI {
            stripTypingPlaceholderIfNeeded()
            stopTypingAnimation()
            isStreamingAI = true
            aiStreamBuffer = delta
            let msg = ChatMessage(
                sender: aiSender,
                messageId: Self.streamingAIMessageId,
                sentDate: Date(),
                kind: .text(delta)
            )
            messages.append(msg)
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToLastItem(animated: true)
        } else {
            aiStreamBuffer += delta
            guard let idx = messages.lastIndex(where: { $0.messageId == Self.streamingAIMessageId }) else { return }
            let prev = messages[idx]
            messages[idx] = ChatMessage(
                sender: aiSender,
                messageId: Self.streamingAIMessageId,
                sentDate: prev.sentDate,
                kind: .text(aiStreamBuffer)
            )
            applyStreamingChunkToVisibleCell(section: idx)
            messagesCollectionView.scrollToLastItem(animated: false)
        }
    }

    /// Без `reloadSections`: иначе каждый чанк заново конфигурирует ячейку и «прыгает» фон пузыря.
    private func applyStreamingChunkToVisibleCell(section idx: Int) {
        let indexPath = IndexPath(item: 0, section: idx)
        UIView.performWithoutAnimation {
            if let cell = messagesCollectionView.cellForItem(at: indexPath) as? TextMessageCell {
                cell.messageLabel.text = aiStreamBuffer
                cell.messageLabel.textColor = AIChatPalette.incomingText
                cell.messageLabel.font = .systemFont(ofSize: 16, weight: .regular)
                cell.messageContainerView.backgroundColor = AIChatPalette.incomingBubble
                cell.messageContainerView.style = bubbleStyle(outgoing: false)
            }
            messagesCollectionView.collectionViewLayout.invalidateLayout()
            messagesCollectionView.layoutIfNeeded()
        }
    }

    @MainActor
    private func refetchChatFromServerSilently(updateCollectionView: Bool = true) async {
        guard let id = chatId else { return }
        do {
            let detail = try await CollectChatBootstrapper.fetchChatDetail(id: id)
            applyDetail(detail)
            if updateCollectionView {
                messagesCollectionView.reloadData()
                messagesCollectionView.scrollToLastItem(animated: false)
            }
        } catch {
            // Оставляем текущую ленту; устаревшие чанки всё равно отфильтрованы поколением.
        }
    }

    private func configureNavigationBar() {
        if let nav = navigationController?.navigationBar {
            AppNavigationBarAppearance.apply(to: nav)
        }
    }

    private func configureBackButton() {
        navigationItem.leftBarButtonItem = makeCircleBackBarButton(action: #selector(backTapped))
    }

    private func configureModalDismissBackButton() {
        navigationItem.leftBarButtonItem = makeCircleBackBarButton(action: #selector(modalDismissTapped))
    }

    private func makeCircleBackBarButton(action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "library_nav_back"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: action, for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32),
        ])
        return UIBarButtonItem(customView: button)
    }

    @objc
    private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func modalDismissTapped() {
        navigationController?.dismiss(animated: true)
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

    private func setSendLoadingState(_ loading: Bool) {
        sendButton?.setLoading(loading)
    }

    private func appendTypingPlaceholderAndAnimate() {
        stopTypingAnimation()
        stripTypingPlaceholderIfNeeded()
        let typing = ChatMessage(sender: aiSender, messageId: Self.typingMessageId, sentDate: Date(), kind: .text("."))
        messages.append(typing)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
        typingDotsTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let frames = [".", "..", "..."]
            var idx = 0
            while !Task.isCancelled {
                if let msgIndex = self.messages.lastIndex(where: { $0.messageId == Self.typingMessageId }) {
                    let prev = self.messages[msgIndex]
                    self.messages[msgIndex] = ChatMessage(
                        sender: prev.sender,
                        messageId: prev.messageId,
                        sentDate: prev.sentDate,
                        kind: .text(frames[idx])
                    )
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToLastItem(animated: false)
                }
                idx = (idx + 1) % frames.count
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
        }
    }

    private func stopTypingAnimation() {
        typingDotsTask?.cancel()
        typingDotsTask = nil
    }

    private func canSendFreeMessage() -> Bool {
        if SubscriptionAccess.shared.isPremiumActive { return true }
        return UserDefaults.standard.integer(forKey: Self.freeMessagesCountKey) < Self.freeMessagesLimit
    }

    private func incrementFreeMessagesCountIfNeeded() {
        guard !SubscriptionAccess.shared.isPremiumActive else { return }
        let current = UserDefaults.standard.integer(forKey: Self.freeMessagesCountKey)
        UserDefaults.standard.set(current + 1, forKey: Self.freeMessagesCountKey)
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
        guard !trimmed.isEmpty, let id = chatId else { return }
        guard canSendFreeMessage() else {
            presentPaywallFullScreen()
            return
        }

        let messageId = UUID().uuidString
        let newMessage = ChatMessage(
            sender: userSender,
            messageId: messageId,
            sentDate: Date(),
            kind: .text(trimmed)
        )
        messages.append(newMessage)
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()

        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)

        messageInputBar.isUserInteractionEnabled = false
        setSendLoadingState(true)
        appendTypingPlaceholderAndAnimate()
        acceptingSocketStream = true
        Task {
            do {
                _ = try await CollectChatHTTPClient.shared.postJSON(path: "chats/\(id)/", body: ["text": trimmed])
                await MainActor.run { [weak self] in
                    self?.incrementFreeMessagesCountIfNeeded()
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    acceptingSocketStream = false
                    if let idx = messages.lastIndex(where: { $0.messageId == messageId }) {
                        messages.remove(at: idx)
                        messagesCollectionView.reloadData()
                    }
                    stripTypingPlaceholderIfNeeded()
                    stopTypingAnimation()
                    setSendLoadingState(false)
                    messageInputBar.isUserInteractionEnabled = true
                    UserFacingRequestErrorAlert.presentTryAgainLater(from: self)
                }
            }
        }
    }
}
