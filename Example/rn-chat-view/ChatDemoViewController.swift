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
                content: MessageBody(text: "Привет, Алиса! Всё отлично, работаю над компонентом чата 🚀", content: nil),
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
                content: MessageBody(text: "Звучит здорово! Можешь показать дизайн?", content: nil),
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
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(ImagesContent([
                        .video(VideoItem(url: "https://example.com/video1.mp4", thumbnailUrl: "https://picsum.photos/id/60/400/300", width: 400, height: 300, duration: 45)),
                    ]))
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
                content: MessageBody(
                    text: "Смотри какие виды!",
                    content: AnyChatContent(ImagesContent([
                        .image(ImageItem(url: "https://picsum.photos/id/10/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/10/200/150")),
                        .image(ImageItem(url: "https://picsum.photos/id/20/300/400", width: 300, height: 400, thumbnailUrl: "https://picsum.photos/id/20/150/200")),
                    ]))
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
                content: MessageBody(text: "Деплой запланирован на пятницу в 18:00 UTC. Убедитесь, что все PR смержены до конца четверга.", content: nil),
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
                content: MessageBody(text: "Понял, закончу свой PR сегодня", content: nil),
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
                content: MessageBody(
                    text: "Кстати, хотела сказать, что новый API-эндпоинт для пользовательских настроек готов к тестированию. Документация обновлена в Confluence. Swagger-спеки по адресу /api/v2/preferences. Напиши, если будут вопросы!",
                    content: nil
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
                content: MessageBody(text: "Спасибо, сейчас посмотрю!", content: nil),
                timestamp: now,
                senderName: nil,
                isMine: true,
                groupDate: today,
                status: .sending,
                reply: ReplyInfo(replyToId: "11", senderName: otherUser, text: "Кстати, хотела сказать, что новый API-эндпоинт...", hasImage: false),
                forwardedFrom: nil,
                reactions: [],
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

// MARK: - Debug Panel

private final class DebugPanelView: UIView {

    var onToggleChanged: ((String, Bool) -> Void)?
    var onThemeChanged: ((ChatTheme) -> Void)?
    var onRandomizePolls: (() -> Void)?
    var onShuffleMessages: (() -> Void)?
    var onClearData: (() -> Void)?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        backgroundColor = .systemBackground

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .bottom
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 6),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -6),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -12),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            heightAnchor.constraint(equalToConstant: 70),
        ])

        // Theme
        let themeItem = makeSegmentItem(title: "Theme", items: ["Light", "Dark"], selected: 1) { [weak self] index in
            self?.onThemeChanged?(index == 0 ? .light : .dark)
        }
        stackView.addArrangedSubview(themeItem)

        // Toggles
        let toggles: [(String, String, Bool)] = [
            ("Sender", "senderName", true),
            ("Status", "status", true),
            ("Time", "time", true),
            ("Edited", "edited", true),
            ("Reactions", "reactions", true),
            ("Reply", "reply", true),
            ("Forwarded", "forwarded", true),
            ("FAB", "fab", true),
            ("Float Date", "floatDate", true),
            ("Date Sep", "dateSep", true),
            ("Empty", "empty", true),
            ("Input", "inputBar", true),
            ("Attach", "attach", true),
            ("Voice", "voice", true),
            ("Ctx Menu", "ctxMenu", true),
        ]

        for (label, key, defaultOn) in toggles {
            let item = makeToggleItem(title: label, key: key, isOn: defaultOn)
            stackView.addArrangedSubview(item)
        }

        // Polls button
        let pollsItem = makeButtonItem(title: "Polls", icon: "🎲") { [weak self] in
            self?.onRandomizePolls?()
        }
        stackView.addArrangedSubview(pollsItem)

        // Shuffle button
        let shuffleItem = makeButtonItem(title: "Shuffle", icon: "🔀") { [weak self] in
            self?.onShuffleMessages?()
        }
        stackView.addArrangedSubview(shuffleItem)

        // Clear data button
        let clearItem = makeButtonItem(title: "Clear", icon: "🗑") { [weak self] in
            self?.onClearData?()
        }
        stackView.addArrangedSubview(clearItem)
    }

    // MARK: - Factory

    private func makeToggleItem(title: String, key: String, isOn: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.accessibilityIdentifier = key
        toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
        container.addSubview(toggle)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            toggle.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
            toggle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            toggle.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
        ])

        return container
    }

    private func makeSegmentItem(title: String, items: [String], selected: Int, onChange: @escaping (Int) -> Void) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let segment = UISegmentedControl(items: items)
        segment.selectedSegmentIndex = selected
        segment.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 11)], for: .normal)
        segment.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(segment)

        let handler = SegmentHandler(onChange: onChange)
        segment.addTarget(handler, action: #selector(SegmentHandler.changed(_:)), for: .valueChanged)
        objc_setAssociatedObject(segment, "handler", handler, .OBJC_ASSOCIATION_RETAIN)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            segment.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            segment.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            segment.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            segment.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    private func makeButtonItem(title: String, icon: String, action: @escaping () -> Void) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let button = UIButton(type: .system)
        button.setTitle(icon, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)

        let handler = ButtonHandler(action: action)
        button.addTarget(handler, action: #selector(ButtonHandler.tapped), for: .touchUpInside)
        objc_setAssociatedObject(button, "handler", handler, .OBJC_ASSOCIATION_RETAIN)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
        ])

        return container
    }

    // MARK: - Actions

    @objc private func toggleChanged(_ sender: UISwitch) {
        guard let key = sender.accessibilityIdentifier else { return }
        onToggleChanged?(key, sender.isOn)
    }
}

