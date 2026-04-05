import UIKit

/// Default implementation of ChatContentFactory.
/// Handles built-in media types: images, voice, poll, files.
/// Subclass and override specific methods for customization.
open class DefaultChatContentFactory: ChatContentFactory {

    public init() {}

    // MARK: - Media Content

    open func contentView(
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        let isMine = message.isMine

        if let images = media.content(as: ImagesContent.self) {
            let grid = MediaGridView()
            grid.configure(media: images.items, width: width, theme: theme, layout: layout)
            grid.onItemTap = { index in onInteraction(.mediaTap(index: index)) }
            return grid
        }

        if let voice = media.content(as: VoicePayload.self) {
            let view = VoiceContentView()
            view.configure(voice: voice, isMine: isMine, theme: theme, layout: layout)
            view.onPlayTap = { onInteraction(.voiceTap(url: voice.url)) }
            return view
        }

        if let poll = media.content(as: PollPayload.self) {
            let view = PollContentView()
            view.configure(poll: poll, isMine: isMine, theme: theme, layout: layout)
            view.onOptionTap = { optionId in onInteraction(.pollOptionTap(pollId: poll.id, optionId: optionId)) }
            view.onDetailTap = { onInteraction(.pollDetailTap(pollId: poll.id)) }
            return view
        }

        if let files = media.content(as: FilesContent.self) {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = layout.fileRowSpacing
            for (i, file) in files.items.enumerated() {
                let view = FileContentView()
                view.configure(file: file, isMine: isMine, theme: theme, layout: layout)
                view.onTap = { onInteraction(.fileTap(index: i)) }
                stack.addArrangedSubview(view)
            }
            return stack
        }

        // Fallback for unknown types
        let label = UILabel()
        label.text = "[\(media.contentTypeID)]"
        label.font = layout.messageFont
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }

    open func contentHeight(
        for media: AnyChatContent,
        width: CGFloat,
        layout L: ChatLayout
    ) -> CGFloat {
        if let images = media.content(as: ImagesContent.self) {
            return MediaGridView.gridHeight(for: images.items, width: width, layout: L)
        }
        if media.content(as: VoicePayload.self) != nil {
            return L.voicePlaySize + 12 // 8pt top + 4pt bottom internal padding
        }
        if let poll = media.content(as: PollPayload.self) {
            return pollHeight(poll, width: width, layout: L)
        }
        if let files = media.content(as: FilesContent.self) {
            let rowH = L.fileIconSize + L.filePadding * 2
            return rowH * CGFloat(files.items.count) + L.fileRowSpacing * CGFloat(max(0, files.items.count - 1))
        }
        return L.messageFont.lineHeight + L.bubbleVPad * 2
    }

    open func reconfigureContentView(
        _ view: UIView,
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> Bool {
        let isMine = message.isMine

        if let poll = media.content(as: PollPayload.self), let pollView = view as? PollContentView {
            pollView.configure(poll: poll, isMine: isMine, theme: theme, layout: layout)
            pollView.onOptionTap = { optionId in onInteraction(.pollOptionTap(pollId: poll.id, optionId: optionId)) }
            pollView.onDetailTap = { onInteraction(.pollDetailTap(pollId: poll.id)) }
            return true
        }
        if let voice = media.content(as: VoicePayload.self), let voiceView = view as? VoiceContentView {
            voiceView.configure(voice: voice, isMine: isMine, theme: theme, layout: layout)
            voiceView.onPlayTap = { onInteraction(.voiceTap(url: voice.url)) }
            return true
        }
        if let images = media.content(as: ImagesContent.self), let gridView = view as? MediaGridView {
            gridView.configure(media: images.items, width: width, theme: theme, layout: layout)
            gridView.onItemTap = { index in onInteraction(.mediaTap(index: index)) }
            return true
        }
        if let files = media.content(as: FilesContent.self), let filesStack = view as? UIStackView {
            for (i, sub) in filesStack.arrangedSubviews.enumerated() {
                if let fileView = sub as? FileContentView, i < files.items.count {
                    fileView.configure(file: files.items[i], isMine: isMine, theme: theme, layout: layout)
                    fileView.onTap = { onInteraction(.fileTap(index: i)) }
                }
            }
            return true
        }
        return false
    }


    private func pollHeight(_ poll: PollPayload, width: CGFloat, layout L: ChatLayout) -> CGFloat {
        let count = poll.options.count
        var h: CGFloat = ChatTextMeasurer.height(poll.question, font: L.pollQuestionFont, width: width)
        h += L.bubbleSpacing + L.pollSubtitleFont.lineHeight
        h += L.pollHeaderSpacing
        h += CGFloat(count) * L.pollBarHeight + CGFloat(max(0, count - 1)) * L.pollOptionSpacing
        h += L.pollHeaderSpacing + L.pollVotesFont.lineHeight
        return h
    }

    // MARK: - Text

    open func textView(
        text: String,
        isMine: Bool,
        theme: ChatTheme,
        layout: ChatLayout
    ) -> UIView {
        let view = TextContentView()
        view.configure(text: text, isMine: isMine, theme: theme, layout: layout)
        return view
    }

    open func textHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        ChatTextMeasurer.height(text, font: font, width: width)
    }

