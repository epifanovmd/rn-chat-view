import IOSChatView
import UIKit

// MARK: - Thread Demo View Controller

/// Экран обсуждения (тред). Первое сообщение — закреплённое (.pinned),
/// далее обычный диалог. Может быть открыт из основного чата по тапу на тред-индикатор.
final class ThreadDemoViewController: UIViewController, ChatViewControllerDelegate {

    private let chatVC = ChatViewController()
    private let rootMessage: ChatMessage
    private var threadMessages: [ChatMessage]

    // MARK: - Init

    /// - Parameters:
    ///   - rootMessage: Исходное сообщение, открытое для обсуждения
    ///   - existingReplies: Уже существующие ответы в треде (если есть)
    ///   - theme: Тема чата
    init(rootMessage: ChatMessage, existingReplies: [ChatMessage] = [], theme: ChatTheme = .dark) {
        // Создаём pinned-версию root-сообщения
        let pinned = ChatMessage(
            id: rootMessage.id,
            content: rootMessage.content,
            timestamp: rootMessage.timestamp,
            senderName: rootMessage.senderName,
            ownership: .pinned,
            groupDate: rootMessage.groupDate,
            status: rootMessage.status,
            reply: nil,
            forwardedFrom: rootMessage.forwardedFrom,
            reactions: rootMessage.reactions,
            isEdited: rootMessage.isEdited,
            actions: []
        )
        self.rootMessage = pinned
        self.threadMessages = existingReplies
        super.init(nibName: nil, bundle: nil)
        chatVC.theme = theme
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Обсуждение"
        view.backgroundColor = chatVC.theme.backgroundColor
        navigationItem.largeTitleDisplayMode = .never

        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "👀", "💯", "🔥"]
        chatVC.features.showFloatingDate = false
        chatVC.features.showDateSeparators = false
        chatVC.delegate = self

        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        chatVC.didMove(toParent: self)

        chatVC.hasMore = false
        reloadMessages()
    }

    private func reloadMessages() {
        chatVC.updateMessages([rootMessage] + threadMessages)
    }

    // MARK: - ChatViewControllerDelegate

    func chatDidTapFAB() { chatVC.scrollToBottom(animated: true) }

    func chatDidSelectAction(actionId: String, messageId: String) {
        guard let msg = chatVC.message(forID: messageId) else { return }
        switch actionId {
        case "reply":
            chatVC.beginReply(info: ReplyInfo(
                replyToId: messageId,
                senderName: msg.senderName ?? "Вы",
                text: msg.content.text,
                hasImage: false
            ))
        case "delete":
            threadMessages.removeAll { $0.id == messageId }
            reloadMessages()
        default: break
        }
    }

    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {
        toggleReaction(emoji: emoji, messageId: messageId)
    }

    func chatDidTapReaction(messageId: String, emoji: String) {
        toggleReaction(emoji: emoji, messageId: messageId)
    }

    private func toggleReaction(emoji: String, messageId: String) {
        guard let idx = threadMessages.firstIndex(where: { $0.id == messageId }) else { return }
        let msg = threadMessages[idx]
        var reactions = msg.reactions

        if let rIdx = reactions.firstIndex(where: { $0.emoji == emoji }) {
            let existing = reactions[rIdx]
            if existing.isSelected {
                if existing.count <= 1 { reactions.remove(at: rIdx) }
                else { reactions[rIdx] = Reaction(emoji: emoji, count: existing.count - 1, isSelected: false) }
            } else {
                reactions[rIdx] = Reaction(emoji: emoji, count: existing.count + 1, isSelected: true)
            }
        } else {
            reactions.append(Reaction(emoji: emoji, count: 1, isSelected: true))
        }

        threadMessages[idx] = ChatMessage(
            id: msg.id, content: msg.content, timestamp: msg.timestamp,
            senderName: msg.senderName, ownership: msg.ownership, groupDate: msg.groupDate,
            status: msg.status, reply: msg.reply, forwardedFrom: msg.forwardedFrom,
            reactions: reactions, isEdited: msg.isEdited, actions: msg.actions
        )
        reloadMessages()
    }

    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }

    func chatDidSendMessage(text: String, replyToId: String?) {
        let now = Date()
        let actions = [
            MessageAction(id: "reply", title: "Ответить", systemImage: "arrowshape.turn.up.left", isDestructive: false),
            MessageAction(id: "delete", title: "Удалить", systemImage: "trash", isDestructive: true),
        ]
        let msg = ChatMessage(
            id: UUID().uuidString,
            content: MessageBody(text: text, content: nil),
            timestamp: now,
            senderName: nil,
            ownership: .mine,
            groupDate: DateHelper.shared.groupKey(from: now),
            status: .sending,
            reply: replyToId.flatMap { id in
                chatVC.message(forID: id).map {
                    ReplyInfo(replyToId: id, senderName: $0.senderName ?? "Вы", text: $0.content.text, hasImage: false)
                }
            },
            forwardedFrom: nil,
            reactions: [],
            isEdited: false,
            actions: actions
        )
        threadMessages.append(msg)
        reloadMessages()
    }

    func chatDidEditMessage(text: String, messageId: String) {}
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() {}
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {}
    func chatDidChangeInputText(_ text: String) {}
}

