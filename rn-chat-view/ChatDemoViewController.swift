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
                content: MessageContent(text: "Привет! Как дела?", media: nil, voice: nil, poll: nil, files: nil),
                timestamp: cal.date(byAdding: .hour, value: -25, to: now)!,
                senderName: otherUser,
                isMine: false,
                groupDate: yesterday,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [Reaction(emoji: "👍", count: 1, isMine: true)],
                isEdited: false,
                actions: defaultActions
            ),

            // 2. Plain text (outgoing, read)
            ChatMessage(
                id: "2",
                content: MessageContent(text: "Привет, Алиса! Всё отлично, работаю над компонентом чата 🚀", media: nil, voice: nil, poll: nil, files: nil),
                timestamp: cal.date(byAdding: .hour, value: -24, to: now)!,
                senderName: nil,
                isMine: true,
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
                content: MessageContent(text: "Звучит здорово! Можешь показать дизайн?", media: nil, voice: nil, poll: nil, files: nil),
                timestamp: cal.date(byAdding: .hour, value: -23, to: now)!,
                senderName: otherUser,
                isMine: false,
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
                content: MessageContent(
                    text: "Вот макет",
                    media: [
                        .image(ImageItem(
                            url: "https://picsum.photos/id/1/400/300",
                            width: 400, height: 300,
                            thumbnailUrl: "https://picsum.photos/id/1/200/150"
                        ))
                    ],
                    voice: nil, poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -22, to: now)!,
                senderName: nil,
                isMine: true,
                groupDate: yesterday,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [
                    Reaction(emoji: "🔥", count: 2, isMine: false),
                    Reaction(emoji: "❤️", count: 1, isMine: true)
                ],
                isEdited: false,
                actions: defaultActions
            ),

            // --- Today ---

            // 5a. Single video (incoming)
            ChatMessage(
                id: "5a",
                content: MessageContent(
                    text: nil,
                    media: [
                        .video(VideoItem(url: "https://example.com/video1.mp4", thumbnailUrl: "https://picsum.photos/id/60/400/300", width: 400, height: 300, duration: 45)),
                    ],
                    voice: nil, poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -6, to: now)!,
                senderName: otherUser,
                isMine: false,
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
                content: MessageContent(
                    text: "Смотри какие виды!",
                    media: [
                        .image(ImageItem(url: "https://picsum.photos/id/10/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/10/200/150")),
                        .image(ImageItem(url: "https://picsum.photos/id/20/300/400", width: 300, height: 400, thumbnailUrl: "https://picsum.photos/id/20/150/200")),
                    ],
                    voice: nil, poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!.addingTimeInterval(-2400),
                senderName: nil,
                isMine: true,
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
                content: MessageContent(
                    text: nil,
                    media: [
                        .image(ImageItem(url: "https://picsum.photos/id/30/400/400", width: 400, height: 400, thumbnailUrl: "https://picsum.photos/id/30/200/200")),
                        .video(VideoItem(url: "https://example.com/video2.mp4", thumbnailUrl: "https://picsum.photos/id/40/400/300", width: 400, height: 300, duration: 12)),
                        .image(ImageItem(url: "https://picsum.photos/id/50/300/400", width: 300, height: 400, thumbnailUrl: "https://picsum.photos/id/50/150/200")),
                    ],
                    voice: nil, poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!.addingTimeInterval(-1800),
                senderName: otherUser,
                isMine: false,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [Reaction(emoji: "😍", count: 1, isMine: true)],
                isEdited: false,
                actions: defaultActions
            ),

            // 5d. Four images (outgoing)
            ChatMessage(
                id: "5d",
                content: MessageContent(
                    text: nil,
                    media: [
                        .image(ImageItem(url: "https://picsum.photos/id/100/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/100/200/150")),
                        .image(ImageItem(url: "https://picsum.photos/id/110/300/300", width: 300, height: 300, thumbnailUrl: "https://picsum.photos/id/110/150/150")),
                        .image(ImageItem(url: "https://picsum.photos/id/120/400/250", width: 400, height: 250, thumbnailUrl: "https://picsum.photos/id/120/200/125")),
                        .image(ImageItem(url: "https://picsum.photos/id/130/350/400", width: 350, height: 400, thumbnailUrl: "https://picsum.photos/id/130/175/200")),
                    ],
                    voice: nil, poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!.addingTimeInterval(-1200),
                senderName: nil,
                isMine: true,
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
                content: MessageContent(
                    text: "Фото и видео с поездки 🏔",
                    media: [
                        .image(ImageItem(url: "https://picsum.photos/id/140/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/140/200/150")),
                        .video(VideoItem(url: "https://example.com/video3.mp4", thumbnailUrl: "https://picsum.photos/id/150/400/300", width: 400, height: 300, duration: 128)),
                        .image(ImageItem(url: "https://picsum.photos/id/160/300/400", width: 300, height: 400, thumbnailUrl: "https://picsum.photos/id/160/150/200")),
                        .image(ImageItem(url: "https://picsum.photos/id/170/400/400", width: 400, height: 400, thumbnailUrl: "https://picsum.photos/id/170/200/200")),
                        .video(VideoItem(url: "https://example.com/video4.mp4", thumbnailUrl: "https://picsum.photos/id/180/400/250", width: 400, height: 250, duration: 67)),
                    ],
                    voice: nil, poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!.addingTimeInterval(-600),
                senderName: otherUser,
                isMine: false,
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
                content: MessageContent(
                    text: nil, media: nil,
                    voice: VoicePayload(
                        url: "https://dl.espressif.com/dl/audio/gs-16b-2c-44100hz.m4a",
                        duration: 12.5,
                        waveform: [0.1, 0.3, 0.5, 0.8, 1.0, 0.7, 0.4, 0.6, 0.9, 0.5,
                                   0.3, 0.2, 0.4, 0.7, 0.8, 0.6, 0.3, 0.1, 0.2, 0.4]
                    ),
                    poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -4, to: now)!,
                senderName: nil,
                isMine: true,
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
                content: MessageContent(
                    text: nil, media: nil,
                    voice: VoicePayload(
                        url: "https://dl.espressif.com/dl/audio/gs-16b-1c-44100hz.m4a",
                        duration: 8.0,
                        waveform: [0.2, 0.5, 0.9, 0.7, 0.3, 0.6, 1.0, 0.8, 0.4, 0.2,
                                   0.5, 0.7, 0.3, 0.9, 0.6, 0.4, 0.8, 0.5, 0.3, 0.1]
                    ),
                    poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-1800),
                senderName: otherUser,
                isMine: false,
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
                content: MessageContent(
                    text: nil, media: nil,
                    voice: VoicePayload(
                        url: "https://dl.espressif.com/dl/audio/ff-16b-1c-44100hz.m4a",
                        duration: 3.2,
                        waveform: [0.4, 0.8, 1.0, 0.6, 0.3, 0.5, 0.9, 0.7, 0.2, 0.4]
                    ),
                    poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-1200),
                senderName: nil,
                isMine: true,
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
                content: MessageContent(
                    text: nil, media: nil,
                    voice: VoicePayload(
                        url: "https://dl.espressif.com/dl/audio/ff-16b-2c-44100hz.m4a",
                        duration: 47.0,
                        waveform: [0.1, 0.2, 0.4, 0.6, 0.8, 1.0, 0.9, 0.7, 0.5, 0.3,
                                   0.4, 0.6, 0.8, 0.7, 0.5, 0.3, 0.2, 0.4, 0.6, 0.8,
                                   1.0, 0.7, 0.4, 0.2, 0.3, 0.5, 0.7, 0.9, 0.6, 0.3]
                    ),
                    poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-600),
                senderName: otherUser,
                isMine: false,
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
                content: MessageContent(
                    text: "Вот файлы проекта",
                    media: nil, voice: nil, poll: nil,
                    files: [
                        FilePayload(url: "https://example.com/report.pdf", name: "Q4_Report_2025.pdf", size: 2_540_000, mimeType: "application/pdf"),
                        FilePayload(url: "https://example.com/design.zip", name: "UI_Design_Assets.zip", size: 15_800_000, mimeType: "application/zip"),
                        FilePayload(url: "https://example.com/track.mp3", name: "notification_sound.mp3", size: 340_000, mimeType: "audio/mpeg"),
                    ]
                ),
                timestamp: cal.date(byAdding: .hour, value: -3, to: now)!,
                senderName: otherUser,
                isMine: false,
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
                content: MessageContent(
                    text: nil, media: nil, voice: nil,
                    poll: PollPayload(
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
                    ),
                    files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -2, to: now)!,
                senderName: nil,
                isMine: true,
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
                content: MessageContent(
                    text: nil, media: nil, voice: nil,
                    poll: PollPayload(
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
                    ),
                    files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-1800),
                senderName: otherUser,
                isMine: false,
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
                content: MessageContent(
                    text: nil, media: nil, voice: nil,
                    poll: PollPayload(
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
                    ),
                    files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-900),
                senderName: nil,
                isMine: true,
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
                content: MessageContent(text: "Деплой запланирован на пятницу в 18:00 UTC. Убедитесь, что все PR смержены до конца четверга.", media: nil, voice: nil, poll: nil, files: nil),
                timestamp: cal.date(byAdding: .hour, value: -1, to: now)!,
                senderName: otherUser,
                isMine: false,
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
                content: MessageContent(text: "Понял, закончу свой PR сегодня", media: nil, voice: nil, poll: nil, files: nil),
                timestamp: cal.date(byAdding: .minute, value: -30, to: now)!,
                senderName: nil,
                isMine: true,
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
                content: MessageContent(
                    text: "Кстати, хотела сказать, что новый API-эндпоинт для пользовательских настроек готов к тестированию. Документация обновлена в Confluence. Swagger-спеки по адресу /api/v2/preferences. Напиши, если будут вопросы!",
                    media: nil, voice: nil, poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .minute, value: -10, to: now)!,
                senderName: otherUser,
                isMine: false,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [
                    Reaction(emoji: "👍", count: 3, isMine: true),
                    Reaction(emoji: "🙌", count: 1, isMine: false),
                ],
                isEdited: false,
                actions: defaultActions
            ),

            // 12. Sending message (outgoing, sending status)
            ChatMessage(
                id: "12",
                content: MessageContent(text: "Спасибо, сейчас посмотрю!", media: nil, voice: nil, poll: nil, files: nil),
                timestamp: now,
                senderName: nil,
                isMine: true,
                groupDate: today,
                status: .sending,
                reply: ReplyInfo(replyToId: "11", senderName: otherUser, text: "Кстати, хотела сказать, что новый API-эндпоинт...", hasImage: false),
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),
        ]
    }

    private static let defaultActions: [MessageAction] = [
        MessageAction(id: "reply", title: "Ответить", systemImage: "arrowshape.turn.up.left", isDestructive: false),
        MessageAction(id: "copy", title: "Копировать", systemImage: "doc.on.doc", isDestructive: false),
        MessageAction(id: "forward", title: "Переслать", systemImage: "arrowshape.turn.up.right", isDestructive: false),
        MessageAction(id: "delete", title: "Удалить", systemImage: "trash", isDestructive: true),
    ]
}

// MARK: - Debug Panel

private final class DebugPanelView: UIView {

    var onThemeChanged: ((ChatTheme) -> Void)?
    var onSenderNameChanged: ((Bool) -> Void)?
    var onRandomizePolls: (() -> Void)?

    private let themeToggle: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Light", "Dark"])
        control.selectedSegmentIndex = 1
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private let senderNameToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = true
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()

    private let senderNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Sender name"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Debug"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let randomizePollsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🎲 Polls", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        backgroundColor = .systemBackground

        addSubview(titleLabel)
        addSubview(themeToggle)
        addSubview(senderNameLabel)
        addSubview(senderNameToggle)
        addSubview(randomizePollsButton)
        addSubview(separator)

        themeToggle.addTarget(self, action: #selector(themeToggleChanged), for: .valueChanged)
        senderNameToggle.addTarget(self, action: #selector(senderNameToggleChanged), for: .valueChanged)
        randomizePollsButton.addTarget(self, action: #selector(randomizePollsTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),

            themeToggle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            themeToggle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            senderNameLabel.leadingAnchor.constraint(equalTo: themeToggle.trailingAnchor, constant: 16),
            senderNameLabel.centerYAnchor.constraint(equalTo: themeToggle.centerYAnchor),

            senderNameToggle.leadingAnchor.constraint(equalTo: senderNameLabel.trailingAnchor, constant: 8),
            senderNameToggle.centerYAnchor.constraint(equalTo: themeToggle.centerYAnchor),

            randomizePollsButton.leadingAnchor.constraint(equalTo: senderNameToggle.trailingAnchor, constant: 12),
            randomizePollsButton.centerYAnchor.constraint(equalTo: themeToggle.centerYAnchor),

            themeToggle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        ])
    }

    @objc private func themeToggleChanged() {
        let theme: ChatTheme = themeToggle.selectedSegmentIndex == 0 ? .light : .dark
        onThemeChanged?(theme)
    }

    @objc private func senderNameToggleChanged() {
        onSenderNameChanged?(senderNameToggle.isOn)
    }

    @objc private func randomizePollsTapped() {
        onRandomizePolls?()
    }
}

// MARK: - Demo ViewController

final class ChatDemoViewController: UIViewController, ChatViewControllerDelegate {

    private let chatVC = ChatViewController()
    private let debugPanel = DebugPanelView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ChatTheme.dark.backgroundColor

        setupDebugPanel()

        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.showsSenderName = true
        chatVC.emojiReactionsList = ["👍", "❤️", "😂", "😮", "😢", "🔥", "🎉", "👎"]

        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: debugPanel.bottomAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        chatVC.didMove(toParent: self)

        chatVC.updateMessages(ChatDemoData.makeSampleMessages())
    }

    private func setupDebugPanel() {
        debugPanel.translatesAutoresizingMaskIntoConstraints = false
        debugPanel.backgroundColor = .black
        view.addSubview(debugPanel)

        NSLayoutConstraint.activate([
            debugPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            debugPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            debugPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        debugPanel.onThemeChanged = { [weak self] theme in
            guard let self else { return }
            self.chatVC.theme = theme
            self.view.backgroundColor = theme.backgroundColor
            self.debugPanel.backgroundColor = theme.isDark ? .black : .systemBackground
        }

        debugPanel.onSenderNameChanged = { [weak self] show in
            guard let self else { return }
            self.chatVC.showsSenderName = show
        }

        debugPanel.onRandomizePolls = { [weak self] in
            self?.randomizePolls()
        }
    }

    // MARK: - Alert Helper

    private func showAlert(_ title: String, _ message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - ChatViewControllerDelegate

    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachTop(distance: CGFloat) { showAlert("Reached Top", "distance: \(Int(distance))") }
    func chatDidReachBottom(distance: CGFloat) {}

    func chatDidTapFAB() {
        chatVC.clearUnread()
        chatVC.scrollToBottom(animated: true)
    }

    func chatMessagesDidAppear(ids: [String]) {}

    func chatDidTapMessage(id: String, attachmentIndex: Int?) {
        if let idx = attachmentIndex {
            showAlert("Tap Message", "id: \(id)\nattachment: \(idx)")
        } else {
            showAlert("Tap Message", "id: \(id)")
        }
    }

    func chatDidSelectAction(actionId: String, messageId: String) {
        if actionId == "reply", let msg = chatVC.message(forID: messageId) {
            chatVC.beginReply(info: ReplyInfo(
                replyToId: messageId,
                senderName: msg.senderName ?? "Вы",
                text: msg.content.text,
                hasImage: msg.content.media?.isEmpty == false
            ))
            return
        }
        showAlert("Action: \(actionId)", "message: \(messageId)")
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
            if existing.isMine {
                // Remove my reaction
                if existing.count <= 1 {
                    reactions.remove(at: rIdx)
                } else {
                    reactions[rIdx] = Reaction(emoji: emoji, count: existing.count - 1, isMine: false)
                }
            } else {
                // Add my reaction to existing
                reactions[rIdx] = Reaction(emoji: emoji, count: existing.count + 1, isMine: true)
            }
        } else {
            // New reaction
            reactions.append(Reaction(emoji: emoji, count: 1, isMine: true))
        }

        msgs[idx] = ChatMessage(
            id: msg.id,
            content: msg.content,
            timestamp: msg.timestamp,
            senderName: msg.senderName,
            isMine: msg.isMine,
            groupDate: msg.groupDate,
            status: msg.status,
            reply: msg.reply,
            forwardedFrom: msg.forwardedFrom,
            reactions: reactions,
            isEdited: msg.isEdited,
            actions: msg.actions
        )
        chatVC.updateMessages(msgs)
    }

    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }

    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String) {
        togglePollVote(messageId: messageId, optionId: optionId)
    }

    func chatDidTapPollDetail(messageId: String, pollId: String) {
        showAlert("Poll Detail", "poll: \(pollId)")
    }

    private func togglePollVote(messageId: String, optionId: String) {
        var msgs = chatVC.messages
        guard let idx = msgs.firstIndex(where: { $0.id == messageId }),
              let poll = msgs[idx].content.poll,
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
            content: MessageContent(text: msg.content.text, media: msg.content.media, voice: msg.content.voice, poll: updatedPoll, files: msg.content.files),
            timestamp: msg.timestamp, senderName: msg.senderName, isMine: msg.isMine,
            groupDate: msg.groupDate, status: msg.status, reply: msg.reply,
            forwardedFrom: msg.forwardedFrom, reactions: msg.reactions,
            isEdited: msg.isEdited, actions: msg.actions
        )
        chatVC.updateMessages(msgs)
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

    private func randomizePolls() {
        var msgs = chatVC.messages
        for i in 0..<msgs.count {
            guard let poll = msgs[i].content.poll, !poll.isClosed else { continue }

            var options: [PollOption] = []
            var totalVotes = 0
            for opt in poll.options {
                let votes = Int.random(in: 0...20)
                options.append(PollOption(id: opt.id, text: opt.text, votes: votes, percentage: 0))
                totalVotes += votes
            }
            for j in 0..<options.count {
                let pct: CGFloat = totalVotes > 0 ? CGFloat(options[j].votes) / CGFloat(totalVotes) : 0
                options[j] = PollOption(id: options[j].id, text: options[j].text, votes: options[j].votes, percentage: pct)
            }

            let randomSelected = options.filter { _ in Bool.random() }.map(\.id)
            let updated = PollPayload(
                id: poll.id, question: poll.question, options: options,
                totalVotes: totalVotes, selectedOptionIds: randomSelected,
                isMultipleChoice: poll.isMultipleChoice, isClosed: poll.isClosed, isAnonymous: poll.isAnonymous
            )

            let msg = msgs[i]
            msgs[i] = ChatMessage(
                id: msg.id,
                content: MessageContent(text: msg.content.text, media: msg.content.media, voice: msg.content.voice, poll: updated, files: msg.content.files),
                timestamp: msg.timestamp, senderName: msg.senderName, isMine: msg.isMine,
                groupDate: msg.groupDate, status: msg.status, reply: msg.reply,
                forwardedFrom: msg.forwardedFrom, reactions: msg.reactions,
                isEdited: msg.isEdited, actions: msg.actions
            )
        }
        chatVC.updateMessages(msgs)
    }

    func chatDidSendMessage(text: String, replyToId: String?) {
        print("[Demo] Send: \"\(text)\", reply to: \(replyToId ?? "none")")

        // Append the new message to the list
        var msgs = chatVC.messages
        let today = DateHelper.shared.groupKey(from: Date())
        let newMsg = ChatMessage(
            id: UUID().uuidString,
            content: MessageContent(text: text, media: nil, voice: nil, poll: nil, files: nil),
            timestamp: Date(),
            senderName: nil,
            isMine: true,
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
        chatVC.updateMessages(msgs)
    }

    func chatDidEditMessage(text: String, messageId: String) {
        showAlert("Edit Message", "id: \(messageId)\ntext: \(text)")
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
            content: MessageContent(
                text: nil, media: nil,
                voice: VoicePayload(
                    url: fileURL.absoluteString,
                    duration: duration,
                    waveform: waveform
                ),
                poll: nil, files: nil
            ),
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
        msgs.append(voiceMsg)
        chatVC.updateMessages(msgs)
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