    // MARK: - Emoji

    open func emojiView(text: String, emojiCount: Int, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = ChatTextMeasurer.emojiFont(for: emojiCount, layout: layout)
        label.textAlignment = .center
        return label
    }

    // MARK: - Reactions

    open func reactionsView(
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

    open func replyPreviewView(
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

    open func footerView(
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

    open func senderNameView(name: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.font = layout.senderNameFont
        label.numberOfLines = 1
        label.text = name
        label.textColor = theme.incomingSenderName
        return label
    }

    // MARK: - Forwarded Header

    open func forwardedHeaderView(from: String, isMine: Bool, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.font = layout.forwardedFont
        label.numberOfLines = 1
        label.text = "Переслано от \(from)"
        label.textColor = isMine ? theme.outgoingForwardedLabel : theme.incomingForwardedLabel
        return label
    }

    // MARK: - Date Separator

    open func dateSeparatorView(title: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
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

    open func dateSeparatorHeight(layout: ChatLayout) -> CGFloat {
        layout.dateSeparatorFont.lineHeight + layout.dateSeparatorVPad * 2
    }

    // MARK: - Floating Date

    open func floatingDateView(title: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        dateSeparatorView(title: title, theme: theme, layout: layout)
    }

    // MARK: - Empty State

    open func emptyStateView(theme: ChatTheme, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.text = NSLocalizedString("chat.empty", value: "Сообщений пока нет.\nНапишите первым!", comment: "")
        label.font = layout.emptyStateFont
        label.textColor = theme.emptyStateText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    open func emptyStateLoadingView(theme: ChatTheme, layout: ChatLayout) -> UIView {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        return spinner
    }

    // MARK: - Loading Indicator

    open func loadingIndicatorView(theme: ChatTheme, layout: ChatLayout) -> UIView {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        return spinner
    }

    // MARK: - FAB

    open func fabView(theme: ChatTheme, layout: ChatLayout) -> UIView {
        let size = layout.inputButtonSize
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = size / 2
        button.layer.borderWidth = layout.inputBorderWidth
        button.backgroundColor = theme.fabBackground
        button.layer.borderColor = theme.fabBorder.cgColor

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let arrow = UIImageView(image: UIImage(systemName: "chevron.down", withConfiguration: config))
        arrow.contentMode = .scaleAspectFit
        arrow.tintColor = theme.fabArrowColor
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.isUserInteractionEnabled = false
        button.addSubview(arrow)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size),
            arrow.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])

        return button
    }

    open func fabBadgeView(theme: ChatTheme, layout: ChatLayout) -> UIView {
        let badge = PaddedLabel(hPad: 6)
        badge.font = layout.fabBadgeFont
        badge.textAlignment = .center
        badge.layer.cornerRadius = layout.fabBadgeCornerRadius
        badge.layer.masksToBounds = true
        badge.backgroundColor = theme.fabBadgeBackground
        badge.textColor = theme.fabBadgeTextColor
        return badge
    }
}
