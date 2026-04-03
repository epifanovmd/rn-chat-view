import UIKit
import SwiftUI

// MARK: - Message Generator

private enum MessageGenerator {
    static let users = ["Алиса", "Боб", "Катя"]
    static let texts = [
        "Привет! Как дела?",
        "Отлично, спасибо 👍",
        "Когда будет готов релиз?",
        "Уже почти, осталось немного",
        "Давайте обсудим на созвоне",
        "Ок, в 15:00 удобно?",
        "Да, подключусь",
        "Посмотри PR, я оставил комменты",
        "Сейчас гляну",
        "Баг пофиксил, можно мержить",
        "Супер! 🚀",
        "Не забудь обновить документацию",
        "Уже обновил",
        "Кто-нибудь тестировал на реальном устройстве?",
        "Я проверил на iPhone 15, всё ок",
        "На iPad тоже работает",
        "Нужно ещё добавить тёмную тему",
        "Она уже есть, переключи в настройках",
        "Точно! Не заметил 😅",
        "Завтра планирую выкатить в TestFlight",
    ]

    static func generate(count: Int, startIndex: Int, baseDate: Date, direction: Direction) -> [ChatMessage] {
        let cal = Calendar.current
        return (0..<count).map { i in
            let idx = startIndex + i
            let safeIdx = abs(idx)
            let isMine = safeIdx % 3 == 0
            let user = isMine ? nil : users[safeIdx % users.count]
            let text = texts[safeIdx % texts.count]
            let offset: Int
            switch direction {
            case .older: offset = -(count - i)
            case .newer: offset = i + 1
            }
            let date = cal.date(byAdding: .minute, value: offset * 2, to: baseDate)!
            let groupDate = DateHelper.shared.groupKey(from: date)

            return ChatMessage(
                id: "page-\(idx)",
                content: MessageContent(text: text, media: nil, voice: nil, poll: nil, files: nil),
                timestamp: date,
                senderName: user,
                isMine: isMine,
                groupDate: groupDate,
                status: isMine ? .read : .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: []
            )
        }
    }

    enum Direction { case older, newer }
}

// MARK: - PaginationDemoViewController

final class PaginationDemoViewController: UIViewController, ChatViewControllerDelegate {

    private let chatVC = ChatViewController()
    private var allMessages: [ChatMessage] = []
    private var oldestIndex = 50
    private var newestIndex = 70
    private let pageSize = 20
    private let maxNewerIndex = 200
    private let baseDate = Date()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ChatTheme.dark.backgroundColor

        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.showsSenderName = true
        chatVC.hasMore = true
        chatVC.hasNewer = true

        addChild(chatVC)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatVC.view)
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        chatVC.didMove(toParent: self)

        // Initial load — middle chunk
        let initial = MessageGenerator.generate(
            count: newestIndex - oldestIndex,
            startIndex: oldestIndex,
            baseDate: baseDate,
            direction: .older
        )
        allMessages = initial.sorted { $0.timestamp < $1.timestamp }

        // Scroll to message in the middle on initial load
        let middleIdx = oldestIndex + (newestIndex - oldestIndex) / 2
        chatVC.pendingScrollMessageId = "page-\(middleIdx)"

        chatVC.updateMessages(allMessages)
    }

    // MARK: - ChatViewControllerDelegate

    func chatDidScroll(offset: CGPoint) {}
    func chatMessagesDidAppear(ids: [String]) {}
    func chatDidChangeInputText(_ text: String) {}

    func chatDidReachTop(distance: CGFloat) {
        chatVC.isLoadingTop = true
        let loadFrom = oldestIndex - pageSize

        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
            guard let self else { return }
            let older = MessageGenerator.generate(
                count: self.pageSize,
                startIndex: loadFrom,
                baseDate: Calendar.current.date(byAdding: .minute, value: -((self.oldestIndex - loadFrom) * 2), to: self.baseDate)!,
                direction: .older
            )
            self.oldestIndex = loadFrom
            self.allMessages.insert(contentsOf: older.sorted { $0.timestamp < $1.timestamp }, at: 0)
            self.chatVC.isLoadingTop = false
            self.chatVC.updateMessages(self.allMessages)
        }
    }

    func chatDidReachBottom(distance: CGFloat) {
        guard newestIndex < maxNewerIndex else {
            chatVC.hasNewer = false
            return
        }

        chatVC.isLoadingBottom = true
        let loadTo = min(maxNewerIndex, newestIndex + pageSize)
        let count = loadTo - newestIndex

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            let newer = MessageGenerator.generate(
                count: count,
                startIndex: self.newestIndex,
                baseDate: self.baseDate,
                direction: .newer
            )
            self.newestIndex = loadTo
            self.allMessages.append(contentsOf: newer.sorted { $0.timestamp < $1.timestamp })
            self.chatVC.hasNewer = self.newestIndex < self.maxNewerIndex
            self.chatVC.isLoadingBottom = false
            self.chatVC.updateMessages(self.allMessages)
        }
    }

    func chatDidTapFAB() {
        chatVC.clearUnread()
        chatVC.scrollToBottom(animated: true)
    }

    func chatDidTapMessage(id: String, attachmentIndex: Int?) {}
    func chatDidSelectAction(actionId: String, messageId: String) {}
    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {}
    func chatDidTapReaction(messageId: String, emoji: String) {}
    func chatDidTapReplyMessage(id: String) {}
    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String) {}
    func chatDidTapPollDetail(messageId: String, pollId: String) {}

    func chatDidSendMessage(text: String, replyToId: String?) {
        let today = DateHelper.shared.groupKey(from: Date())
        let msg = ChatMessage(
            id: UUID().uuidString,
            content: MessageContent(text: text, media: nil, voice: nil, poll: nil, files: nil),
            timestamp: Date(),
            senderName: nil,
            isMine: true,
            groupDate: today,
            status: .sending,
            reply: nil,
            forwardedFrom: nil,
            reactions: [],
            isEdited: false,
            actions: []
        )
        allMessages.append(msg)
        chatVC.updateMessages(allMessages)
    }

    func chatDidEditMessage(text: String, messageId: String) {}
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() {}
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {}
}

// MARK: - SwiftUI Wrapper

struct PaginationDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PaginationDemoViewController {
        PaginationDemoViewController()
    }
    func updateUIViewController(_ vc: PaginationDemoViewController, context: Context) {}
}
