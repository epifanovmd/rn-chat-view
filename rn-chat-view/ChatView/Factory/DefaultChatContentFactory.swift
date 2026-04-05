import UIKit

/// Default implementation of ChatContentFactory.
/// Subclass and override specific methods for customization.
class DefaultChatContentFactory: ChatContentFactory {

    // MARK: - Media Content

    func contentView(
        for media: MessageMedia,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        let isMine = message.isMine
        switch media {
        case .images(let items):
            let grid = MediaGridView()
            grid.configure(media: items, width: width, theme: theme, layout: layout)
            grid.onItemTap = { index in onInteraction(.mediaTap(index: index)) }
            return grid

        case .voice(let payload):
            let view = VoiceContentView()
            view.configure(voice: payload, isMine: isMine, theme: theme, layout: layout)
            view.onPlayTap = { onInteraction(.voiceTap(url: payload.url)) }
            return view

        case .poll(let payload):
            let view = PollContentView()
            view.configure(poll: payload, isMine: isMine, theme: theme, layout: layout)
            view.onOptionTap = { optionId in onInteraction(.pollOptionTap(pollId: payload.id, optionId: optionId)) }
            view.onDetailTap = { onInteraction(.pollDetailTap(pollId: payload.id)) }
            return view

        case .files(let items):
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = layout.fileRowSpacing
            for (i, file) in items.enumerated() {
                let view = FileContentView()
                view.configure(file: file, isMine: isMine, theme: theme, layout: layout)
                view.onTap = { onInteraction(.fileTap(index: i)) }
                stack.addArrangedSubview(view)
            }
            return stack

        case .custom(let type, _):
            let label = UILabel()
            label.text = "[\(type)]"
            label.font = layout.messageFont
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            return label
        }
    }

    func contentHeight(
        for media: MessageMedia,
        width: CGFloat,
        layout L: ChatLayout
    ) -> CGFloat {
        switch media {
        case .images(let items):
            return MediaGridView.gridHeight(for: items, width: width, layout: L)
        case .voice:
            return L.voicePlaySize
        case .poll(let p):
            return MessageSizeCalculator.pollHeight(p, width: width, layout: L)
        case .files(let items):
            let rowH = L.fileIconSize + L.filePadding * 2
            return rowH * CGFloat(items.count) + L.fileRowSpacing * CGFloat(max(0, items.count - 1))
        case .custom:
            return L.messageFont.lineHeight + L.bubbleVPad * 2
        }
    }

    // MARK: - Text

    func textView(
        text: String,
        isMine: Bool,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView {
        let view = TextContentView()
        view.configure(text: text, isMine: isMine, theme: theme, layout: layout)
        return view
    }

    func textHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        MessageSizeCalculator.textHeight(text, font: font, width: width)
    }

    // MARK: - Emoji

    func emojiView(text: String, emojiCount: Int, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = MessageSizeCalculator.emojiFont(for: emojiCount, layout: layout)
        label.textAlignment = .center
        return label
    }

    // MARK: - Reactions

    func reactionsView(
        reactions: [Reaction],
        theme: ChatTheme,
        maxWidth: CGFloat,
        layout: ChatLayout,
        onTap: @escaping (String) -> Void
    ) -> UIView {
        let view = ReactionsView()
        view.configure(reactions: reactions, theme: theme, maxWidth: maxWidth, layout: layout)
        view.onReactionTap = onTap
        return view
    }

    // MARK: - Reply Preview

    func replyPreviewView(
        reply: ReplyInfo,
        resolved: ReplyDisplayInfo?,
        isMine: Bool,
        theme: ChatTheme,
        layout: ChatLayout,
        onTap: @escaping () -> Void
    ) -> UIView {
        let view = ReplyPreviewView()
        view.configure(reply: reply, resolved: resolved, isMine: isMine, theme: theme, layout: layout)
        view.onTap = onTap
        return view
    }

    // MARK: - Footer

    func footerView(
        message: ChatMessage,
        theme: ChatTheme,
        layout: ChatLayout,
        features: ChatFeatures
    ) -> UIView? {
        let isMine = message.isMine
        let hasFooter = features.showTimestamp
            || (message.isEdited && features.showEditedMark)
            || (isMine && features.showMessageStatus)
        guard hasFooter else { return nil }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = layout.footerSpacing
        stack.alignment = .center

        // Edited
        let editedLabel = UILabel()
        editedLabel.font = layout.editedFont
        editedLabel.text = "изм."
        editedLabel.textColor = isMine ? theme.outgoingEdited : theme.incomingEdited
        editedLabel.isHidden = !message.isEdited || !features.showEditedMark
        stack.addArrangedSubview(editedLabel)

        // Time
        let timeLabel = UILabel()
        timeLabel.font = layout.timeFont
        timeLabel.text = DateHelper.shared.timeString(from: message.timestamp)
        timeLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
        timeLabel.isHidden = !features.showTimestamp
        stack.addArrangedSubview(timeLabel)

        // Status
        let statusView = MessageStatusView()
        statusView.configure(status: message.status, isMine: isMine, theme: theme)
        statusView.isHidden = !isMine || !features.showMessageStatus
        statusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusView.widthAnchor.constraint(equalToConstant: layout.statusIconSize),
            statusView.heightAnchor.constraint(equalToConstant: layout.statusIconSize),
        ])
        stack.addArrangedSubview(statusView)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: layout.footerHeight),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    // MARK: - Sender Name

    func senderNameView(name: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.font = layout.senderNameFont
        label.numberOfLines = 1
        label.text = name
        label.textColor = theme.incomingSenderName
        return label
    }

    // MARK: - Forwarded Header

    func forwardedHeaderView(from: String, isMine: Bool, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.font = layout.forwardedFont
        label.numberOfLines = 1
        label.text = "Переслано от \(from)"
        label.textColor = isMine ? theme.outgoingForwardedLabel : theme.incomingForwardedLabel
        return label
    }

    // MARK: - Date Separator

    func dateSeparatorView(title: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let pill = UIView()
        pill.backgroundColor = theme.dateSeparatorBackground
        pill.layer.cornerRadius = layout.dateSeparatorCornerRadius

        let label = UILabel()
        label.text = title
        label.font = layout.dateSeparatorFont
        label.textColor = theme.dateSeparatorText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: layout.dateSeparatorVPad),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -layout.dateSeparatorVPad),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: layout.dateSeparatorHPad),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -layout.dateSeparatorHPad),
        ])

        return pill
    }

    func dateSeparatorHeight(layout: ChatLayout) -> CGFloat {
        layout.dateSeparatorFont.lineHeight + layout.dateSeparatorVPad * 2
    }

    // MARK: - Floating Date

    func floatingDateView(title: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        dateSeparatorView(title: title, theme: theme, layout: layout)
    }
}
