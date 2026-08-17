import UIKit

public final class ReplyPreviewView: UIView {
    var onTap: (() -> Void)?

    private let accentBar = UIView()
    private let senderLabel = UILabel()
    private let contentLabel = UILabel()
    private var heightConstraint: NSLayoutConstraint!

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        clipsToBounds = true

        accentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)

        senderLabel.numberOfLines = 1
        senderLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(senderLabel)

        contentLabel.numberOfLines = 1
        contentLabel.lineBreakMode = .byTruncatingTail
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentLabel)

        heightConstraint = heightAnchor.constraint(equalToConstant: ChatLayout.shared.replyHeight)

        NSLayoutConstraint.activate([
            heightConstraint,
            accentBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: topAnchor),
            accentBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentBar.widthAnchor.constraint(equalToConstant: ChatLayout.shared.replyAccentWidth),
            senderLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 8),
            senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            senderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            contentLabel.leadingAnchor.constraint(equalTo: senderLabel.leadingAnchor),
            contentLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 1),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])

        applyLayout(ChatLayout.shared)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    private func applyLayout(_ L: ChatLayout) {
        layer.cornerRadius = L.replyCornerRadius
        heightConstraint.constant = L.replyHeight
        senderLabel.font = L.replySenderFont
        contentLabel.font = L.replyFont
    }

    /// Строки, которые реально попадают в цитату. Используются и при отрисовке,
    /// и при расчёте ширины пузыря — иначе размер считается по одному тексту,
    /// а показывается другой, и цитата обрезается.
    public static func senderText(reply: ReplyInfo, resolved: ReplyDisplayInfo?) -> String {
        resolved?.senderName ?? reply.senderName ?? ""
    }

    public static func contentText(reply: ReplyInfo, resolved: ReplyDisplayInfo?) -> String {
        if let text = resolved?.text ?? reply.text, !text.isEmpty {
            return text
        }
        if reply.hasImage || (resolved?.hasImage == true) {
            return "📷 Photo"
        }
        return "…"
    }

    func configure(reply: ReplyInfo, resolved: ReplyDisplayInfo?, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout = ChatLayout.shared) {
        applyLayout(layout)
        let isOutgoing = ownership == .mine
        backgroundColor = isOutgoing ? theme.outgoingReplyBackground : theme.incomingReplyBackground
        accentBar.backgroundColor = isOutgoing ? theme.outgoingReplyAccent : theme.incomingReplyAccent

        senderLabel.text = Self.senderText(reply: reply, resolved: resolved)
        senderLabel.textColor = isOutgoing ? theme.outgoingReplySender : theme.incomingReplySender

        contentLabel.text = Self.contentText(reply: reply, resolved: resolved)
        contentLabel.textColor = isOutgoing ? theme.outgoingReplyText : theme.incomingReplyText
    }

    @objc private func tapped() { onTap?() }
}