// MARK: - Debug Scroll Panel (Layout / Theme toggles)

private final class DebugScrollPanel: UIView {

    var onChanged: ((String, Int) -> Void)?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .bottom
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -4),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor, constant: -8),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    func addToggle(label title: String, key: String, titleA: String, titleB: String) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 9, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        let segment = UISegmentedControl(items: [titleA, titleB])
        segment.selectedSegmentIndex = 0
        segment.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 9)], for: .normal)
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.accessibilityIdentifier = key
        segment.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        container.addSubview(segment)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            segment.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
            segment.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            segment.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            segment.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        stackView.addArrangedSubview(container)
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        guard let key = sender.accessibilityIdentifier else { return }
        onChanged?(key, sender.selectedSegmentIndex)
    }
}

// MARK: - Action Handlers

private final class SegmentHandler: NSObject {
    let onChange: (Int) -> Void
    init(onChange: @escaping (Int) -> Void) { self.onChange = onChange }
    @objc func changed(_ sender: UISegmentedControl) { onChange(sender.selectedSegmentIndex) }
}

private final class ButtonHandler: NSObject {
    let action: () -> Void
    init(action: @escaping () -> Void) { self.action = action }
    @objc func tapped() { action() }
}

// MARK: - Demo ViewController

final class ChatDemoViewController: UIViewController, ChatViewControllerDelegate {

    private let chatVC = ChatViewController()
    private let debugPanel = DebugPanelView()
    private let layoutPanel = DebugScrollPanel()
    private let themePanel = DebugScrollPanel()
    private var messageCounter = 1000

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ChatTheme.dark.backgroundColor

        setupDebugPanel()

        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥", "🎉", "👎"]

        setupLayoutPanel()
        setupThemePanel()

        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: themePanel.bottomAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        chatVC.didMove(toParent: self)

        chatVC.hasMore = true
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

        debugPanel.onToggleChanged = { [weak self] key, isOn in
            guard let self else { return }
            switch key {
            case "senderName": self.chatVC.features.senderNameMode = isOn ? .incomingOnly : .never
            case "status":     self.chatVC.features.showMessageStatus = isOn
            case "time":       self.chatVC.features.showTimestamp = isOn
            case "edited":     self.chatVC.features.showEditedMark = isOn
            case "reactions":  self.chatVC.features.showReactions = isOn
            case "reply":      self.chatVC.features.showReplyPreview = isOn
            case "forwarded":  self.chatVC.features.showForwardedMark = isOn
            case "fab":        self.chatVC.features.showFab = isOn
            case "floatDate":  self.chatVC.features.showFloatingDate = isOn
            case "dateSep":    self.chatVC.features.showDateSeparators = isOn
            case "empty":      self.chatVC.features.showEmptyState = isOn
            case "inputBar":   self.chatVC.features.showInputBar = isOn
            case "attach":     self.chatVC.features.showAttachButton = isOn
            case "voice":      self.chatVC.features.showVoiceRecording = isOn
            case "ctxMenu":    self.chatVC.features.contextMenuEnabled = isOn
            default: break
            }
        }