// MARK: - Thread Preview Data

/// Хранит данные тредов для демо (в реальном приложении это было бы на сервере)
enum ThreadDemoStore {

    /// Фиксированные ответы для демонстрации тредов
    static func replies(for threadId: String) -> [ChatMessage] {
        let cal = Calendar.current
        let now = Date()
        let today = DateHelper.shared.groupKey(from: now)
        let replyActions = [
            MessageAction(id: "reply", title: "Ответить", systemImage: "arrowshape.turn.up.left", isDestructive: false),
            MessageAction(id: "delete", title: "Удалить", systemImage: "trash", isDestructive: true),
        ]

        switch threadId {
        case "thread-1":
            return [
                ChatMessage(
                    id: "t1-r1",
                    content: MessageBody(text: "Да, привет! Всё хорошо, спасибо 😊", content: nil),
                    timestamp: cal.date(byAdding: .hour, value: -24, to: now)!,
                    senderName: "Борис",
                    ownership: .theirs,
                    groupDate: today,
                    status: .read,
                    reply: nil, forwardedFrom: nil, reactions: [],
                    isEdited: false, actions: replyActions
                ),
                ChatMessage(
                    id: "t1-r2",
                    content: MessageBody(text: "У нас новый проект стартует на следующей неделе", content: nil),
                    timestamp: cal.date(byAdding: .hour, value: -23, to: now)!,
                    senderName: "Борис",
                    ownership: .theirs,
                    groupDate: today,
                    status: .read,
                    reply: nil, forwardedFrom: nil,
                    reactions: [Reaction(emoji: "🔥", count: 1, isSelected: true)],
                    isEdited: false, actions: replyActions
                ),
                ChatMessage(
                    id: "t1-r3",
                    content: MessageBody(text: "Круто! Расскажи подробнее", content: nil),
                    timestamp: cal.date(byAdding: .hour, value: -22, to: now)!,
                    senderName: nil,
                    ownership: .mine,
                    groupDate: today,
                    status: .read,
                    reply: nil, forwardedFrom: nil, reactions: [],
                    isEdited: false, actions: replyActions
                ),
                ChatMessage(
                    id: "t1-r4",
                    content: MessageBody(text: "Мобильное приложение для доставки, Swift + Kotlin", content: nil),
                    timestamp: cal.date(byAdding: .hour, value: -21, to: now)!,
                    senderName: "Борис",
                    ownership: .theirs,
                    groupDate: today,
                    status: .read,
                    reply: ReplyInfo(replyToId: "t1-r3", senderName: "Вы", text: "Круто! Расскажи подробнее", hasImage: false),
                    forwardedFrom: nil, reactions: [],
                    isEdited: false, actions: replyActions
                ),
                ChatMessage(
                    id: "t1-r5",
                    content: MessageBody(text: "Звучит интересно, я в деле 👍", content: nil),
                    timestamp: cal.date(byAdding: .hour, value: -20, to: now)!,
                    senderName: nil,
                    ownership: .mine,
                    groupDate: today,
                    status: .delivered,
                    reply: nil, forwardedFrom: nil, reactions: [],
                    isEdited: false, actions: replyActions
                ),
            ]

        case "thread-2":
            return [
                ChatMessage(
                    id: "t2-r1",
                    content: MessageBody(text: "Выглядит классно! Покажи ещё скриншоты", content: nil),
                    timestamp: cal.date(byAdding: .hour, value: -23, to: now)!,
                    senderName: "Алиса",
                    ownership: .theirs,
                    groupDate: today,
                    status: .read,
                    reply: nil, forwardedFrom: nil, reactions: [],
                    isEdited: false, actions: replyActions
                ),
                ChatMessage(
                    id: "t2-r2",
                    content: MessageBody(text: "Да, сейчас закончу тёмную тему и скину", content: nil),
                    timestamp: cal.date(byAdding: .hour, value: -22, to: now)!,
                    senderName: nil,
                    ownership: .mine,
                    groupDate: today,
                    status: .read,
                    reply: nil, forwardedFrom: nil, reactions: [],
                    isEdited: false, actions: replyActions
                ),
            ]

        default:
            return []
        }
    }
}
