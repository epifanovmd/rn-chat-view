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
    private let forwardedContainer = UIView()
    private let forwardedAccent = UIView()
    private let forwardedStack = UIStackView()
    private let replyPreview = ReplyPreviewView()
    private var contentView: UIView?
    private let reactionsView = ReactionsView()
    private let footerContainer = UIView()
    private let editedLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusView = MessageStatusView()

    private var isEmojiOnly = false
    private var currentLayout = ChatLayout()

    // MARK: - Stored constraints (updated in applyLayout)

    private var stackTopConstraint: NSLayoutConstraint!
    private var stackLeadingConstraint: NSLayoutConstraint!
    private var stackTrailingConstraint: NSLayoutConstraint!

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        layer.masksToBounds = true

        stack.axis = .vertical
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        senderLabel.numberOfLines = 1
        forwardedLabel.numberOfLines = 1
        editedLabel.text = "изм."

        setupForwardedContainer()
        setupFooter()

        stackTopConstraint = stack.topAnchor.constraint(equalTo: topAnchor)
        stackLeadingConstraint = stack.leadingAnchor.constraint(equalTo: leadingAnchor)
        stackTrailingConstraint = stack.trailingAnchor.constraint(equalTo: trailingAnchor)

        NSLayoutConstraint.activate([stackTopConstraint, stackLeadingConstraint, stackTrailingConstraint])

        applyLayout(ChatLayout())
    }

    private func applyLayout(_ L: ChatLayout) {
        currentLayout = L
        layer.cornerRadius = L.bubbleCornerRadius
        stack.spacing = L.bubbleSpacing
        senderLabel.font = L.senderNameFont
        forwardedLabel.font = L.forwardedFont
        editedLabel.font = L.editedFont
        timeLabel.font = L.timeFont
        stackTopConstraint.constant = L.bubbleVPad
        stackLeadingConstraint.constant = L.bubbleHPad
        stackTrailingConstraint.constant = -L.bubbleHPad
    }

    private func setupForwardedContainer() {
        let L = ChatLayout()

        forwardedAccent.translatesAutoresizingMaskIntoConstraints = false
        forwardedAccent.layer.cornerRadius = L.forwardedAccentWidth / 2

        forwardedStack.axis = .vertical
        forwardedStack.spacing = L.bubbleSpacing
        forwardedStack.translatesAutoresizingMaskIntoConstraints = false

        forwardedContainer.addSubview(forwardedAccent)
        forwardedContainer.addSubview(forwardedStack)

        NSLayoutConstraint.activate([
            forwardedAccent.leadingAnchor.constraint(equalTo: forwardedContainer.leadingAnchor),
            forwardedAccent.topAnchor.constraint(equalTo: forwardedContainer.topAnchor),
            forwardedAccent.bottomAnchor.constraint(equalTo: forwardedContainer.bottomAnchor),
            forwardedAccent.widthAnchor.constraint(equalToConstant: L.forwardedAccentWidth),

            forwardedStack.leadingAnchor.constraint(equalTo: forwardedAccent.trailingAnchor, constant: L.forwardedContentInset),
            forwardedStack.trailingAnchor.constraint(equalTo: forwardedContainer.trailingAnchor),
            forwardedStack.topAnchor.constraint(equalTo: forwardedContainer.topAnchor),
            forwardedStack.bottomAnchor.constraint(equalTo: forwardedContainer.bottomAnchor),
        ])
    }

    private let footerStack = UIStackView()

    private func setupFooter() {
        footerContainer.translatesAutoresizingMaskIntoConstraints = false

        footerStack.axis = .horizontal
        footerStack.spacing = ChatLayout().footerSpacing
        footerStack.alignment = .center
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.addSubview(footerStack)

        statusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footerContainer.heightAnchor.constraint(equalToConstant: ChatLayout().footerHeight),
            footerStack.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            footerStack.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
            statusView.widthAnchor.constraint(equalToConstant: ChatLayout().statusIconSize),
            statusView.heightAnchor.constraint(equalToConstant: ChatLayout().statusIconSize),
        ])

        // Order: [edited] [time] [status] — stack handles spacing for hidden views
        footerStack.addArrangedSubview(editedLabel)
        footerStack.addArrangedSubview(timeLabel)
        footerStack.addArrangedSubview(statusView)
    }

    // MARK: - Configure

    func configure(message: ChatMessage, resolvedReply: ReplyDisplayInfo?, theme: ChatTheme, bubbleWidth: CGFloat, showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), layout: ChatLayout = ChatLayout()) {
        applyLayout(layout)
        let isMine = message.isMine
        let content = message.content
        isEmojiOnly = !content.hasMedia && EmojiHelper.emojiOnlyCount(content.text) != nil

        // Background
        if isEmojiOnly {
            backgroundColor = .clear
            layer.cornerRadius = 0
        } else {
            backgroundColor = isMine ? theme.outgoingBubble : theme.incomingBubble
            layer.cornerRadius = currentLayout.bubbleCornerRadius
        }

        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }

        // Sender Name
        if showSenderName, let name = message.senderName, !isMine {
            senderLabel.text = name
            senderLabel.textColor = theme.incomingSenderName
            stack.addArrangedSubview(senderLabel)
        }

        // Forwarded
        let isForwarded = features.showForwardedMark && message.forwardedFrom != nil
        if let fwd = message.forwardedFrom, features.showForwardedMark {
            let L = currentLayout
            let accentColor = isMine ? theme.outgoingForwardedAccent : theme.incomingForwardedAccent
            forwardedAccent.backgroundColor = accentColor

            forwardedLabel.text = "Переслано от \(fwd)"
            forwardedLabel.textColor = isMine ? theme.outgoingForwardedLabel : theme.incomingForwardedLabel

            forwardedStack.arrangedSubviews.forEach { forwardedStack.removeArrangedSubview($0); $0.removeFromSuperview() }
            forwardedStack.addArrangedSubview(forwardedLabel)

            // Reply Preview inside forwarded
            if features.showReplyPreview, let reply = message.reply {
                replyPreview.configure(reply: reply, resolved: resolvedReply, isMine: isMine, theme: theme)
                replyPreview.onTap = { [weak self] in self?.onReplyTap?() }
                forwardedStack.addArrangedSubview(replyPreview)
            }

            // Content inside forwarded
            let contentInnerW = bubbleWidth - L.bubbleHPad * 2 - L.forwardedAccentWidth - L.forwardedContentInset
            let newContent = createContentView(for: message, width: contentInnerW, isMine: isMine, theme: theme)
            contentView = newContent
            forwardedStack.addArrangedSubview(newContent)

            stack.addArrangedSubview(forwardedContainer)
        }

        if !isForwarded {
            // Reply Preview
            if features.showReplyPreview, let reply = message.reply {
                replyPreview.configure(reply: reply, resolved: resolvedReply, isMine: isMine, theme: theme)
                replyPreview.onTap = { [weak self] in self?.onReplyTap?() }
                stack.addArrangedSubview(replyPreview)
            }

            // Voice top spacer
            let hasReply = features.showReplyPreview && message.reply != nil
            let hasHeader = (showSenderName && message.senderName != nil && !isMine) || hasReply
            if content.voice != nil, !hasHeader {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.heightAnchor.constraint(equalToConstant: 4).isActive = true
                stack.addArrangedSubview(spacer)
            }

            // Content
            let innerW = bubbleWidth - currentLayout.bubbleHPad * 2
            let newContent = createContentView(for: message, width: innerW, isMine: isMine, theme: theme)
            contentView = newContent
            stack.addArrangedSubview(newContent)
        }

        // Reactions
        if features.showReactions, !message.reactions.isEmpty {
            let maxReactionWidth = bubbleWidth - currentLayout.bubbleHPad * 2
            reactionsView.configure(reactions: message.reactions, theme: theme, maxWidth: maxReactionWidth)
            reactionsView.onReactionTap = { [weak self] emoji in self?.onReactionTap?(emoji) }
            stack.addArrangedSubview(reactionsView)
        }

        // Footer
        if !isEmojiOnly {
            let hasFooter = features.showTimestamp || (message.isEdited && features.showEditedMark) || (isMine && features.showMessageStatus)
            if hasFooter {
                configureFooter(message: message, isMine: isMine, theme: theme, features: features)
                stack.addArrangedSubview(footerContainer)
            }
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
            filesStack.spacing = currentLayout.fileRowSpacing
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
            container.spacing = currentLayout.mixedContentSpacing
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

    private func configureFooter(message: ChatMessage, isMine: Bool, theme: ChatTheme, features: ChatFeatures) {
        timeLabel.text = DateHelper.shared.timeString(from: message.timestamp)
        timeLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
        timeLabel.isHidden = !features.showTimestamp

        editedLabel.isHidden = !message.isEdited || !features.showEditedMark
        editedLabel.textColor = isMine ? theme.outgoingEdited : theme.incomingEdited

        statusView.configure(status: message.status, isMine: isMine, theme: theme)
        statusView.isHidden = !isMine || !features.showMessageStatus
    }

    // MARK: - Reuse

    func prepareForReuse() {
        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
        forwardedStack.arrangedSubviews.forEach { forwardedStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        contentView = nil
        onReplyTap = nil
        onMediaItemTap = nil
        onFileItemTap = nil
        onPollOptionTap = nil
        onPollDetailTap = nil
        onVoiceTap = nil
        onReactionTap = nil
        // Reset footer visibility
        timeLabel.isHidden = false
        editedLabel.isHidden = true
        statusView.isHidden = false
    }
}
