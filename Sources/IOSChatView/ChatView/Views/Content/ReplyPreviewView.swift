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

        heightConstraint = heightAnchor.constraint(equalToConstant: ChatLayout().replyHeight)

        NSLayoutConstraint.activate([
            heightConstraint,
            accentBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: topAnchor),
            accentBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentBar.widthAnchor.constraint(equalToConstant: ChatLayout().replyAccentWidth),
            senderLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 8),
            senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            senderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            contentLabel.leadingAnchor.constraint(equalTo: senderLabel.leadingAnchor),
            contentLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 1),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])

        applyLayout(ChatLayout())

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    private func applyLayout(_ L: ChatLayout) {
        layer.cornerRadius = L.replyCornerRadius
        heightConstraint.constant = L.replyHeight
        senderLabel.font = L.replySenderFont
        contentLabel.font = L.replyFont
    }

    func configure(reply: ReplyInfo, resolved: ReplyDisplayInfo?, isMine: Bool, theme: ChatTheme, layout: ChatLayout = ChatLayout()) {
        applyLayout(layout)
        backgroundColor = isMine ? theme.outgoingReplyBackground : theme.incomingReplyBackground
        accentBar.backgroundColor = isMine ? theme.outgoingReplyAccent : theme.incomingReplyAccent

        let sender = resolved?.senderName ?? reply.senderName ?? ""
        senderLabel.text = sender
        senderLabel.textColor = isMine ? theme.outgoingReplySender : theme.incomingReplySender

        if let text = resolved?.text ?? reply.text, !text.isEmpty {
            contentLabel.text = text
        } else if reply.hasImage || (resolved?.hasImage == true) {
            contentLabel.text = "📷 Photo"
        } else {
            contentLabel.text = "…"
        }
        contentLabel.textColor = isMine ? theme.outgoingReplyText : theme.incomingReplyText
    }

    @objc private func tapped() { onTap?() }
}