        debugPanel.onRandomizePolls = { [weak self] in
            self?.randomizePolls()
        }

        debugPanel.onShuffleMessages = { [weak self] in
            self?.shuffleMessages()
        }

        debugPanel.onClearData = { [weak self] in
            guard let self else { return }
            if self.chatVC.messages.isEmpty {
                self.chatVC.isLoading = false
                self.chatVC.updateMessages(ChatDemoData.makeSampleMessages())
            } else {
                self.chatVC.updateMessages([])
            }
        }
    }

    private func setupLayoutPanel() {
        layoutPanel.translatesAutoresizingMaskIntoConstraints = false
        layoutPanel.backgroundColor = debugPanel.backgroundColor
        view.addSubview(layoutPanel)

        NSLayoutConstraint.activate([
            layoutPanel.topAnchor.constraint(equalTo: debugPanel.bottomAnchor),
            layoutPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            layoutPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let items: [(String, String, CGFloat, CGFloat)] = [
            ("Corner", "bubbleCornerRadius", 18, 6),
            ("MaxW", "bubbleMaxWidthRatio", 0.78, 0.55),
            ("HPad", "bubbleHPad", 12, 20),
            ("VPad", "bubbleVPad", 6, 12),
            ("CellH", "cellHMargin", 8, 20),
            ("CellV", "cellVSpacing", 2, 8),
            ("Font", "messageFont", 15, 18),
            ("ImgH", "imageMaxHeight", 280, 180),
            ("ReplyH", "replyHeight", 38, 50),
        ]

        for (label, key, valA, valB) in items {
            layoutPanel.addToggle(label: label, key: key, titleA: "\(Int(valA))", titleB: "\(Int(valB))")
        }

        layoutPanel.onChanged = { [weak self] key, index in
            guard let self else { return }
            var L = self.chatVC.layout
            switch key {
            case "bubbleCornerRadius": L.bubbleCornerRadius = index == 0 ? 18 : 6
            case "bubbleMaxWidthRatio": L.bubbleMaxWidthRatio = index == 0 ? 0.78 : 0.55
            case "bubbleHPad": L.bubbleHPad = index == 0 ? 12 : 20
            case "bubbleVPad": L.bubbleVPad = index == 0 ? 6 : 12
            case "cellHMargin": L.cellHMargin = index == 0 ? 8 : 20
            case "cellVSpacing": L.cellVSpacing = index == 0 ? 2 : 8
            case "messageFont": L.messageFont = .systemFont(ofSize: index == 0 ? 15 : 18)
            case "imageMaxHeight": L.imageMaxHeight = index == 0 ? 280 : 180
            case "replyHeight": L.replyHeight = index == 0 ? 38 : 50
            default: break
            }
            self.chatVC.layout = L
        }
    }

    private var currentInputBarTheme: InputBarTheme = .dark

    private func setupThemePanel() {
        themePanel.translatesAutoresizingMaskIntoConstraints = false
        themePanel.backgroundColor = debugPanel.backgroundColor
        view.addSubview(themePanel)

        NSLayoutConstraint.activate([
            themePanel.topAnchor.constraint(equalTo: layoutPanel.bottomAnchor),
            themePanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            themePanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let items: [(String, String)] = [
            // Chat colors
            ("OutBbl", "outBubble"),
            ("InBbl", "inBubble"),
            ("OutTxt", "outText"),
            ("InTxt", "inText"),
            ("OutTime", "outTime"),
            ("Sender", "senderName"),
            ("DateBg", "dateSepBg"),
            ("DateTxt", "dateSepTxt"),
            ("ReactBg", "reactBg"),
            ("FabBg", "fabBg"),
            ("Wave", "waveform"),
            ("PollBar", "pollBar"),
            ("Highlight", "highlight"),
            // InputBar colors
            ("IB Bg", "ibBg"),
            ("IB Txt", "ibText"),
            ("IB Tint", "ibTint"),
            ("IB Brd", "ibBorder"),
            ("IB Mic", "ibMic"),
        ]

        for (label, key) in items {
            themePanel.addToggle(label: label, key: key, titleA: "A", titleB: "B")
        }

        themePanel.onChanged = { [weak self] key, index in
            guard let self else { return }
            var T = self.chatVC.theme
            var IB = self.currentInputBarTheme

            switch key {
            // Chat theme
            case "outBubble": T.outgoingBubble = index == 0
                ? UIColor(red: 0.17, green: 0.32, blue: 0.47, alpha: 1)
                : UIColor(red: 0.13, green: 0.45, blue: 0.27, alpha: 1)
            case "inBubble": T.incomingBubble = index == 0
                ? UIColor(red: 0.11, green: 0.15, blue: 0.20, alpha: 1)
                : UIColor(red: 0.18, green: 0.12, blue: 0.22, alpha: 1)
            case "outText": T.outgoingText = index == 0 ? .white : .yellow
            case "inText": T.incomingText = index == 0 ? .white : UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1)
            case "outTime": T.outgoingTime = index == 0
                ? UIColor(white: 1.0, alpha: 0.5)
                : UIColor(red: 0.6, green: 0.9, blue: 0.6, alpha: 0.7)
            case "senderName": T.incomingSenderName = index == 0
                ? UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1)
                : .systemOrange
            case "dateSepBg": T.dateSeparatorBackground = index == 0
                ? UIColor(white: 1.0, alpha: 0.08)
                : UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.3)
            case "dateSepTxt": T.dateSeparatorText = index == 0
                ? UIColor(white: 1.0, alpha: 0.5)
                : UIColor.systemCyan
            case "reactBg": T.reactionBackground = index == 0
                ? UIColor(white: 0.2, alpha: 1)
                : UIColor(red: 0.3, green: 0.15, blue: 0.4, alpha: 1)
            case "fabBg": T.fabBackground = index == 0
                ? UIColor(red: 0.15, green: 0.19, blue: 0.25, alpha: 1)
                : UIColor.systemIndigo
            case "waveform": T.voiceWaveformActive = index == 0
                ? UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1)
                : .systemGreen
            case "pollBar": T.pollBarFilled = index == 0
                ? UIColor(red: 0.35, green: 0.6, blue: 0.9, alpha: 1)
                : .systemOrange
            case "highlight": T.messageHighlightColor = index == 0
                ? UIColor.systemYellow.withAlphaComponent(0.3)
                : UIColor.systemRed.withAlphaComponent(0.3)
            // InputBar theme
            case "ibBg": IB.background = index == 0
                ? UIColor(red: 0.15, green: 0.19, blue: 0.25, alpha: 1)
                : UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
            case "ibText": IB.text = index == 0 ? .white : .systemGreen
            case "ibTint": IB.tint = index == 0
                ? UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1)
                : .systemOrange
            case "ibBorder": IB.border = index == 0
                ? UIColor(white: 0.25, alpha: 1)
                : UIColor.systemPurple.withAlphaComponent(0.5)
            case "ibMic": IB.recordingMicFill = index == 0
                ? UIColor(red: 0.35, green: 0.6, blue: 0.95, alpha: 1)
                : .systemGreen
            default: break
            }

            self.chatVC.theme = T
            self.currentInputBarTheme = IB
            self.chatVC.inputBar.applyTheme(IB)
        }
    }

    // MARK: - Alert Helper

    // MARK: - Load Older Messages

    private func loadOlderMessages() {
        let cal = Calendar.current
        var msgs = chatVC.messages
        let batchSize = 50

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
            let isMine = i % 3 == 0
            let sender = isMine ? nil : senders[i % senders.count]

            let msg = ChatMessage(
                id: "gen-\(messageCounter)",
                content: MessageBody(text: texts[i % texts.count], content: nil),
                timestamp: timestamp,
                senderName: sender,
                isMine: isMine,
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
        chatVC.updateMessages(msgs)
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
        loadOlderMessages()
    }
    func chatDidReachBottom(distance: CGFloat) {}

    func chatDidTapFAB() {
        chatVC.clearUnread()
        chatVC.scrollToBottom(animated: true)
    }

    func chatMessagesDidAppear(ids: [String]) {}

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
            chatVC.updateMessages(msgs)
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
            guard let poll = msgs[i].content.content?.content(as: PollPayload.self), !poll.isClosed else { continue }

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
                content: MessageBody(text: msg.content.text, content: AnyChatContent(updated)),
                timestamp: msg.timestamp, senderName: msg.senderName, isMine: msg.isMine,
                groupDate: msg.groupDate, status: msg.status, reply: msg.reply,
                forwardedFrom: msg.forwardedFrom, reactions: msg.reactions,
                isEdited: msg.isEdited, actions: msg.actions
            )
        }
        chatVC.updateMessages(msgs)
    }

    private func shuffleMessages() {
        var msgs = chatVC.messages
        guard msgs.count > 1 else { return }

        // Shuffle order of some messages
        let swapCount = min(msgs.count / 3, Int.random(in: 2...6))
        for _ in 0..<swapCount {
            let a = Int.random(in: 0..<msgs.count)
            let b = Int.random(in: 0..<msgs.count)
            if a != b { msgs.swapAt(a, b) }
        }

        // Randomly apply several content mutations
        let mutations = Int.random(in: 1...4)
        for _ in 0..<mutations {
            let op = Int.random(in: 0...3)
            switch op {
            case 0 where msgs.count > 3:
                // Delete random message
                let idx = Int.random(in: 0..<msgs.count)
                msgs.remove(at: idx)

            case 1:
                // Edit random message text
                let idx = Int.random(in: 0..<msgs.count)
                let msg = msgs[idx]
                let texts = [
                    "Отредактировано! 📝",
                    "Новый текст после shuffle",
                    "Lorem ipsum dolor sit amet",
                    "Короткий",
                    "Очень длинный текст сообщения который должен занимать несколько строк в бабле чата и проверять что размеры правильно пересчитываются при редактировании 🔄",
                ]
                msgs[idx] = ChatMessage(
                    id: msg.id,
                    content: MessageBody(text: texts.randomElement()!, content: msg.content.content),
                    timestamp: msg.timestamp, senderName: msg.senderName, isMine: msg.isMine,
                    groupDate: msg.groupDate, status: msg.status, reply: msg.reply,
                    forwardedFrom: msg.forwardedFrom,
                    reactions: msg.reactions, isEdited: true, actions: msg.actions
                )

            case 2:
                // Toggle reactions on random message
                let idx = Int.random(in: 0..<msgs.count)
                let msg = msgs[idx]
                let emojis = ["👍", "❤️", "😂", "🔥", "👀", "🎉"]
                let newReactions = (0..<Int.random(in: 0...3)).map {
                    Reaction(emoji: emojis[$0 % emojis.count], count: Int.random(in: 1...10), isMine: Bool.random())
                }
                msgs[idx] = ChatMessage(
                    id: msg.id, content: msg.content, timestamp: msg.timestamp,
                    senderName: msg.senderName, isMine: msg.isMine, groupDate: msg.groupDate,
                    status: msg.status, reply: msg.reply, forwardedFrom: msg.forwardedFrom,
                    reactions: newReactions, isEdited: msg.isEdited, actions: msg.actions
                )

            default:
                // Change status of random message
                let idx = Int.random(in: 0..<msgs.count)
                let msg = msgs[idx]
                let statuses: [MessageStatus] = [.sending, .sent, .delivered, .read]
                msgs[idx] = ChatMessage(
                    id: msg.id, content: msg.content, timestamp: msg.timestamp,
                    senderName: msg.senderName, isMine: msg.isMine, groupDate: msg.groupDate,
                    status: statuses.randomElement()!, reply: msg.reply,
                    forwardedFrom: msg.forwardedFrom, reactions: msg.reactions,
                    isEdited: msg.isEdited, actions: msg.actions
                )
            }
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
            content: MessageBody(text: text, content: nil),
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
        var msgs = chatVC.messages
        guard let idx = msgs.firstIndex(where: { $0.id == messageId }) else { return }
        let msg = msgs[idx]
        msgs[idx] = ChatMessage(
            id: msg.id,
            content: MessageBody(text: text, content: msg.content.content),
            timestamp: msg.timestamp,
            senderName: msg.senderName,
            isMine: msg.isMine,
            groupDate: msg.groupDate,
            status: msg.status,
            reply: msg.reply,
            forwardedFrom: msg.forwardedFrom,
            reactions: msg.reactions,
            isEdited: true,
            actions: msg.actions
        )
        chatVC.updateMessages(msgs)
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
