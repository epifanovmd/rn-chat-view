import AVFoundation
import UIKit
import SwiftUI

// MARK: - LiveChatDemoViewController

final class LiveChatDemoViewController: UIViewController, ChatViewControllerDelegate {

    private let chatVC = ChatViewController()
    private var allMessages: [ChatMessage] = []
    private var nextId = 1
    private var activityTimer: Timer?
    private let users = ["Алиса", "Борис", "Вера", "Глеб", "Дана"]
    private let emojis = ["👍", "❤️", "😂", "😮", "🔥", "🎉", "😢", "👎"]

    private let defaultActions: [MessageAction] = [
        MessageAction(id: "reply", title: "Ответить", systemImage: "arrowshape.turn.up.left", isDestructive: false),
        MessageAction(id: "copy", title: "Копировать", systemImage: "doc.on.doc", isDestructive: false),
        MessageAction(id: "forward", title: "Переслать", systemImage: "arrowshape.turn.up.right", isDestructive: false),
        MessageAction(id: "delete", title: "Удалить", systemImage: "trash", isDestructive: true),
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ChatTheme.dark.backgroundColor

        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.showsSenderName = true
        chatVC.emojiReactionsList = emojis
        chatVC.hasMore = true

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

        // Seed initial messages
        let seed = generateHistoryBatch(count: 15, before: Date())
        allMessages = seed
        chatVC.updateMessages(seed)

        // Start live activity
        activityTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.performRandomActivity()
        }
    }

    deinit {
        activityTimer?.invalidate()
    }

    // MARK: - Random Activity

    private func performRandomActivity() {
        let roll = Int.random(in: 0..<100)

        if roll < 45 {
            addIncomingMessage()
        } else if roll < 65 {
            addRandomReaction()
        } else if roll < 80 {
            randomizePollVotes()
        } else if roll < 90 {
            updateMessageStatus()
        } else {
            addIncomingMessage()
        }
    }

    // MARK: - Incoming Messages

    private func addIncomingMessage() {
        let type = Int.random(in: 0..<100)
        let msg: ChatMessage

        if type < 40 {
            msg = makeTextMessage()
        } else if type < 55 {
            msg = makeImageMessage()
        } else if type < 65 {
            msg = makeVideoMessage()
        } else if type < 75 {
            msg = makeMixedMediaMessage()
        } else if type < 82 {
            msg = makeVoiceMessage()
        } else if type < 90 {
            msg = makeFileMessage()
        } else if type < 95 {
            msg = makeReplyMessage()
        } else {
            msg = makeForwardedMessage()
        }

        allMessages.append(msg)
        chatVC.updateMessages(allMessages)
    }

    // MARK: - Message Generators

    private func makeTextMessage() -> ChatMessage {
        let texts = [
            "Привет! Как дела?", "Ок, понял 👍", "Давай обсудим позже",
            "Сегодня отличная погода ☀️", "Видел новый апдейт?",
            "Кстати, хотел спросить — ты когда заканчиваешь проект? Нужно обсудить пару деталей по интеграции.",
            "🔥🔥🔥", "Ладно", "Сейчас не могу, напишу позже",
            "А что там с дедлайном? Я слышал переносят на следующую неделю.",
            "Ого, круто!", "Не знал об этом, спасибо за инфо",
            "Может завтра созвонимся?", "Скинул файл, посмотри",
        ]
        return makeMessage(text: texts.randomElement()!)
    }

    private func makeImageMessage() -> ChatMessage {
        let id = Int.random(in: 1...200)
        let w: CGFloat = [300, 400, 350].randomElement()!
        let h: CGFloat = [200, 300, 400, 250].randomElement()!
        return makeMessage(
            text: Bool.random() ? "Смотри фото" : nil,
            media: [.image(ImageItem(
                url: "https://picsum.photos/id/\(id)/\(Int(w))/\(Int(h))",
                width: w, height: h,
                thumbnailUrl: "https://picsum.photos/id/\(id)/\(Int(w/2))/\(Int(h/2))"
            ))]
        )
    }

    private func makeVideoMessage() -> ChatMessage {
        let id = Int.random(in: 200...400)
        return makeMessage(media: [
            .video(VideoItem(
                url: "https://example.com/video\(id).mp4",
                thumbnailUrl: "https://picsum.photos/id/\(id)/400/300",
                width: 400, height: 300,
                duration: TimeInterval.random(in: 5...180)
            ))
        ])
    }

    private func makeMixedMediaMessage() -> ChatMessage {
        let count = Int.random(in: 2...5)
        var media: [MediaItem] = []
        for _ in 0..<count {
            let id = Int.random(in: 1...500)
            if Bool.random() {
                media.append(.image(ImageItem(
                    url: "https://picsum.photos/id/\(id)/400/300",
                    width: 400, height: 300,
                    thumbnailUrl: "https://picsum.photos/id/\(id)/200/150"
                )))
            } else {
                media.append(.video(VideoItem(
                    url: "https://example.com/v\(id).mp4",
                    thumbnailUrl: "https://picsum.photos/id/\(id)/400/300",
                    width: 400, height: 300,
                    duration: TimeInterval.random(in: 10...120)
                )))
            }
        }
        return makeMessage(text: Bool.random() ? "Медиа" : nil, media: media)
    }

    private func makeVoiceMessage() -> ChatMessage {
        let dur = TimeInterval.random(in: 2...60)
        let bars = (0..<20).map { _ in Float.random(in: 0.1...1.0) }
        let urls = [
            "https://dl.espressif.com/dl/audio/gs-16b-2c-44100hz.m4a",
            "https://dl.espressif.com/dl/audio/gs-16b-1c-44100hz.m4a",
            "https://dl.espressif.com/dl/audio/ff-16b-1c-44100hz.m4a",
        ]
        return makeMessage(voice: VoicePayload(url: urls.randomElement()!, duration: dur, waveform: bars))
    }

    private func makeFileMessage() -> ChatMessage {
        let files = [
            FilePayload(url: "https://example.com/doc.pdf", name: "Отчёт_Q1.pdf", size: Int64.random(in: 100_000...10_000_000), mimeType: "application/pdf"),
            FilePayload(url: "https://example.com/arch.zip", name: "Архив_проекта.zip", size: Int64.random(in: 1_000_000...50_000_000), mimeType: "application/zip"),
            FilePayload(url: "https://example.com/img.png", name: "screenshot.png", size: Int64.random(in: 50_000...5_000_000), mimeType: "image/png"),
        ]
        let count = Int.random(in: 1...3)
        let selected = Array(files.shuffled().prefix(count))
        return makeMessage(text: Bool.random() ? "Вот файлы" : nil, files: selected)
    }

    private func makeReplyMessage() -> ChatMessage {
        guard let target = allMessages.filter({ !$0.isMine }).randomElement() else { return makeTextMessage() }
        let texts = ["Согласен!", "Не уверен...", "Хороший вопрос", "Точно!", "Нужно подумать"]
        return makeMessage(
            text: texts.randomElement()!,
            reply: ReplyInfo(replyToId: target.id, senderName: target.senderName, text: target.content.text, hasImage: target.content.media != nil)
        )
    }

    private func makeForwardedMessage() -> ChatMessage {
        let texts = [
            "Важная информация от команды — дедлайн перенесён.",
            "Встреча перенесена на 15:00",
            "Новый билд готов к тестированию",
        ]
        return makeMessage(text: texts.randomElement()!, forwardedFrom: users.randomElement()!)
    }

    // MARK: - Helper

    private func makeMessage(
        text: String? = nil,
        media: [MediaItem]? = nil,
        voice: VoicePayload? = nil,
        files: [FilePayload]? = nil,
        reply: ReplyInfo? = nil,
        forwardedFrom: String? = nil
    ) -> ChatMessage {
        let id = "\(nextId)"
        nextId += 1
        let isMine = Int.random(in: 0..<100) < 25
        let sender = isMine ? nil : users.randomElement()!
        let now = Date()
        return ChatMessage(
            id: id,
            content: MessageContent(text: text, media: media, voice: voice, poll: nil, files: files),
            timestamp: now,
            senderName: sender,
            isMine: isMine,
            groupDate: DateHelper.shared.groupKey(from: now),
            status: isMine ? [.sending, .sent, .delivered].randomElement()! : .read,
            reply: reply,
            forwardedFrom: forwardedFrom,
            reactions: [],
            isEdited: false,
            actions: defaultActions
        )
    }

    // MARK: - Random Reactions

    private func addRandomReaction() {
        guard !allMessages.isEmpty else { return }
        let idx = Int.random(in: max(0, allMessages.count - 10)..<allMessages.count)
        let msg = allMessages[idx]
        let emoji = emojis.randomElement()!

        var reactions = msg.reactions
        if let rIdx = reactions.firstIndex(where: { $0.emoji == emoji }) {
            let r = reactions[rIdx]
            reactions[rIdx] = Reaction(emoji: emoji, count: r.count + 1, isMine: r.isMine)
        } else {
            reactions.append(Reaction(emoji: emoji, count: 1, isMine: Bool.random()))
        }

        allMessages[idx] = ChatMessage(
            id: msg.id, content: msg.content, timestamp: msg.timestamp,
            senderName: msg.senderName, isMine: msg.isMine, groupDate: msg.groupDate,
            status: msg.status, reply: msg.reply, forwardedFrom: msg.forwardedFrom,
            reactions: reactions, isEdited: msg.isEdited, actions: msg.actions
        )
        chatVC.updateMessages(allMessages)
    }

    // MARK: - Poll Votes

    private func randomizePollVotes() {
        for i in 0..<allMessages.count {
            guard let poll = allMessages[i].content.poll, !poll.isClosed else { continue }
            var opts: [PollOption] = []
            var total = 0
            for o in poll.options {
                let v = Int.random(in: 0...20)
                opts.append(PollOption(id: o.id, text: o.text, votes: v, percentage: 0))
                total += v
            }
            for j in 0..<opts.count {
                let pct: CGFloat = total > 0 ? CGFloat(opts[j].votes) / CGFloat(total) : 0
                opts[j] = PollOption(id: opts[j].id, text: opts[j].text, votes: opts[j].votes, percentage: pct)
            }
            let selected = opts.filter { _ in Bool.random() }.map(\.id)
            let updated = PollPayload(
                id: poll.id, question: poll.question, options: opts,
                totalVotes: total, selectedOptionIds: selected,
                isMultipleChoice: poll.isMultipleChoice, isClosed: poll.isClosed, isAnonymous: poll.isAnonymous
            )
            let m = allMessages[i]
            allMessages[i] = ChatMessage(
                id: m.id,
                content: MessageContent(text: m.content.text, media: m.content.media, voice: m.content.voice, poll: updated, files: m.content.files),
                timestamp: m.timestamp, senderName: m.senderName, isMine: m.isMine,
                groupDate: m.groupDate, status: m.status, reply: m.reply,
                forwardedFrom: m.forwardedFrom, reactions: m.reactions,
                isEdited: m.isEdited, actions: m.actions
            )
        }
        chatVC.updateMessages(allMessages)
    }

    // MARK: - Status Updates

    private func updateMessageStatus() {
        guard let idx = allMessages.lastIndex(where: { $0.isMine && $0.status != .read }) else { return }
        let msg = allMessages[idx]
        let next: MessageStatus
        switch msg.status {
        case .sending:   next = .sent
        case .sent:      next = .delivered
        case .delivered:  next = .read
        default: return
        }
        allMessages[idx] = ChatMessage(
            id: msg.id, content: msg.content, timestamp: msg.timestamp,
            senderName: msg.senderName, isMine: msg.isMine, groupDate: msg.groupDate,
            status: next, reply: msg.reply, forwardedFrom: msg.forwardedFrom,
            reactions: msg.reactions, isEdited: msg.isEdited, actions: msg.actions
        )
        chatVC.updateMessages(allMessages)
    }

    // MARK: - History Generation

    private func generateHistoryBatch(count: Int, before date: Date) -> [ChatMessage] {
        let cal = Calendar.current
        var msgs: [ChatMessage] = []

        for i in 0..<count {
            let ts = cal.date(byAdding: .minute, value: -(count - i) * 5, to: date)!
            let type = Int.random(in: 0..<100)
            let id = "\(nextId)"
            nextId += 1
            let isMine = Int.random(in: 0..<100) < 30
            let sender = isMine ? nil : users.randomElement()!
            let groupDate = DateHelper.shared.groupKey(from: ts)

            let content: MessageContent
            if type < 50 {
                let texts = [
                    "Старое сообщение", "Ок 👍", "Понял, сделаю",
                    "Тут в общем такая ситуация — нужно переделать модуль авторизации до конца недели.",
                    "🔥", "Согласен", "Посмотрю завтра", "Готово!", "А как же...",
                    "Не забудь про встречу", "Скинь ссылку", "Уже отправил",
                ]
                content = MessageContent(text: texts.randomElement()!, media: nil, voice: nil, poll: nil, files: nil)
            } else if type < 70 {
                let imgId = Int.random(in: 1...500)
                content = MessageContent(text: nil, media: [
                    .image(ImageItem(url: "https://picsum.photos/id/\(imgId)/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/\(imgId)/200/150"))
                ], voice: nil, poll: nil, files: nil)
            } else if type < 80 {
                let dur = TimeInterval.random(in: 3...45)
                let bars = (0..<20).map { _ in Float.random(in: 0.1...1.0) }
                content = MessageContent(text: nil, media: nil, voice: VoicePayload(
                    url: "https://dl.espressif.com/dl/audio/gs-16b-1c-44100hz.m4a", duration: dur, waveform: bars
                ), poll: nil, files: nil)
            } else if type < 90 {
                content = MessageContent(text: nil, media: nil, voice: nil, poll: PollPayload(
                    id: "poll-\(id)", question: "Какой вариант лучше?",
                    options: [
                        PollOption(id: "a", text: "Вариант A", votes: Int.random(in: 1...10), percentage: 0.4),
                        PollOption(id: "b", text: "Вариант B", votes: Int.random(in: 1...10), percentage: 0.35),
                        PollOption(id: "c", text: "Вариант C", votes: Int.random(in: 1...10), percentage: 0.25),
                    ],
                    totalVotes: 15, selectedOptionIds: Bool.random() ? ["a"] : [],
                    isMultipleChoice: false, isClosed: false, isAnonymous: Bool.random()
                ), files: nil)
            } else {
                content = MessageContent(text: "Документ", media: nil, voice: nil, poll: nil, files: [
                    FilePayload(url: "https://example.com/f.pdf", name: "file_\(id).pdf", size: Int64.random(in: 100_000...5_000_000), mimeType: "application/pdf")
                ])
            }

            var reactions: [Reaction] = []
            if Int.random(in: 0..<100) < 20 {
                reactions.append(Reaction(emoji: emojis.randomElement()!, count: Int.random(in: 1...5), isMine: Bool.random()))
            }

            msgs.append(ChatMessage(
                id: id, content: content, timestamp: ts,
                senderName: sender, isMine: isMine, groupDate: groupDate,
                status: isMine ? .read : .read,
                reply: nil, forwardedFrom: nil,
                reactions: reactions, isEdited: Bool.random() && type < 50,
                actions: defaultActions
            ))
        }
        return msgs
    }

    // MARK: - ChatViewControllerDelegate

    func chatDidScroll(offset: CGPoint) {}

    func chatDidReachTop(distance: CGFloat) {
        guard !chatVC.isLoadingTop else { return }
        chatVC.isLoadingTop = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            let oldest = self.allMessages.first?.timestamp ?? Date()
            let older = self.generateHistoryBatch(count: 20, before: oldest)
            self.allMessages.insert(contentsOf: older, at: 0)
            self.chatVC.isLoadingTop = false
            self.chatVC.updateMessages(self.allMessages)
        }
    }

    func chatDidReachBottom(distance: CGFloat) {}

    func chatDidTapFAB() {
        chatVC.clearUnread()
        chatVC.scrollToBottom(animated: true)
    }

    func chatMessagesDidAppear(ids: [String]) {}

    func chatDidTapMessage(id: String, attachmentIndex: Int?) {}

    func chatDidSelectAction(actionId: String, messageId: String) {
        if actionId == "reply", let msg = chatVC.message(forID: messageId) {
            chatVC.beginReply(info: ReplyInfo(
                replyToId: messageId,
                senderName: msg.senderName ?? "Вы",
                text: msg.content.text,
                hasImage: msg.content.media?.isEmpty == false
            ))
        }
    }

    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {
        toggleReaction(emoji: emoji, messageId: messageId)
    }

    func chatDidTapReaction(messageId: String, emoji: String) {
        toggleReaction(emoji: emoji, messageId: messageId)
    }

    private func toggleReaction(emoji: String, messageId: String) {
        guard let idx = allMessages.firstIndex(where: { $0.id == messageId }) else { return }
        let msg = allMessages[idx]
        var reactions = msg.reactions

        if let rIdx = reactions.firstIndex(where: { $0.emoji == emoji }) {
            let r = reactions[rIdx]
            if r.isMine {
                reactions.remove(at: rIdx)
            } else {
                reactions[rIdx] = Reaction(emoji: emoji, count: r.count + 1, isMine: true)
            }
        } else {
            reactions.append(Reaction(emoji: emoji, count: 1, isMine: true))
        }

        allMessages[idx] = ChatMessage(
            id: msg.id, content: msg.content, timestamp: msg.timestamp,
            senderName: msg.senderName, isMine: msg.isMine, groupDate: msg.groupDate,
            status: msg.status, reply: msg.reply, forwardedFrom: msg.forwardedFrom,
            reactions: reactions, isEdited: msg.isEdited, actions: msg.actions
        )
        chatVC.updateMessages(allMessages)
    }

    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }

    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String) {}
    func chatDidTapPollDetail(messageId: String, pollId: String) {}

    func chatDidSendMessage(text: String, replyToId: String?) {
        let now = Date()
        let msg = ChatMessage(
            id: "\(nextId)", content: MessageContent(text: text, media: nil, voice: nil, poll: nil, files: nil),
            timestamp: now, senderName: nil, isMine: true,
            groupDate: DateHelper.shared.groupKey(from: now), status: .sending,
            reply: replyToId.flatMap { id in chatVC.message(forID: id).map {
                ReplyInfo(replyToId: id, senderName: $0.senderName ?? "Вы", text: $0.content.text, hasImage: false)
            }},
            forwardedFrom: nil, reactions: [], isEdited: false, actions: defaultActions
        )
        nextId += 1
        allMessages.append(msg)
        chatVC.updateMessages(allMessages)
    }

    func chatDidEditMessage(text: String, messageId: String) {}
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() {}

    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval) {
        let now = Date()
        let waveform = (0..<20).map { _ in Float.random(in: 0.1...1.0) }
        let msg = ChatMessage(
            id: "\(nextId)",
            content: MessageContent(text: nil, media: nil, voice: VoicePayload(
                url: fileURL.absoluteString, duration: duration, waveform: waveform
            ), poll: nil, files: nil),
            timestamp: now, senderName: nil, isMine: true,
            groupDate: DateHelper.shared.groupKey(from: now), status: .sending,
            reply: nil, forwardedFrom: nil, reactions: [], isEdited: false, actions: []
        )
        nextId += 1
        allMessages.append(msg)
        chatVC.updateMessages(allMessages)
    }

    func chatDidChangeInputText(_ text: String) {}
}

// MARK: - SwiftUI Wrapper

struct LiveChatDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LiveChatDemoViewController {
        LiveChatDemoViewController()
    }
    func updateUIViewController(_ vc: LiveChatDemoViewController, context: Context) {}
}
