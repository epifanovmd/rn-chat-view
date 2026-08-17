import UIKit

public final class MessageCell: UICollectionViewCell {
    public static let reuseID = "MessageCell"

    // MARK: - Колбэки

    var onTap: (() -> Void)?
    var onLongPress: ((UICollectionViewCell) -> Void)?
    var onReplyTap: (() -> Void)?
    var onContentInteraction: ((ChatContentInteraction) -> Void)?
    var onReactionTap: ((String) -> Void)?
    var onThreadTap: (() -> Void)?
    var onLinkTap: ((URL) -> Void)?

    // MARK: - Состояние

    private var currentTheme: ChatTheme = .light
    private var currentLayout: ChatLayout = ChatLayout.shared

    // MARK: - Вью

    let bubbleView = MessageBubbleView()
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var centerXConstraint: NSLayoutConstraint!
    private var widthConstraint: NSLayoutConstraint!

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                                 constant: ChatLayout.shared.cellHMargin)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                                   constant: -ChatLayout.shared.cellHMargin)
        centerXConstraint = bubbleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)

        // Один постоянный констрейнт ширины — constant мутируется при конфигурации,
        // пересоздание NSLayoutConstraint на каждый dequeue слишком дорого.
        widthConstraint = bubbleView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            widthConstraint,
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        bubbleView.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = ChatLayout.shared.longPressDuration
        bubbleView.addGestureRecognizer(longPress)
    }

    // MARK: - Конфигурация

    func configure(message: ChatMessage, resolvedReply: ReplyDisplayInfo?, theme: ChatTheme, maxWidth: CGFloat, showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), layout: ChatLayout = ChatLayout.shared, factory: ChatContentFactory = DefaultChatContentFactory(), bubbleWidth: CGFloat? = nil) {
        currentTheme = theme
        currentLayout = layout
        let avatarSpace: CGFloat = (features.showAvatars && message.ownership == .theirs)
            ? layout.avatarSize + layout.avatarLeadingMargin + layout.avatarBubbleSpacing
            : 0
        leadingConstraint.constant = layout.cellHMargin + avatarSpace
        trailingConstraint.constant = -layout.cellHMargin
        let bw = bubbleWidth ?? MessageSizeCalculator.bubbleWidth(for: message, containerWidth: maxWidth, layout: layout, showSenderName: showSenderName, features: features, factory: factory, resolvedReply: resolvedReply)

        leadingConstraint.isActive = false
        trailingConstraint.isActive = false
        centerXConstraint.isActive = false

        switch message.ownership.alignment {
        case .trailing:
            trailingConstraint.isActive = true
        case .leading:
            leadingConstraint.isActive = true
        case .center:
            centerXConstraint.isActive = true
        }

        if widthConstraint.constant != bw { widthConstraint.constant = bw }

        bubbleView.configure(message: message, resolvedReply: resolvedReply, theme: theme, bubbleWidth: bw, showSenderName: showSenderName, features: features, layout: layout, factory: factory)
        bubbleView.onReplyTap = onReplyTap
        bubbleView.onContentInteraction = onContentInteraction
        bubbleView.onReactionTap = onReactionTap
        bubbleView.onThreadTap = onThreadTap
        bubbleView.onLinkTap = onLinkTap
    }

    // MARK: - Обновление на месте

    func reconfigureInPlace(message: ChatMessage, resolvedReply: ReplyDisplayInfo?, theme: ChatTheme, maxWidth: CGFloat, showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), layout: ChatLayout = ChatLayout.shared, factory: ChatContentFactory = DefaultChatContentFactory(), bubbleWidth: CGFloat? = nil) {
        currentTheme = theme
        currentLayout = layout

        let bw = bubbleWidth ?? MessageSizeCalculator.bubbleWidth(for: message, containerWidth: maxWidth, layout: layout, showSenderName: showSenderName, features: features, factory: factory, resolvedReply: resolvedReply)

        if widthConstraint.constant != bw { widthConstraint.constant = bw }

        bubbleView.reconfigureInPlace(message: message, resolvedReply: resolvedReply, theme: theme, bubbleWidth: bw, showSenderName: showSenderName, features: features, layout: layout, factory: factory)
        bubbleView.onReplyTap = onReplyTap
        bubbleView.onContentInteraction = onContentInteraction
        bubbleView.onReactionTap = onReactionTap
        bubbleView.onThreadTap = onThreadTap
        bubbleView.onLinkTap = onLinkTap
    }

    // MARK: - Подсветка

    func playHighlight() {
        let overlay = UIView(frame: bubbleView.bounds)
        overlay.backgroundColor = currentTheme.messageHighlightColor
        overlay.layer.cornerRadius = currentLayout.bubbleCornerRadius
        overlay.alpha = 0
        bubbleView.addSubview(overlay)
        let L = currentLayout
        UIView.animate(withDuration: L.highlightAnimateIn, animations: { overlay.alpha = 1 }) { _ in
            UIView.animate(withDuration: L.highlightAnimateOut, delay: L.highlightDelay, animations: { overlay.alpha = 0 }) { _ in
                overlay.removeFromSuperview()
            }
        }
    }

    // MARK: - Переиспользование

    public override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
        onLongPress = nil
        onReplyTap = nil
        onContentInteraction = nil
        onReactionTap = nil
        onThreadTap = nil
        onLinkTap = nil
        bubbleView.prepareForReuse()
    }

    // MARK: - Жесты

    @objc private func handleTap() { onTap?() }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { onLongPress?(self) }
    }
}
