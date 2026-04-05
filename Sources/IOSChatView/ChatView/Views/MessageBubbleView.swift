import UIKit

public final class MessageBubbleView: UIView {

    // MARK: - Callbacks

    var onReplyTap: (() -> Void)?
    var onContentInteraction: ((ChatContentInteraction) -> Void)?
    var onReactionTap: ((String) -> Void)?

    // MARK: - Subviews

    private let stack = UIStackView()
    private var contentView: UIView?
    private var reactionsView: UIView?
    private var footerView: UIView?

    private var isEmojiOnly = false
    private var currentLayout = ChatLayout()
    private(set) var currentMessage: ChatMessage?

    // MARK: - Stored constraints (updated in applyLayout)

    private var stackTopConstraint: NSLayoutConstraint!
    private var stackLeadingConstraint: NSLayoutConstraint!
    private var stackTrailingConstraint: NSLayoutConstraint!

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) { fatalError() }

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
        isEmojiOnly = content.content == nil && EmojiHelper.emojiOnlyCount(content.text) != nil

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

            // Content
            let innerW = bubbleWidth - currentLayout.bubbleHPad * 2
            let newContent = createContentView(for: message, width: innerW, isMine: isMine, theme: theme, factory: factory)
            contentView = newContent
            stack.addArrangedSubview(newContent)
        }

        // Reactions
        reactionsView = nil
        if features.showReactions, !message.reactions.isEmpty {
            let maxReactionWidth = bubbleWidth - currentLayout.bubbleHPad * 2
            let rv = factory.reactionsView(reactions: message.reactions, theme: theme, maxWidth: maxReactionWidth, layout: currentLayout) { [weak self] emoji in
                self?.onReactionTap?(emoji)
            }
            reactionsView = rv
            stack.addArrangedSubview(rv)
        }

        // Footer
        footerView = nil
        if !isEmojiOnly {
            if let fv = factory.footerView(message: message, theme: theme, layout: currentLayout, features: features) {
                footerView = fv
                stack.addArrangedSubview(fv)
            }
        }

        currentMessage = message
    }

    // MARK: - Content Factory

    private func createContentView(for msg: ChatMessage, width: CGFloat, isMine: Bool, theme: ChatTheme, factory: ChatContentFactory) -> UIView {
        let content = msg.content

        // Emoji-only (text without media, 1-3 emoji)
        if content.content == nil, let count = EmojiHelper.emojiOnlyCount(content.text) {
            return factory.emojiView(text: content.text!, emojiCount: count, layout: currentLayout)
        }

        // Build content stack: media on top, text on bottom (if both present)
        var views: [UIView] = []

        // Media view
        if let media = content.content {
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

    // MARK: - Reconfigure In-Place

    /// Reconfigures the bubble without destroying/recreating the view hierarchy.
    /// Falls back to full `configure()` when structural shape changes.
    func reconfigureInPlace(message: ChatMessage, resolvedReply: ReplyDisplayInfo?, theme: ChatTheme, bubbleWidth: CGFloat, showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), layout: ChatLayout = ChatLayout(), factory: ChatContentFactory = DefaultChatContentFactory()) {
        guard let old = currentMessage, canReconfigureInPlace(from: old, to: message, showSenderName: showSenderName, features: features) else {
            configure(message: message, resolvedReply: resolvedReply, theme: theme, bubbleWidth: bubbleWidth, showSenderName: showSenderName, features: features, layout: layout, factory: factory)
            return
        }

        applyLayout(layout)
        let isMine = message.isMine
        let content = message.content

        // Background
        backgroundColor = isMine ? theme.outgoingBubble : theme.incomingBubble

        // Update content view in-place
        let isForwarded = features.showForwardedMark && message.forwardedFrom != nil
        let innerW: CGFloat
        if isForwarded {
            innerW = bubbleWidth - currentLayout.bubbleHPad * 2 - currentLayout.forwardedAccentWidth - currentLayout.forwardedContentInset
        } else {
            innerW = bubbleWidth - currentLayout.bubbleHPad * 2
        }
        reconfigureContentView(message: message, width: innerW, isMine: isMine, theme: theme, layout: layout, factory: factory)

        // Update reactions
        reconfigureReactions(message: message, bubbleWidth: bubbleWidth, theme: theme, features: features, layout: layout, factory: factory)

        // Update footer (cheap — just replace)
        if let oldFooter = footerView {
            stack.removeArrangedSubview(oldFooter)
            oldFooter.removeFromSuperview()
            footerView = nil
        }
        if !isEmojiOnly {
            if let fv = factory.footerView(message: message, theme: theme, layout: currentLayout, features: features) {
                footerView = fv
                stack.addArrangedSubview(fv)
            }
        }

        currentMessage = message
    }

    /// Checks if the structural shape of the bubble is the same (can skip full rebuild).
    private func canReconfigureInPlace(from old: ChatMessage, to new: ChatMessage, showSenderName: Bool, features: ChatFeatures) -> Bool {
        // Same message ID
        guard old.id == new.id else { return false }
        // Same media type case
        guard mediaCaseTag(old.content.content) == mediaCaseTag(new.content.content) else { return false }
        // Same text presence
        guard (old.content.text != nil) == (new.content.text != nil) else { return false }
        // Same forwarded status
        let oldFwd = features.showForwardedMark && old.forwardedFrom != nil
        let newFwd = features.showForwardedMark && new.forwardedFrom != nil
        guard oldFwd == newFwd else { return false }
        // Same reply presence
        let oldReply = features.showReplyPreview && old.reply != nil
        let newReply = features.showReplyPreview && new.reply != nil
        guard oldReply == newReply else { return false }
        // Same sender name presence
        let oldName = showSenderName && old.senderName != nil && !old.isMine
        let newName = showSenderName && new.senderName != nil && !new.isMine
        guard oldName == newName else { return false }
        // Same emoji-only status
        let oldEmoji = old.content.content == nil && EmojiHelper.emojiOnlyCount(old.content.text) != nil
        let newEmoji = new.content.content == nil && EmojiHelper.emojiOnlyCount(new.content.text) != nil
        guard oldEmoji == newEmoji else { return false }
        return true
    }

    private func mediaCaseTag(_ media: AnyChatContent?) -> String {
        media?.contentTypeID ?? ""
    }

    /// Reconfigure the content view in-place via the factory.
    private func reconfigureContentView(message: ChatMessage, width: CGFloat, isMine: Bool, theme: ChatTheme, layout: ChatLayout, factory: ChatContentFactory) {
        guard let cv = contentView else { return }
        let content = message.content

        // Ask factory to reconfigure the media view in-place
        if let media = content.content {
            let interactionHandler: (ChatContentInteraction) -> Void = { [weak self] interaction in
                self?.onContentInteraction?(interaction)
            }
            _ = factory.reconfigureContentView(cv, for: media, message: message, width: width, theme: theme, layout: layout, onInteraction: interactionHandler)
        }

        // Update text if present (standalone or mixed content with media)
        if let text = content.text, !text.isEmpty {
            if let textView = cv as? TextContentView {
                textView.configure(text: text, isMine: isMine, theme: theme, layout: layout)
            } else if let mixedStack = cv as? UIStackView {
                for sub in mixedStack.arrangedSubviews {
                    if let tv = sub as? TextContentView {
                        tv.configure(text: text, isMine: isMine, theme: theme, layout: layout)
                        break
                    }
                }
            }
        }
    }

    /// Update reactions: reconfigure existing, add if new, remove if gone.
    private func reconfigureReactions(message: ChatMessage, bubbleWidth: CGFloat, theme: ChatTheme, features: ChatFeatures, layout: ChatLayout, factory: ChatContentFactory) {
        let hasReactions = features.showReactions && !message.reactions.isEmpty

        if hasReactions {
            let maxW = bubbleWidth - currentLayout.bubbleHPad * 2
            if let rv = reactionsView as? ReactionsView {
                rv.configure(reactions: message.reactions, theme: theme, maxWidth: maxW, layout: layout)
                rv.onReactionTap = { [weak self] emoji in self?.onReactionTap?(emoji) }
            } else {
                // Reactions appeared — insert before footer
                let rv = factory.reactionsView(reactions: message.reactions, theme: theme, maxWidth: maxW, layout: layout) { [weak self] emoji in
                    self?.onReactionTap?(emoji)
                }
                let insertIndex: Int
                if let fv = footerView, let idx = stack.arrangedSubviews.firstIndex(of: fv) {
                    insertIndex = idx
                } else {
                    insertIndex = stack.arrangedSubviews.count
                }
                stack.insertArrangedSubview(rv, at: insertIndex)
                reactionsView = rv
            }
        } else if let rv = reactionsView {
            stack.removeArrangedSubview(rv)
            rv.removeFromSuperview()
            reactionsView = nil
        }
    }

    // MARK: - Reuse

    func prepareForReuse() {
        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
        contentView = nil
        reactionsView = nil
        footerView = nil
        currentMessage = nil
        onReplyTap = nil
        onContentInteraction = nil
        onReactionTap = nil
    }
}
