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
                content: MessageContent(text: "Hey! How's it going?", media: nil, voice: nil, poll: nil, files: nil),
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
                content: MessageContent(text: "Hi Alice! All good, working on the chat component 🚀", media: nil, voice: nil, poll: nil, files: nil),
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
                content: MessageContent(text: "Sounds great! Can you share the design?", media: nil, voice: nil, poll: nil, files: nil),
                timestamp: cal.date(byAdding: .hour, value: -23, to: now)!,
                senderName: otherUser,
                isMine: false,
                groupDate: yesterday,
                status: .read,
                reply: ReplyInfo(replyToId: "2", senderName: "You", text: "Hi Alice! All good, working on the chat component 🚀", hasImage: false),
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),

            // 4. Image message (outgoing)
            ChatMessage(
                id: "4",
                content: MessageContent(
                    text: "Here's the mockup",
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

            // 5. Multi-image message (incoming)
            ChatMessage(
                id: "5",
                content: MessageContent(
                    text: nil,
                    media: [
                        .image(ImageItem(url: "https://picsum.photos/id/10/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/10/200/150")),
                        .image(ImageItem(url: "https://picsum.photos/id/20/300/400", width: 300, height: 400, thumbnailUrl: "https://picsum.photos/id/20/150/200")),
                        .image(ImageItem(url: "https://picsum.photos/id/30/400/400", width: 400, height: 400, thumbnailUrl: "https://picsum.photos/id/30/200/200")),
                    ],
                    voice: nil, poll: nil, files: nil
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!,
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

            // 7. File message (incoming)
            ChatMessage(
                id: "7",
                content: MessageContent(
                    text: "Check out this document",
                    media: nil, voice: nil, poll: nil,
                    files: [
                        FilePayload(url: "https://example.com/report.pdf", name: "Q4_Report_2025.pdf", size: 2_540_000, mimeType: "application/pdf"),
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

            // 8. Poll message (outgoing)
            ChatMessage(
                id: "8",
                content: MessageContent(
                    text: nil, media: nil, voice: nil,
                    poll: PollPayload(
                        id: "poll-1",
                        question: "When should we have the team meeting?",
                        options: [
                            PollOption(id: "opt-1", text: "Monday 10 AM", votes: 3, percentage: 0.5),
                            PollOption(id: "opt-2", text: "Tuesday 2 PM", votes: 2, percentage: 0.33),
                            PollOption(id: "opt-3", text: "Wednesday 11 AM", votes: 1, percentage: 0.17),
                        ],
                        totalVotes: 6,
                        selectedOptionIds: ["opt-1"],
                        isMultipleChoice: false,
                        isClosed: false
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

            // 9. Forwarded message (incoming)
            ChatMessage(
                id: "9",
                content: MessageContent(text: "The deployment is scheduled for Friday at 6 PM UTC. Please make sure all PRs are merged by Thursday EOD.", media: nil, voice: nil, poll: nil, files: nil),
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
                content: MessageContent(text: "Got it, I'll finish my PR today", media: nil, voice: nil, poll: nil, files: nil),
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
                    text: "By the way, I wanted to mention that the new API endpoint for user preferences is ready for testing. The documentation has been updated in Confluence. You can find the Swagger specs at /api/v2/preferences. Let me know if you have any questions or run into issues!",
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
                content: MessageContent(text: "Thanks, will check it out right now!", media: nil, voice: nil, poll: nil, files: nil),
                timestamp: now,
                senderName: nil,
                isMine: true,
                groupDate: today,
                status: .sending,
                reply: ReplyInfo(replyToId: "11", senderName: otherUser, text: "By the way, I wanted to mention that the new API endpoint...", hasImage: false),
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: defaultActions
            ),
        ]
    }

    private static let defaultActions: [MessageAction] = [
        MessageAction(id: "reply", title: "Reply", systemImage: "arrowshape.turn.up.left", isDestructive: false),
        MessageAction(id: "copy", title: "Copy", systemImage: "doc.on.doc", isDestructive: false),
        MessageAction(id: "forward", title: "Forward", systemImage: "arrowshape.turn.up.right", isDestructive: false),
        MessageAction(id: "delete", title: "Delete", systemImage: "trash", isDestructive: true),
    ]
}

// MARK: - Debug Panel

private final class DebugPanelView: UIView {

    var onThemeChanged: ((ChatTheme) -> Void)?
    var onSenderNameChanged: ((Bool) -> Void)?

    private let themeToggle: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Light", "Dark"])
        control.selectedSegmentIndex = 0
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
        addSubview(separator)

        themeToggle.addTarget(self, action: #selector(themeToggleChanged), for: .valueChanged)
        senderNameToggle.addTarget(self, action: #selector(senderNameToggleChanged), for: .valueChanged)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),

            themeToggle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            themeToggle.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            senderNameLabel.leadingAnchor.constraint(equalTo: themeToggle.trailingAnchor, constant: 16),
            senderNameLabel.centerYAnchor.constraint(equalTo: themeToggle.centerYAnchor),

            senderNameToggle.leadingAnchor.constraint(equalTo: senderNameLabel.trailingAnchor, constant: 8),
            senderNameToggle.centerYAnchor.constraint(equalTo: themeToggle.centerYAnchor),

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
}

// MARK: - Demo ViewController

final class ChatDemoViewController: UIViewController, ChatViewControllerDelegate {

    private let chatVC = ChatViewController()
    private let debugPanel = DebugPanelView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ChatTheme.light.backgroundColor

        setupDebugPanel()

        chatVC.delegate = self
        chatVC.theme = .light
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
    }

    // MARK: - ChatViewControllerDelegate

    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachTop(distance: CGFloat) { print("[Demo] Reached top, distance: \(distance)") }
    func chatDidReachBottom(distance: CGFloat) { print("[Demo] Reached bottom, distance: \(distance)") }
    func chatMessagesDidAppear(ids: [String]) { print("[Demo] Visible: \(ids)") }

    func chatDidTapMessage(id: String, attachmentIndex: Int?) {
        print("[Demo] Tapped message \(id), attachment: \(String(describing: attachmentIndex))")
    }

    func chatDidSelectAction(actionId: String, messageId: String) {
        print("[Demo] Action \(actionId) on message \(messageId)")

        if actionId == "reply", let msg = chatVC.message(forID: messageId) {
            chatVC.beginReply(info: ReplyInfo(
                replyToId: messageId,
                senderName: msg.senderName ?? "You",
                text: msg.content.text,
                hasImage: msg.content.media?.isEmpty == false
            ))
        }
    }

    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {
        print("[Demo] Reaction \(emoji) on message \(messageId)")
    }

    func chatDidTapReaction(messageId: String, emoji: String) {
        print("[Demo] Tapped reaction \(emoji) on \(messageId)")
    }

    func chatDidTapReplyMessage(id: String) {
        print("[Demo] Tapped reply to \(id)")
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }

    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String) {
        print("[Demo] Poll \(pollId) option \(optionId) tapped")
    }

    func chatDidTapPollDetail(messageId: String, pollId: String) {
        print("[Demo] Poll \(pollId) detail tapped")
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
        print("[Demo] Edit message \(messageId): \"\(text)\"")
    }

    func chatDidCancelInputAction(type: String) {
        print("[Demo] Cancel input action: \(type)")
    }

    func chatDidTapAttachment() {
        print("[Demo] Attachment tapped")
    }

    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval) {
        print("[Demo] Voice recording: \(fileURL), duration: \(duration)s")
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
