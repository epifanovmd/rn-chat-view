import UIKit

final class MessageBubbleView: UIView {

    // MARK: - Callbacks

    var onReplyTap: (() -> Void)?
    var onMediaItemTap: ((Int) -> Void)?
    var onFileItemTap: ((Int) -> Void)?
    var onPollOptionTap: ((String, String) -> Void)?
    var onPollDetailTap: ((String) -> Void)?
    var onVoiceTap: ((String) -> Void)?
    var onReactionTap: ((String) -> Void)?

    // MARK: - Subviews

    private let stack = UIStackView()
    private let senderLabel = UILabel()
    private let forwardedLabel = UILabel()
    private let replyPreview = ReplyPreviewView()
    private var contentView: UIView?
    private let reactionsView = ReactionsView()
    private let footerContainer = UIView()
    private let editedLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusView = MessageStatusView()

    private var isEmojiOnly = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        layer.cornerRadius = ChatLayout.current.bubbleCornerRadius
        layer.masksToBounds = true

        stack.axis = .vertical
        stack.spacing = ChatLayout.current.bubbleSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        senderLabel.font = ChatLayout.current.senderNameFont
        senderLabel.numberOfLines = 1
        forwardedLabel.font = ChatLayout.current.forwardedFont
        forwardedLabel.numberOfLines = 1
        editedLabel.font = ChatLayout.current.editedFont
        editedLabel.text = "edited"
        timeLabel.font = ChatLayout.current.timeFont

