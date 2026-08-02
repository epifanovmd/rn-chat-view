import UIKit

public final class MessageBubbleView: UIView {

    // MARK: - Колбэки

    var onReplyTap: (() -> Void)?
    var onContentInteraction: ((ChatContentInteraction) -> Void)?
    var onReactionTap: ((String) -> Void)?
    var onThreadTap: (() -> Void)?
    var onLinkTap: ((URL) -> Void)?

    // MARK: - Вью

    private let stack = UIStackView()
    private var contentView: UIView?
    private var threadView: UIView?
    private var reactionsView: UIView?
    private var footerView: UIView?

    private var isEmojiOnly = false
    private var currentLayout = ChatLayout()
    private(set) var currentMessage: ChatMessage?

    // MARK: - Констрейнты

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

    // MARK: - Конфигурация

    func configure(message: ChatMessage, resolvedReply: ReplyDisplayInfo?, theme: ChatTheme, bubbleWidth: CGFloat, showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), layout: ChatLayout = ChatLayout(), factory: ChatContentFactory = DefaultChatContentFactory()) {
        applyLayout(layout)
        let ownership = message.ownership
        let content = message.content
        isEmojiOnly = Self.isBubblelessEmoji(
            message, showSenderName: showSenderName, features: features)

        if isEmojiOnly {
            backgroundColor = .clear
            layer.cornerRadius = 0
        } else {
            switch ownership {
            case .mine:   backgroundColor = theme.outgoingBubble
            case .theirs: backgroundColor = theme.incomingBubble
            case .system: backgroundColor = theme.systemBubble
            case .pinned: backgroundColor = theme.pinnedBubble
            }
            layer.cornerRadius = currentLayout.bubbleCornerRadius
        }

        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }

        if showSenderName, let name = message.senderName {
            let senderView = factory.senderNameView(name: name, theme: theme, layout: currentLayout)
            stack.addArrangedSubview(senderView)
        }

        let isForwarded = features.showForwardedMark && message.forwardedFrom != nil
        if let fwd = message.forwardedFrom, features.showForwardedMark {
            let L = currentLayout
            let accentColor = ownership == .mine ? theme.outgoingForwardedAccent : theme.incomingForwardedAccent

            let forwardedHeaderLabel = factory.forwardedHeaderView(from: fwd, ownership: message.ownership, theme: theme, layout: currentLayout)

            let forwardedAccent = UIView()
            forwardedAccent.translatesAutoresizingMaskIntoConstraints = false
            forwardedAccent.backgroundColor = accentColor
            forwardedAccent.layer.cornerRadius = L.forwardedAccentWidth / 2

            let forwardedStack = UIStackView()
            forwardedStack.axis = .vertical
            forwardedStack.spacing = L.bubbleSpacing
            forwardedStack.translatesAutoresizingMaskIntoConstraints = false

            forwardedStack.addArrangedSubview(forwardedHeaderLabel)

            if features.showReplyPreview, let reply = message.reply {
                let replyView = factory.replyPreviewView(reply: reply, resolved: resolvedReply, ownership: message.ownership, theme: theme, layout: currentLayout) { [weak self] in
                    self?.onReplyTap?()
                }
                forwardedStack.addArrangedSubview(replyView)
            }

            let contentInnerW = bubbleWidth - L.bubbleHPad * 2 - L.forwardedAccentWidth - L.forwardedContentInset
            let newContent = createContentView(for: message, width: contentInnerW, theme: theme, features: features, factory: factory)
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
            if features.showReplyPreview, let reply = message.reply {
                let replyView = factory.replyPreviewView(reply: reply, resolved: resolvedReply, ownership: message.ownership, theme: theme, layout: currentLayout) { [weak self] in
                    self?.onReplyTap?()
                }
                stack.addArrangedSubview(replyView)
            }

            let innerW = bubbleWidth - currentLayout.bubbleHPad * 2
            let newContent = createContentView(for: message, width: innerW, theme: theme, features: features, factory: factory)
            contentView = newContent
            stack.addArrangedSubview(newContent)
        }

        threadView = nil
        if features.showThreadIndicator, let thread = message.thread {
            let tv = factory.threadIndicatorView(thread: thread, ownership: message.ownership, theme: theme, layout: currentLayout) { [weak self] in
                self?.onThreadTap?()
            }
            threadView = tv
            stack.addArrangedSubview(tv)
        }

        reactionsView = nil
        if features.showReactions, !message.reactions.isEmpty {
            let maxReactionWidth = bubbleWidth - currentLayout.bubbleHPad * 2
            let rv = factory.reactionsView(reactions: message.reactions, theme: theme, maxWidth: maxReactionWidth, layout: currentLayout) { [weak self] emoji in
                self?.onReactionTap?(emoji)
            }
            reactionsView = rv
            stack.addArrangedSubview(rv)
        }

        footerView = nil
        if !isEmojiOnly {
            if let fv = factory.footerView(message: message, theme: theme, layout: currentLayout, features: features) {
                footerView = fv
                stack.addArrangedSubview(fv)
            }
        }

        currentMessage = message
    }

    /// Крупное эмодзи без фона пузыря — только когда рядом нет имени
    /// отправителя, цитаты и заголовка пересылки: им нужен контейнер.
    static func isBubblelessEmoji(_ msg: ChatMessage, showSenderName: Bool, features: ChatFeatures) -> Bool {
        guard msg.content.content == nil,
              EmojiHelper.emojiOnlyCount(msg.content.text) != nil else { return false }

        if showSenderName, msg.senderName != nil { return false }
        if features.showReplyPreview, msg.reply != nil { return false }
        if features.showForwardedMark, msg.forwardedFrom != nil { return false }

        return true
    }

    // MARK: - Фабрика контента

    private func createContentView(for msg: ChatMessage, width: CGFloat, theme: ChatTheme, features: ChatFeatures, factory: ChatContentFactory) -> UIView {
        let content = msg.content

        if content.content == nil, let count = EmojiHelper.emojiOnlyCount(content.text) {
            return factory.emojiView(text: content.text!, emojiCount: count, layout: currentLayout)
        }

        var views: [UIView] = []

        if let media = content.content {
            let mediaView = factory.contentView(for: media, message: msg, width: width, theme: theme, layout: currentLayout) { [weak self] interaction in
                self?.onContentInteraction?(interaction)
            }
            views.append(mediaView)
        }

        if let text = content.text, !text.isEmpty {
            views.append(factory.textView(text: text, ownership: msg.ownership, theme: theme, layout: currentLayout, linkDetectionEnabled: features.linkDetectionEnabled) { [weak self] url in
                self?.onLinkTap?(url)
            })
        }

        if views.count == 1 {
            return views[0]
        }

        if views.count > 1 {
            let container = UIStackView()
            container.axis = .vertical
            container.spacing = currentLayout.mixedContentSpacing
            views.forEach { container.addArrangedSubview($0) }
            return container
        }

        return factory.textView(text: "", ownership: msg.ownership, theme: theme, layout: currentLayout, linkDetectionEnabled: false, onLinkTap: nil)
    }

    // MARK: - Обновление на месте

    /// Обновляет bubble без пересоздания иерархии вью.
    /// Если структура изменилась — fallback на полный configure().
    func reconfigureInPlace(message: ChatMessage, resolvedReply: ReplyDisplayInfo?, theme: ChatTheme, bubbleWidth: CGFloat, showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), layout: ChatLayout = ChatLayout(), factory: ChatContentFactory = DefaultChatContentFactory()) {
        guard let old = currentMessage, canReconfigureInPlace(from: old, to: message, showSenderName: showSenderName, features: features) else {
            configure(message: message, resolvedReply: resolvedReply, theme: theme, bubbleWidth: bubbleWidth, showSenderName: showSenderName, features: features, layout: layout, factory: factory)
            return
        }

        applyLayout(layout)
        let content = message.content

        switch message.ownership {
        case .mine:   backgroundColor = theme.outgoingBubble
        case .theirs: backgroundColor = theme.incomingBubble
        case .system: backgroundColor = theme.systemBubble
        case .pinned: backgroundColor = theme.pinnedBubble
        }

        let isForwarded = features.showForwardedMark && message.forwardedFrom != nil
        let innerW: CGFloat
        if isForwarded {
            innerW = bubbleWidth - currentLayout.bubbleHPad * 2 - currentLayout.forwardedAccentWidth - currentLayout.forwardedContentInset
        } else {
            innerW = bubbleWidth - currentLayout.bubbleHPad * 2
        }
        reconfigureContentView(message: message, width: innerW, theme: theme, layout: layout, features: features, factory: factory)

        reconfigureReactions(message: message, bubbleWidth: bubbleWidth, theme: theme, features: features, layout: layout, factory: factory)

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

    /// Структурный отпечаток bubble — всё, что влияет на иерархию вью.
    /// Одинаковый отпечаток = можно обновить на месте. Разный = полная пересборка.
    private struct BubbleStructure: Equatable {
        let messageId: String
        let contentTypeID: String   // "" if no content
        let hasText: Bool
        let isForwarded: Bool
        let hasReply: Bool
        let hasSenderName: Bool
        let hasThread: Bool
        let isEmojiOnly: Bool
    }

    private func bubbleStructure(for msg: ChatMessage, showSenderName: Bool, features: ChatFeatures) -> BubbleStructure {
        BubbleStructure(
            messageId: msg.id,
            contentTypeID: msg.content.content?.contentTypeID ?? "",
            hasText: msg.content.text != nil,
            isForwarded: features.showForwardedMark && msg.forwardedFrom != nil,
            hasReply: features.showReplyPreview && msg.reply != nil,
            hasSenderName: showSenderName && msg.senderName != nil,
            hasThread: features.showThreadIndicator && msg.thread != nil,
            isEmojiOnly: Self.isBubblelessEmoji(msg, showSenderName: showSenderName, features: features)
        )
    }

    private func canReconfigureInPlace(from old: ChatMessage, to new: ChatMessage, showSenderName: Bool, features: ChatFeatures) -> Bool {
        bubbleStructure(for: old, showSenderName: showSenderName, features: features) ==
        bubbleStructure(for: new, showSenderName: showSenderName, features: features)
    }

    private func reconfigureContentView(message: ChatMessage, width: CGFloat, theme: ChatTheme, layout: ChatLayout, features: ChatFeatures, factory: ChatContentFactory) {
        guard let cv = contentView else { return }
        let content = message.content

        if let media = content.content {
            let interactionHandler: (ChatContentInteraction) -> Void = { [weak self] interaction in
                self?.onContentInteraction?(interaction)
            }
            _ = factory.reconfigureContentView(cv, for: media, message: message, width: width, theme: theme, layout: layout, onInteraction: interactionHandler)
        }

        if let text = content.text, !text.isEmpty {
            if let textView = cv as? TextContentView {
                textView.configure(text: text, ownership: message.ownership, theme: theme, layout: layout, linkDetectionEnabled: features.linkDetectionEnabled)
                textView.onLinkTap = { [weak self] url in self?.onLinkTap?(url) }
            } else if let mixedStack = cv as? UIStackView {
                for sub in mixedStack.arrangedSubviews {
                    if let tv = sub as? TextContentView {
                        tv.configure(text: text, ownership: message.ownership, theme: theme, layout: layout, linkDetectionEnabled: features.linkDetectionEnabled)
                        tv.onLinkTap = { [weak self] url in self?.onLinkTap?(url) }
                        break
                    }
                }
            }
        }
    }

    private func reconfigureReactions(message: ChatMessage, bubbleWidth: CGFloat, theme: ChatTheme, features: ChatFeatures, layout: ChatLayout, factory: ChatContentFactory) {
        let hasReactions = features.showReactions && !message.reactions.isEmpty

        if hasReactions {
            let maxW = bubbleWidth - currentLayout.bubbleHPad * 2
            if let rv = reactionsView as? ReactionsView {
                rv.configure(reactions: message.reactions, theme: theme, maxWidth: maxW, layout: layout)
                rv.onReactionTap = { [weak self] emoji in self?.onReactionTap?(emoji) }
            } else {
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

    // MARK: - Переиспользование

    func prepareForReuse() {
        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
        contentView = nil
        threadView = nil
        reactionsView = nil
        footerView = nil
        currentMessage = nil
        onReplyTap = nil
        onContentInteraction = nil
        onReactionTap = nil
        onThreadTap = nil
        onLinkTap = nil
    }
}
