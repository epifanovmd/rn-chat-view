import UIKit

final class ReplyPreviewView: UIView {
    var onTap: (() -> Void)?

    private let accentBar = UIView()
    private let senderLabel = UILabel()
    private let contentLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        layer.cornerRadius = ChatLayout.current.replyCornerRadius
        clipsToBounds = true

        accentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)

        senderLabel.font = ChatLayout.current.replySenderFont
        senderLabel.numberOfLines = 1
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(senderLabel)

        contentLabel.font = ChatLayout.current.replyFont
        contentLabel.numberOfLines = 1
        contentLabel.lineBreakMode = .byTruncatingTail
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ChatLayout.current.replyHeight),
            accentBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: topAnchor),
            accentBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentBar.widthAnchor.constraint(equalToConstant: ChatLayout.current.replyAccentWidth),
            senderLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 8),
            senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            senderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            contentLabel.leadingAnchor.constraint(equalTo: senderLabel.leadingAnchor),
            contentLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 1),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    func configure(reply: ReplyInfo, resolved: ReplyDisplayInfo?, isMine: Bool, theme: ChatTheme) {
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

    /// Configure from snapshot data (for input bar reply panel)
    func configureFromSnapshot(senderName: String?, text: String?, hasImage: Bool, isMine: Bool, theme: ChatTheme) {
        backgroundColor = theme.replyPanelBackground
        accentBar.backgroundColor = theme.replyPanelAccent
        senderLabel.text = senderName ?? ""
        senderLabel.textColor = theme.replyPanelSender

        if let text, !text.isEmpty {
            contentLabel.text = text
        } else if hasImage {
            contentLabel.text = "📷 Photo"
        } else {
            contentLabel.text = "…"
        }
        contentLabel.textColor = theme.replyPanelText
    }

    @objc private func tapped() { onTap?() }
}
