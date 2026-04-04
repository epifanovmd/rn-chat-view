import UIKit

final class MessageBubbleView: UIView {

    // MARK: - Callbacks

    var onReplyTap: (() -> Void)?
    var onContentInteraction: ((ChatContentInteraction) -> Void)?
    var onReactionTap: ((String) -> Void)?

    // MARK: - Subviews

    private let stack = UIStackView()
    private var contentView: UIView?

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
        stackTopConstraint.constant = L.bubbleVPad
        stackLeadingConstraint.constant = L.bubbleHPad
        stackTrailingConstraint.constant = -L.bubbleHPad
    }

    // MARK: - Configure

    func configure(message: ChatMessage, resolvedReply: ReplyDisplayInfo?, theme: ChatTheme, bubbleWidth: CGFloat, showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), layout: ChatLayout = ChatLayout(), factory: ChatContentFactory = DefaultChatContentFactory()) {
        applyLayout(layout)
        let isMine = message.isMine
        let content = message.content
        isEmojiOnly = content.media == nil && EmojiHelper.emojiOnlyCount(content.text) != nil

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
            let senderView = factory.senderNameView(name: name, theme: theme, layout: currentLayout)
            stack.addArrangedSubview(senderView)
        }

        // Forwarded
        let isForwarded = features.showForwardedMark && message.forwardedFrom != nil
        if let fwd = message.forwardedFrom, features.showForwardedMark {
            let L = currentLayout
            let accentColor = isMine ? theme.outgoingForwardedAccent : theme.incomingForwardedAccent

            let forwardedHeaderLabel = factory.forwardedHeaderView(from: fwd, isMine: isMine, theme: theme, layout: currentLayout)

            let forwardedAccent = UIView()
            forwardedAccent.translatesAutoresizingMaskIntoConstraints = false
            forwardedAccent.backgroundColor = accentColor
            forwardedAccent.layer.cornerRadius = L.forwardedAccentWidth / 2

            let forwardedStack = UIStackView()
            forwardedStack.axis = .vertical
            forwardedStack.spacing = L.bubbleSpacing
            forwardedStack.translatesAutoresizingMaskIntoConstraints = false

            forwardedStack.addArrangedSubview(forwardedHeaderLabel)

            // Reply Preview inside forwarded
            if features.showReplyPreview, let reply = message.reply {
                let replyView = factory.replyPreviewView(reply: reply, resolved: resolvedReply, isMine: isMine, theme: theme, layout: currentLayout) { [weak self] in
                    self?.onReplyTap?()
                }
                forwardedStack.addArrangedSubview(replyView)
            }

            // Content inside forwarded
            let contentInnerW = bubbleWidth - L.bubbleHPad * 2 - L.forwardedAccentWidth - L.forwardedContentInset
            let newContent = createContentView(for: message, width: contentInnerW, isMine: isMine, theme: theme, factory: factory)
            contentView = newContent
            forwardedStack.addArrangedSubview(newContent)

            let forwardedContainer = UIView()
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

            stack.addArrangedSubview(forwardedContainer)
        }

        if !isForwarded {
            // Reply Preview
            if features.showReplyPreview, let reply = message.reply {
                let replyView = factory.replyPreviewView(reply: reply, resolved: resolvedReply, isMine: isMine, theme: theme, layout: currentLayout) { [weak self] in
                    self?.onReplyTap?()
                }
                stack.addArrangedSubview(replyView)
            }

            // Voice top spacer
            let hasReply = features.showReplyPreview && message.reply != nil
            let hasHeader = (showSenderName && message.senderName != nil && !isMine) || hasReply
            if case .voice = content.media, !hasHeader {
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.heightAnchor.constraint(equalToConstant: 4).isActive = true
                stack.addArrangedSubview(spacer)
            }

            // Content
            let innerW = bubbleWidth - currentLayout.bubbleHPad * 2
            let newContent = createContentView(for: message, width: innerW, isMine: isMine, theme: theme, factory: factory)
            contentView = newContent
            stack.addArrangedSubview(newContent)
        }

        // Reactions
        if features.showReactions, !message.reactions.isEmpty {
            let maxReactionWidth = bubbleWidth - currentLayout.bubbleHPad * 2
            let reactionsViewInstance = factory.reactionsView(reactions: message.reactions, theme: theme, maxWidth: maxReactionWidth, layout: currentLayout) { [weak self] emoji in
                self?.onReactionTap?(emoji)
            }
            stack.addArrangedSubview(reactionsViewInstance)
        }

        // Footer
        if !isEmojiOnly {
            if let footerView = factory.footerView(message: message, theme: theme, layout: currentLayout, features: features) {
                stack.addArrangedSubview(footerView)
            }
        }
    }

    // MARK: - Content Factory

    private func createContentView(for msg: ChatMessage, width: CGFloat, isMine: Bool, theme: ChatTheme, factory: ChatContentFactory) -> UIView {
        let content = msg.content

        // Emoji-only (text without media, 1-3 emoji)
        if content.media == nil, let count = EmojiHelper.emojiOnlyCount(content.text) {
            return factory.emojiView(text: content.text!, emojiCount: count, layout: currentLayout)
        }

        // Build content stack: media on top, text on bottom (if both present)
        var views: [UIView] = []

        // Media view
        if let media = content.media {
            let mediaView = factory.contentView(for: media, message: msg, width: width, theme: theme, layout: currentLayout) { [weak self] interaction in
                self?.onContentInteraction?(interaction)
            }
            views.append(mediaView)
        }

        // Text (caption or standalone)
        if let text = content.text, !text.isEmpty {
            views.append(factory.textView(text: text, isMine: isMine, theme: theme, layout: currentLayout))
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
        return factory.textView(text: "", isMine: isMine, theme: theme, layout: currentLayout)
    }

    // MARK: - Reuse

    func prepareForReuse() {
        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
        contentView = nil
        onReplyTap = nil
        onContentInteraction = nil
        onReactionTap = nil
    }
}
