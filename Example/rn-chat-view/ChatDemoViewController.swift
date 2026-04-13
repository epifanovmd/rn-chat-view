import IOSChatView
import UIKit
import SwiftUI

// MARK: - Demo Data

enum ChatDemoData {

    static let currentUser = "me"
    static let otherUser = "Alice"
    static let thirdUser = "Bob"

    static func makeSampleMessages() -> [ChatMessage] {
        let cal = Calendar.current
        let now = Date()
        let today = DateHelper.shared.groupKey(from: now)
        let yesterday = DateHelper.shared.groupKey(from: cal.date(byAdding: .day, value: -1, to: now)!)

        return [
            // --- Yesterday ---

            // 1. Plain text (incoming)
            ChatMessage(
                id: "1",
                content: MessageBody(text: "Привет! Как дела?", content: nil),
                timestamp: cal.date(byAdding: .hour, value: -25, to: now)!,
                senderName: otherUser,
                ownership: .theirs,
                groupDate: yesterday,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [Reaction(emoji: "👍", count: 1, isSelected: true)],
                isEdited: false,
                actions: defaultActions
            ),

            // 2. Plain text (outgoing, read)
            ChatMessage(
                id: "2",
                content: MessageBody(text: "Привет, Алиса! Всё отлично, работаю над компонентом чата 🚀", content: nil),
                timestamp: cal.date(byAdding: .hour, value: -24, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: yesterday,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 3. Reply message (incoming)
            ChatMessage(
                id: "3",
                content: MessageBody(text: "Звучит здорово! Можешь показать дизайн?", content: nil),
                timestamp: cal.date(byAdding: .hour, value: -23, to: now)!,
                senderName: otherUser,
                ownership: .theirs,
                groupDate: yesterday,
                status: .read,
                reply: ReplyInfo(replyToId: "2", senderName: "Вы", text: "Привет, Алиса! Всё отлично, работаю над компонентом чата 🚀", hasImage: false),
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 4. Image message (outgoing)
            ChatMessage(
                id: "4",
                content: MessageBody(
                    text: "Вот макет",
                    content: AnyChatContent(ImagesContent([
                        .image(ImageItem(
                            url: "https://picsum.photos/id/1/400/300",
                            width: 400, height: 300,
                            thumbnailUrl: "https://picsum.photos/id/1/200/150"
                        ))
                    ]))
                ),
                timestamp: cal.date(byAdding: .hour, value: -22, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: yesterday,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [
                    Reaction(emoji: "🔥", count: 2, isSelected: false),
                    Reaction(emoji: "❤️", count: 1, isSelected: true)
                ],
                isEdited: false,
                actions: defaultActions
            ),

            // --- Today ---

            // 5a. Single video (incoming)
            ChatMessage(
                id: "5a",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(ImagesContent([
                        .video(VideoItem(url: "https://example.com/video1.mp4", thumbnailUrl: "https://picsum.photos/id/60/400/300", width: 400, height: 300, duration: 45)),
                    ]))
                ),
                timestamp: cal.date(byAdding: .hour, value: -6, to: now)!,
                senderName: otherUser,
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 5b. Two images (outgoing, with text)
            ChatMessage(
                id: "5b",
                content: MessageBody(
                    text: "Смотри какие виды!",
                    content: AnyChatContent(ImagesContent([
                        .image(ImageItem(url: "https://picsum.photos/id/10/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/10/200/150")),
                        .image(ImageItem(url: "https://picsum.photos/id/20/300/400", width: 300, height: 400, thumbnailUrl: "https://picsum.photos/id/20/150/200")),
                    ]))
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!.addingTimeInterval(-2400),
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 5c. Mixed: 2 images + 1 video (incoming)
            ChatMessage(
                id: "5c",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(ImagesContent([
                        .image(ImageItem(url: "https://picsum.photos/id/30/400/400", width: 400, height: 400, thumbnailUrl: "https://picsum.photos/id/30/200/200")),
                        .video(VideoItem(url: "https://example.com/video2.mp4", thumbnailUrl: "https://picsum.photos/id/40/400/300", width: 400, height: 300, duration: 12)),
                        .image(ImageItem(url: "https://picsum.photos/id/50/300/400", width: 300, height: 400, thumbnailUrl: "https://picsum.photos/id/50/150/200")),
                    ]))
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!.addingTimeInterval(-1800),
                senderName: otherUser,
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [Reaction(emoji: "😍", count: 1, isSelected: true)],
                isEdited: false,
                actions: defaultActions
            ),

            // 5d. Four images (outgoing)
            ChatMessage(
                id: "5d",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(ImagesContent([
                        .image(ImageItem(url: "https://picsum.photos/id/100/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/100/200/150")),
                        .image(ImageItem(url: "https://picsum.photos/id/110/300/300", width: 300, height: 300, thumbnailUrl: "https://picsum.photos/id/110/150/150")),
                        .image(ImageItem(url: "https://picsum.photos/id/120/400/250", width: 400, height: 250, thumbnailUrl: "https://picsum.photos/id/120/200/125")),
                        .image(ImageItem(url: "https://picsum.photos/id/130/350/400", width: 350, height: 400, thumbnailUrl: "https://picsum.photos/id/130/175/200")),
                    ]))
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!.addingTimeInterval(-1200),
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .delivered,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 5e. Five+ mixed: 3 images + 2 videos (incoming, with +N overlay)
            ChatMessage(
                id: "5e",
                content: MessageBody(
                    text: "Фото и видео с поездки 🏔",
                    content: AnyChatContent(ImagesContent([
                        .image(ImageItem(url: "https://picsum.photos/id/140/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/140/200/150")),
                        .video(VideoItem(url: "https://example.com/video3.mp4", thumbnailUrl: "https://picsum.photos/id/150/400/300", width: 400, height: 300, duration: 128)),
                        .image(ImageItem(url: "https://picsum.photos/id/160/300/400", width: 300, height: 400, thumbnailUrl: "https://picsum.photos/id/160/150/200")),
                        .image(ImageItem(url: "https://picsum.photos/id/170/400/400", width: 400, height: 400, thumbnailUrl: "https://picsum.photos/id/170/200/200")),
                        .video(VideoItem(url: "https://example.com/video4.mp4", thumbnailUrl: "https://picsum.photos/id/180/400/250", width: 400, height: 250, duration: 67)),
                    ]))
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!.addingTimeInterval(-600),
                senderName: otherUser,
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 6. Voice message (outgoing)
            ChatMessage(
                id: "6",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(VoicePayload(
                        url: "https://dl.espressif.com/dl/audio/gs-16b-2c-44100hz.m4a",
                        duration: 12.5,
                        waveform: [0.1, 0.3, 0.5, 0.8, 1.0, 0.7, 0.4, 0.6, 0.9, 0.5,
                                   0.3, 0.2, 0.4, 0.7, 0.8, 0.6, 0.3, 0.1, 0.2, 0.4]
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -4, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .delivered,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 6b. Voice message (incoming)
            ChatMessage(
                id: "6b",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(VoicePayload(
                        url: "https://dl.espressif.com/dl/audio/gs-16b-1c-44100hz.m4a",
                        duration: 8.0,
                        waveform: [0.2, 0.5, 0.9, 0.7, 0.3, 0.6, 1.0, 0.8, 0.4, 0.2,
                                   0.5, 0.7, 0.3, 0.9, 0.6, 0.4, 0.8, 0.5, 0.3, 0.1]
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-1800),
                senderName: otherUser,
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 6c. Voice message (outgoing, short)
            ChatMessage(
                id: "6c",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(VoicePayload(
                        url: "https://dl.espressif.com/dl/audio/ff-16b-1c-44100hz.m4a",
                        duration: 3.2,
                        waveform: [0.4, 0.8, 1.0, 0.6, 0.3, 0.5, 0.9, 0.7, 0.2, 0.4]
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-1200),
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .delivered,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 6d. Voice message (incoming, long)
            ChatMessage(
                id: "6d",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(VoicePayload(
                        url: "https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.m4a",
                        duration: 47.0,
                        waveform: [0.1, 0.2, 0.4, 0.6, 0.8, 1.0, 0.9, 0.7, 0.5, 0.3,
                                   0.4, 0.6, 0.8, 0.7, 0.5, 0.3, 0.2, 0.4, 0.6, 0.8,
                                   1.0, 0.7, 0.4, 0.2, 0.3, 0.5, 0.7, 0.9, 0.6, 0.3]
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-600),
                senderName: otherUser,
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 7. File message (incoming, multiple files)
            ChatMessage(
                id: "7",
                content: MessageBody(
                    text: "Вот файлы проекта",
                    content: AnyChatContent(FilesContent([
                        FilePayload(url: "https://example.com/report.pdf", name: "Q4_Report_2025.pdf", size: 2_540_000, mimeType: "application/pdf"),
                        FilePayload(url: "https://example.com/design.zip", name: "UI_Design_Assets.zip", size: 15_800_000, mimeType: "application/zip"),
                        FilePayload(url: "https://example.com/track.mp3", name: "notification_sound.mp3", size: 340_000, mimeType: "audio/mpeg"),
                    ]))
                ),
                timestamp: cal.date(byAdding: .hour, value: -3, to: now)!,
                senderName: otherUser,
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 8. Poll message (outgoing, single choice)
            ChatMessage(
                id: "8",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(PollPayload(
                        id: "poll-1",
                        question: "Когда проведём командную встречу?",
                        options: [
                            PollOption(id: "opt-1", text: "Понедельник 10:00", votes: 3, percentage: 0.5),
                            PollOption(id: "opt-2", text: "Вторник 14:00", votes: 2, percentage: 0.33),
                            PollOption(id: "opt-3", text: "Среда 11:00", votes: 1, percentage: 0.17),
                        ],
                        totalVotes: 6,
                        selectedOptionIds: ["opt-1"],
                        isMultipleChoice: false,
                        isClosed: false,
                        isAnonymous: false
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -2, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .delivered,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 8b. Poll message (incoming, multiple choice)
            ChatMessage(
                id: "8b",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(PollPayload(
                        id: "poll-2",
                        question: "Какие технологии используем в новом проекте?",
                        options: [
                            PollOption(id: "tech-1", text: "Swift + UIKit", votes: 5, percentage: 0.36),
                            PollOption(id: "tech-2", text: "SwiftUI", votes: 4, percentage: 0.29),
                            PollOption(id: "tech-3", text: "React Native", votes: 3, percentage: 0.21),
                            PollOption(id: "tech-4", text: "Flutter", votes: 2, percentage: 0.14),
                        ],
                        totalVotes: 14,
                        selectedOptionIds: ["tech-1", "tech-2"],
                        isMultipleChoice: true,
                        isClosed: false,
                        isAnonymous: true
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-1800),
                senderName: otherUser,
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 8c. Closed poll (outgoing)
            ChatMessage(
                id: "8c",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(PollPayload(
                        id: "poll-3",
                        question: "Где проведём корпоратив?",
                        options: [
                            PollOption(id: "loc-1", text: "Ресторан", votes: 8, percentage: 0.53),
                            PollOption(id: "loc-2", text: "Загородный дом", votes: 5, percentage: 0.33),
                            PollOption(id: "loc-3", text: "Боулинг", votes: 2, percentage: 0.14),
                        ],
                        totalVotes: 15,
                        selectedOptionIds: ["loc-1"],
                        isMultipleChoice: false,
                        isClosed: true,
                        isAnonymous: false
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-900),
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 9. Forwarded message (incoming)
            ChatMessage(
                id: "9",
                content: MessageBody(text: "Деплой запланирован на пятницу в 18:00 UTC. Убедитесь, что все PR смержены до конца четверга.", content: nil),
                timestamp: cal.date(byAdding: .hour, value: -1, to: now)!,
                senderName: otherUser,
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: thirdUser,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 10. Edited message (outgoing, sent)
            ChatMessage(
                id: "10",
                content: MessageBody(text: "Понял, закончу свой PR сегодня", content: nil),
                timestamp: cal.date(byAdding: .minute, value: -30, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .sent,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: true,
                actions: defaultActions
            ),

            // 11. Long text message (incoming)
            ChatMessage(
                id: "11",
                content: MessageBody(
                    text: "Кстати, новый API-эндпоинт готов к тестированию. Документация тут: https://confluence.example.com/api/v2/preferences\n\nЕсли будут вопросы — звони +7 (999) 123-45-67",
                    content: nil
                ),
                timestamp: cal.date(byAdding: .minute, value: -10, to: now)!,
                senderName: otherUser,
                senderAvatarUrl: "https://i.pravatar.cc/150?img=5",
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [
                    Reaction(emoji: "👍", count: 3, isSelected: true),
                    Reaction(emoji: "🙌", count: 1, isSelected: false),
                ],
                thread: ThreadInfo(threadId: "thread-1", replyCount: 5),
                isEdited: false,
                actions: defaultActions
            ),

            // 12. Sending message (outgoing, sending status)
            ChatMessage(
                id: "12",
                content: MessageBody(text: "Спасибо, сейчас посмотрю!", content: nil),
                timestamp: now,
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .sending,
                reply: ReplyInfo(replyToId: "11", senderName: otherUser, text: "Кстати, хотела сказать, что новый API-эндпоинт...", hasImage: false),
                forwardedFrom: nil,
                reactions: [],
                thread: ThreadInfo(threadId: "thread-2", replyCount: 12, lastReplierName: "Борис"),
                isEdited: true,
                actions: defaultActions
            ),
        ]
    }

    static let defaultActions: [MessageAction] = [
        MessageAction(id: "reply", title: "Ответить", systemImage: "arrowshape.turn.up.left", isDestructive: false),
        MessageAction(id: "edit", title: "Редактировать", systemImage: "pencil", isDestructive: false),
        MessageAction(id: "copy", title: "Копировать", systemImage: "doc.on.doc", isDestructive: false),
        MessageAction(id: "forward", title: "Переслать", systemImage: "arrowshape.turn.up.right", isDestructive: false),
        MessageAction(id: "delete", title: "Удалить", systemImage: "trash", isDestructive: true),
    ]
}

// MARK: - Demo ViewController

final class ChatDemoViewController: UIViewController, ChatViewControllerDelegate {

    private let chatVC = ChatViewController()
    private var messageCounter = 1000

    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ChatTheme.dark.backgroundColor

        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.showAvatars = true
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥", "🎉", "👎"]

        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        chatVC.didMove(toParent: self)

        view.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            countLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            countLabel.heightAnchor.constraint(equalToConstant: 24),
        ])

        chatVC.hasMore = true
        chatVC.hasNewer = false

        // Phase 1: show empty state (no messages, no loading)
        // Phase 2: after 1s, start "loading"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.chatVC.isLoading = true

            // Phase 3: after 1.5s more, messages arrive
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self else { return }
                self.chatVC.isLoading = false
                self.chatVC.hasNewer = true
                self.updateMessages(ChatDemoData.makeSampleMessages())
            }
        }
    }

    private func updateMessages(_ msgs: [ChatMessage]) {
        chatVC.updateMessages(msgs)
        countLabel.text = "Messages: \(msgs.count)"
    }

    // MARK: - Load Older Messages

    private func loadOlderMessages() {
        let cal = Calendar.current
        var msgs = chatVC.messages
        let batchSize = 1000

        // Determine base date: earlier than the first message
        let baseDate: Date
        if let firstTimestamp = msgs.first?.timestamp {
            baseDate = cal.date(byAdding: .hour, value: -batchSize, to: firstTimestamp)!
        } else {
            baseDate = Date()
        }

        var newBatch: [ChatMessage] = []
        let senders = ["Alice", "Bob", "Charlie", "Diana"]
        let texts = [
            "Привет! Как дела?",
            "Всё отлично, работаю над проектом 🚀",
            "Звучит здорово! Можешь показать?",
            "Да, конечно, скоро скину",
            "Окей, жду!",
            "Кстати, видел новую версию?",
            "Нет ещё, что там нового?",
            "Много улучшений в производительности",
            "Круто, нужно обновиться",
            "Давай созвонимся завтра",
        ]

        for i in 0..<batchSize {
            messageCounter += 1
            let timestamp = cal.date(byAdding: .minute, value: i * 3, to: baseDate)!
            let groupDate = DateHelper.shared.groupKey(from: timestamp)
            let ownership: MessageOwnership = i % 3 == 0 ? .mine : .theirs
            let sender = ownership == .mine ? nil : senders[i % senders.count]

            let msg = ChatMessage(
                id: "gen-\(messageCounter)",
                content: MessageBody(text: texts[i % texts.count], content: nil),
                timestamp: timestamp,
                senderName: sender,
                ownership: ownership,
                groupDate: groupDate,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: ChatDemoData.defaultActions
            )
            newBatch.append(msg)
        }

        msgs = newBatch + msgs
        chatVC.isLoadingTop = false
        updateMessages(msgs)
    }

    private func loadNewerMessages() {
        let cal = Calendar.current
        var msgs = chatVC.messages
        let batchSize = 100

        let baseDate: Date
        if let lastTimestamp = msgs.last?.timestamp {
            baseDate = cal.date(byAdding: .minute, value: 3, to: lastTimestamp)!
        } else {
            baseDate = Date()
        }

        let senders = ["Alice", "Bob", "Charlie", "Diana"]
        let texts = [
            "Новое сообщение снизу!",
            "Ещё одно новое 🎉",
            "Что думаешь?",
            "Отличная идея",
            "Скоро буду",
            "Подожди минутку",
            "Готово!",
            "Проверь пожалуйста",
            "Всё работает",
            "Супер, спасибо!",
        ]

        for i in 0..<batchSize {
            messageCounter += 1
            let timestamp = cal.date(byAdding: .minute, value: i * 3, to: baseDate)!
            let groupDate = DateHelper.shared.groupKey(from: timestamp)
            let ownership: MessageOwnership = i % 3 == 0 ? .mine : .theirs
            let sender = ownership == .mine ? nil : senders[i % senders.count]

            let msg = ChatMessage(
                id: "gen-\(messageCounter)",
                content: MessageBody(text: texts[i % texts.count], content: nil),
                timestamp: timestamp,
                senderName: sender,
                ownership: ownership,
                groupDate: groupDate,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: ChatDemoData.defaultActions
            )
            msgs.append(msg)
        }

        chatVC.isLoadingBottom = false
        updateMessages(msgs)
    }

    private func showAlert(_ title: String, _ message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - ChatViewControllerDelegate

    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachTop(distance: CGFloat) {
        guard !chatVC.isLoadingTop else { return }
        chatVC.isLoadingTop = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.loadOlderMessages()
        }
    }
    func chatDidReachBottom(distance: CGFloat) {
        guard !chatVC.isLoadingBottom else { return }
        chatVC.isLoadingBottom = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.loadNewerMessages()
        }
    }

    func chatDidTapFAB() {
        chatVC.clearUnread()
        chatVC.scrollToBottom(animated: true)
    }

    func chatVisibleMessagesDidChange(ids: [String]) {}
    func chatUnreadMessagesDidAppear(ids: [String]) {}

    func chatDidTapMessage(id: String, attachmentIndex: Int?) {
        if let idx = attachmentIndex {
            showAlert("Tap Message", "id: \(id)\ncontent: \(idx)")
        } else {
            showAlert("Tap Message", "id: \(id)")
        }
    }

    func chatDidSelectAction(actionId: String, messageId: String) {
        guard let msg = chatVC.message(forID: messageId) else { return }

        switch actionId {
        case "reply":
            chatVC.beginReply(info: ReplyInfo(
                replyToId: messageId,
                senderName: msg.senderName ?? "Вы",
                text: msg.content.text,
                hasImage: msg.content.content != nil
            ))
        case "edit":
            chatVC.beginEdit(messageId: messageId, text: msg.content.text ?? "")
        case "delete":
            var msgs = chatVC.messages
            msgs.removeAll { $0.id == messageId }
            updateMessages(msgs)
        default:
            showAlert("Action: \(actionId)", "message: \(messageId)")
        }
    }

    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {
        toggleReaction(emoji: emoji, messageId: messageId)
    }

    func chatDidTapReaction(messageId: String, emoji: String) {
        toggleReaction(emoji: emoji, messageId: messageId)
    }

    private func toggleReaction(emoji: String, messageId: String) {
        var msgs = chatVC.messages
        guard let idx = msgs.firstIndex(where: { $0.id == messageId }) else { return }

        let msg = msgs[idx]
        var reactions = msg.reactions

        if let rIdx = reactions.firstIndex(where: { $0.emoji == emoji }) {
            let existing = reactions[rIdx]
            if existing.isSelected {
                // Remove my reaction
                if existing.count <= 1 {
                    reactions.remove(at: rIdx)
                } else {
                    reactions[rIdx] = Reaction(emoji: emoji, count: existing.count - 1, isSelected: false)
                }
            } else {
                // Add my reaction to existing
                reactions[rIdx] = Reaction(emoji: emoji, count: existing.count + 1, isSelected: true)
            }
        } else {
            // New reaction
            reactions.append(Reaction(emoji: emoji, count: 1, isSelected: true))
        }

        msgs[idx] = ChatMessage(
            id: msg.id,
            content: msg.content,
            timestamp: msg.timestamp,
            senderName: msg.senderName,
            ownership: msg.ownership,
            groupDate: msg.groupDate,
            status: msg.status,
            reply: msg.reply,
            forwardedFrom: msg.forwardedFrom,
            reactions: reactions,
            isEdited: msg.isEdited,
            actions: msg.actions
        )
        updateMessages(msgs)
    }

    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }

    func chatDidTapThread(messageId: String, threadId: String) {
        guard let msg = chatVC.message(forID: messageId) else { return }
        let replies = ThreadDemoStore.replies(for: threadId)
        let threadVC = ThreadDemoViewController(
            rootMessage: msg,
            existingReplies: replies,
            theme: chatVC.theme
        )
        let nav = UINavigationController(rootViewController: threadVC)
        nav.modalPresentationStyle = .pageSheet
        nav.navigationBar.prefersLargeTitles = false
        present(nav, animated: true)
    }

    func chatDidTapLink(url: URL, messageId: String) {
        let alert = UIAlertController(title: "Ссылка", message: url.absoluteString, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Открыть", style: .default) { _ in UIApplication.shared.open(url) })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String) {
        let alert = UIAlertController(title: "Телефон", message: phoneNumber, preferredStyle: .alert)
        if let url = URL(string: "tel:\(phoneNumber)") {
            alert.addAction(UIAlertAction(title: "Позвонить", style: .default) { _ in UIApplication.shared.open(url) })
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
        switch interaction.type {
        case "pollOptionTap":
            if let optionId = interaction.payload["optionId"] as? String {
                togglePollVote(messageId: messageId, optionId: optionId)
            }
        case "pollDetailTap":
            let pollId = interaction.payload["pollId"] as? String ?? "?"
            showAlert("Poll Detail", "poll: \(pollId)")
        default:
            showAlert("Interaction: \(interaction.type)", "message: \(messageId)")
        }
    }

    private func togglePollVote(messageId: String, optionId: String) {
        var msgs = chatVC.messages
        guard let idx = msgs.firstIndex(where: { $0.id == messageId }),
              let poll = msgs[idx].content.content?.content(as: PollPayload.self),
              !poll.isClosed else { return }

        var selectedIds = poll.selectedOptionIds

        if poll.isMultipleChoice {
            if selectedIds.contains(optionId) {
                selectedIds.removeAll { $0 == optionId }
            } else {
                selectedIds.append(optionId)
            }
        } else {
            if selectedIds.contains(optionId) {
                selectedIds.removeAll()
            } else {
                selectedIds = [optionId]
            }
        }

        let updatedPoll = recalculatePoll(poll, selectedIds: selectedIds)
        let msg = msgs[idx]
        msgs[idx] = ChatMessage(
            id: msg.id,
            content: MessageBody(text: msg.content.text, content: AnyChatContent(updatedPoll)),
            timestamp: msg.timestamp, senderName: msg.senderName, ownership: msg.ownership,
            groupDate: msg.groupDate, status: msg.status, reply: msg.reply,
            forwardedFrom: msg.forwardedFrom, reactions: msg.reactions,
            isEdited: msg.isEdited, actions: msg.actions
        )
        updateMessages(msgs)
    }

    private func recalculatePoll(_ poll: PollPayload, selectedIds: [String]) -> PollPayload {
        // Simulate: toggle changes vote count by 1
        var options = poll.options
        var totalVotes = 0

        for i in 0..<options.count {
            let opt = options[i]
            let wasSelected = poll.selectedOptionIds.contains(opt.id)
            let isNowSelected = selectedIds.contains(opt.id)
            var votes = opt.votes

            if !wasSelected && isNowSelected { votes += 1 }
            if wasSelected && !isNowSelected { votes = max(0, votes - 1) }

            options[i] = PollOption(id: opt.id, text: opt.text, votes: votes, percentage: 0)
            totalVotes += votes
        }

        // Recalculate percentages
        for i in 0..<options.count {
            let pct: CGFloat = totalVotes > 0 ? CGFloat(options[i].votes) / CGFloat(totalVotes) : 0
            options[i] = PollOption(id: options[i].id, text: options[i].text, votes: options[i].votes, percentage: pct)
        }

        return PollPayload(
            id: poll.id, question: poll.question, options: options,
            totalVotes: totalVotes, selectedOptionIds: selectedIds,
            isMultipleChoice: poll.isMultipleChoice, isClosed: poll.isClosed, isAnonymous: poll.isAnonymous
        )
    }

    func chatDidSendMessage(text: String, replyToId: String?) {
        print("[Demo] Send: \"\(text)\", reply to: \(replyToId ?? "none")")

        // Append the new message to the list
        var msgs = chatVC.messages
        let today = DateHelper.shared.groupKey(from: Date())
        let newMsg = ChatMessage(
            id: UUID().uuidString,
            content: MessageBody(text: text, content: nil),
            timestamp: Date(),
            senderName: nil,
            ownership: .mine,
            groupDate: today,
            status: .sending,
            reply: replyToId.flatMap { id in
                chatVC.message(forID: id).map {
                    ReplyInfo(replyToId: id, senderName: $0.senderName ?? "You", text: $0.content.text, hasImage: false)
                }
            },
            forwardedFrom: nil,
            reactions: [],
            isEdited: false,
            actions: []
        )
        msgs.append(newMsg)
        updateMessages(msgs)
    }

    func chatDidEditMessage(text: String, messageId: String) {
        var msgs = chatVC.messages
        guard let idx = msgs.firstIndex(where: { $0.id == messageId }) else { return }
        let msg = msgs[idx]
        msgs[idx] = ChatMessage(
            id: msg.id,
            content: MessageBody(text: text, content: msg.content.content),
            timestamp: msg.timestamp,
            senderName: msg.senderName,
            ownership: msg.ownership,
            groupDate: msg.groupDate,
            status: msg.status,
            reply: msg.reply,
            forwardedFrom: msg.forwardedFrom,
            reactions: msg.reactions,
            isEdited: true,
            actions: msg.actions
        )
        updateMessages(msgs)
    }

    func chatDidCancelInputAction(type: String) {
        showAlert("Cancel", "type: \(type)")
    }

    func chatDidTapAttachment() {
        showAlert("Attachment", "Tap attachment button")
    }

    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {
        var msgs = chatVC.messages
        let today = DateHelper.shared.groupKey(from: Date())

        let voiceMsg = ChatMessage(
            id: UUID().uuidString,
            content: MessageBody(
                text: nil,
                content: AnyChatContent(VoicePayload(
                    url: fileURL.absoluteString,
                    duration: duration,
                    waveform: waveform
                ))
            ),
            timestamp: Date(),
            senderName: nil,
            ownership: .mine,
            groupDate: today,
            status: .sending,
            reply: nil,
            forwardedFrom: nil,
            reactions: [],
            isEdited: false,
            actions: []
        )
        msgs.append(voiceMsg)
        updateMessages(msgs)
    }

    func chatDidChangeInputText(_ text: String) {}
}

// MARK: - SwiftUI Wrapper

struct ChatDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ChatDemoViewController {
        ChatDemoViewController()
    }

    func updateUIViewController(_ uiViewController: ChatDemoViewController, context: Context) {}
}