        setupFooter()

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ChatLayout.current.bubbleVPad),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ChatLayout.current.bubbleHPad),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ChatLayout.current.bubbleHPad),
        ])
    }

    private var footerTrailingGroup: [NSLayoutConstraint] = []
    private var footerLeadingGroup: [NSLayoutConstraint] = []

    private func setupFooter() {
        footerContainer.translatesAutoresizingMaskIntoConstraints = false
        [editedLabel, timeLabel, statusView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            footerContainer.addSubview($0)
        }

        NSLayoutConstraint.activate([
            footerContainer.heightAnchor.constraint(equalToConstant: ChatLayout.current.footerHeight),
            statusView.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
            statusView.widthAnchor.constraint(equalToConstant: ChatLayout.current.statusIconSize),
            statusView.heightAnchor.constraint(equalToConstant: ChatLayout.current.statusIconSize),
            timeLabel.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
            editedLabel.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
        ])

        // Outgoing: [edited] [time] [status] ─── trailing
        footerTrailingGroup = [
            statusView.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: -ChatLayout.current.footerSpacing),
            editedLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -ChatLayout.current.footerSpacing),
        ]

        // Incoming: leading ─── [edited] [time]
        footerLeadingGroup = [
            editedLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -ChatLayout.current.footerSpacing),
            timeLabel.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
        ]
    }

    private func applyFooterLayout(isMine: Bool) {
        footerTrailingGroup.forEach { $0.isActive = false }
        footerLeadingGroup.forEach { $0.isActive = false }
        if isMine {
            footerTrailingGroup.forEach { $0.isActive = true }
        } else {
            footerLeadingGroup.forEach { $0.isActive = true }
        }
    }

    // MARK: - Configure

    func configure(message: ChatMessage, resolvedReply: ReplyDisplayInfo?, theme: ChatTheme, bubbleWidth: CGFloat, showSenderName: Bool = false) {
        let isMine = message.isMine
        let content = message.content
        isEmojiOnly = !content.hasMedia && EmojiHelper.emojiOnlyCount(content.text) != nil

        // Background
        if isEmojiOnly {
            backgroundColor = .clear
            layer.cornerRadius = 0
        } else {
            backgroundColor = isMine ? theme.outgoingBubble : theme.incomingBubble
            layer.cornerRadius = ChatLayout.current.bubbleCornerRadius
        }

        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }

        // Sender Name
        if showSenderName, let name = message.senderName, !isMine {
            senderLabel.text = name
            senderLabel.textColor = theme.incomingSenderName
            stack.addArrangedSubview(senderLabel)
        }

        // Forwarded
        if let fwd = message.forwardedFrom {
            forwardedLabel.text = "↗ \(fwd)"
            forwardedLabel.textColor = isMine ? theme.outgoingForwardedLabel : theme.incomingForwardedLabel
            stack.addArrangedSubview(forwardedLabel)
        }

        // Reply Preview
        if let reply = message.reply {
            replyPreview.configure(reply: reply, resolved: resolvedReply, isMine: isMine, theme: theme)
            replyPreview.onTap = { [weak self] in self?.onReplyTap?() }
            stack.addArrangedSubview(replyPreview)
        }

        // Content
        let innerW = bubbleWidth - ChatLayout.current.bubbleHPad * 2
        let newContent = createContentView(for: message, width: innerW, isMine: isMine, theme: theme)
        contentView = newContent
        stack.addArrangedSubview(newContent)

        // Reactions
        if !message.reactions.isEmpty {
            reactionsView.configure(reactions: message.reactions, theme: theme)
            reactionsView.onReactionTap = { [weak self] emoji in self?.onReactionTap?(emoji) }
            stack.addArrangedSubview(reactionsView)
        }

        // Footer
        if !isEmojiOnly {
            configureFooter(message: message, isMine: isMine, theme: theme)
            stack.addArrangedSubview(footerContainer)
        }
    }

    // MARK: - Content Factory

    private func createContentView(for msg: ChatMessage, width: CGFloat, isMine: Bool, theme: ChatTheme) -> UIView {
        let content = msg.content

        // Emoji-only (text without media, 1-3 emoji)
        if !content.hasMedia, let count = EmojiHelper.emojiOnlyCount(content.text) {
            return createEmojiView(text: content.text!, count: count)
        }

        // Build content stack: media on top, text on bottom (if both present)
        var views: [UIView] = []

        // Media view (by priority: poll > file > voice > media grid)
        if let poll = content.poll {
            let view = PollContentView()
            view.configure(poll: poll, isMine: isMine, theme: theme)
            view.onOptionTap = { [weak self] optionId in self?.onPollOptionTap?(poll.id, optionId) }
            view.onDetailTap = { [weak self] in self?.onPollDetailTap?(poll.id) }
            views.append(view)
        } else if let files = content.files, !files.isEmpty {
            let filesStack = UIStackView()
            filesStack.axis = .vertical
            filesStack.spacing = ChatLayout.current.fileRowSpacing
            for (index, file) in files.enumerated() {
                let view = FileContentView()
                view.configure(file: file, isMine: isMine, theme: theme)
                view.onTap = { [weak self] in self?.onFileItemTap?(index) }
                filesStack.addArrangedSubview(view)
            }
            views.append(filesStack)
        } else if let voice = content.voice {
            let view = VoiceContentView()
            view.configure(voice: voice, isMine: isMine, theme: theme)
            view.onPlayTap = { [weak self] in self?.onVoiceTap?(voice.url) }
            views.append(view)
        } else if let media = content.media, !media.isEmpty {
            let grid = MediaGridView()
            grid.configure(media: media, width: width, theme: theme)
            grid.onItemTap = { [weak self] index in self?.onMediaItemTap?(index) }
            views.append(grid)
        }

        // Text (caption or standalone)
        if let text = content.text, !text.isEmpty {
            views.append(createTextView(text: text, isMine: isMine, theme: theme, width: width))
        }

        // Single view — return directly
        if views.count == 1 {
            return views[0]
        }

        // Multiple views (media + text) — vertical stack
        if views.count > 1 {
            let container = UIStackView()
            container.axis = .vertical
            container.spacing = ChatLayout.current.mixedContentSpacing
            views.forEach { container.addArrangedSubview($0) }
            return container
        }

        // Fallback: empty text
        return createTextView(text: "", isMine: isMine, theme: theme, width: width)
    }

    private func createEmojiView(text: String, count: Int) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = MessageSizeCalculator.emojiFont(for: count)
        label.textAlignment = .center
        return label
    }

    private func createTextView(text: String, isMine: Bool, theme: ChatTheme, width: CGFloat) -> UIView {
        let view = TextContentView()
        view.configure(text: text, isMine: isMine, theme: theme)
        return view
    }

    // MARK: - Footer

    private func configureFooter(message: ChatMessage, isMine: Bool, theme: ChatTheme) {
        timeLabel.text = DateHelper.shared.timeString(from: message.timestamp)
        timeLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
        editedLabel.isHidden = !message.isEdited
        editedLabel.textColor = isMine ? theme.outgoingEdited : theme.incomingEdited
        statusView.configure(status: message.status, isMine: isMine, theme: theme)

        statusView.isHidden = !isMine
        applyFooterLayout(isMine: isMine)
    }

    // MARK: - Reuse

    func prepareForReuse() {
        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
        contentView = nil
        onReplyTap = nil
        onMediaItemTap = nil
        onFileItemTap = nil
        onPollOptionTap = nil
        onPollDetailTap = nil
        onVoiceTap = nil
        onReactionTap = nil
    }
}
