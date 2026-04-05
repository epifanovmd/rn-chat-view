import UIKit

public final class MessageCell: UICollectionViewCell {

    // MARK: - Callbacks

    var onTap: (() -> Void)?
    var onLongPress: ((UICollectionViewCell) -> Void)?
    var onReplyTap: (() -> Void)?
    var onContentInteraction: ((ChatContentInteraction) -> Void)?
    var onReactionTap: ((String) -> Void)?

    // MARK: - State

    private var currentTheme: ChatTheme = .light
    private var currentLayout: ChatLayout = ChatLayout()

    // MARK: - Views

    let bubbleView = MessageBubbleView()
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

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
                                                                 constant: ChatLayout().cellHMargin)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                                   constant: -ChatLayout().cellHMargin)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        bubbleView.addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = ChatLayout().longPressDuration
        bubbleView.addGestureRecognizer(longPress)
    }

    // MARK: - Configure

    func configure(message: ChatMessage, resolvedReply: ReplyDisplayInfo?, theme: ChatTheme, maxWidth: CGFloat, showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), layout: ChatLayout = ChatLayout(), factory: ChatContentFactory = DefaultChatContentFactory()) {
        currentTheme = theme
        currentLayout = layout
        leadingConstraint.constant = layout.cellHMargin
        trailingConstraint.constant = -layout.cellHMargin
        let bw = MessageSizeCalculator.bubbleWidth(for: message, containerWidth: maxWidth, layout: layout, showSenderName: showSenderName, features: features)

        leadingConstraint.isActive = false
        trailingConstraint.isActive = false

        if message.isMine {
            trailingConstraint.isActive = true
        } else {
            leadingConstraint.isActive = true
        }

        for c in bubbleView.constraints where c.firstAttribute == .width { c.isActive = false }
        let wc = bubbleView.widthAnchor.constraint(equalToConstant: bw)
        wc.priority = .defaultHigh
        wc.isActive = true

        bubbleView.configure(message: message, resolvedReply: resolvedReply, theme: theme, bubbleWidth: bw, showSenderName: showSenderName, features: features, layout: layout, factory: factory)
        bubbleView.onReplyTap = onReplyTap
        bubbleView.onContentInteraction = onContentInteraction
        bubbleView.onReactionTap = onReactionTap
    }

    // MARK: - Highlight

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

    // MARK: - Reuse

    public override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
        onLongPress = nil
        onReplyTap = nil
        onContentInteraction = nil
        onReactionTap = nil
        for c in bubbleView.constraints where c.firstAttribute == .width { c.isActive = false }
        bubbleView.prepareForReuse()
    }

    // MARK: - Gestures

    @objc private func handleTap() { onTap?() }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { onLongPress?(self) }
    }
}
