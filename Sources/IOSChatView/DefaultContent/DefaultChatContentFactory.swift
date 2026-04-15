import UIKit

open class DefaultChatContentFactory: ChatContentFactory {

    public init() {}

    // MARK: - Медиа контент

    open func contentView(
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        let ownership = message.ownership

        if let images = media.content(as: ImagesContent.self) {
            let grid = MediaGridView()
            grid.configure(media: images.items, width: width, theme: theme, layout: layout)
            grid.onItemTap = { index in onInteraction(.mediaTap(index: index)) }
            return grid
        }

        if let voice = media.content(as: VoicePayload.self) {
            let view = VoiceContentView()
            view.configure(voice: voice, ownership: ownership, theme: theme, layout: layout)
            view.onPlayTap = { onInteraction(.voiceTap(url: voice.url)) }
            return view
        }

        if let poll = media.content(as: PollPayload.self) {
            let view = PollContentView()
            view.configure(poll: poll, ownership: ownership, theme: theme, layout: layout)
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
                view.configure(file: file, ownership: ownership, theme: theme, layout: layout)
                view.onTap = { onInteraction(.fileTap(index: i)) }
                stack.addArrangedSubview(view)
            }
            return stack
        }

        // Заглушка для неизвестных типов контента
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
        let ownership = message.ownership

        if let poll = media.content(as: PollPayload.self), let pollView = view as? PollContentView {
            pollView.configure(poll: poll, ownership: ownership, theme: theme, layout: layout)
            pollView.onOptionTap = { optionId in onInteraction(.pollOptionTap(pollId: poll.id, optionId: optionId)) }
            pollView.onDetailTap = { onInteraction(.pollDetailTap(pollId: poll.id)) }
            return true
        }
        if let voice = media.content(as: VoicePayload.self), let voiceView = view as? VoiceContentView {
            voiceView.configure(voice: voice, ownership: ownership, theme: theme, layout: layout)
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
                    fileView.configure(file: files.items[i], ownership: ownership, theme: theme, layout: layout)
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

    // MARK: - Текст

    open func textView(
        text: String,
        ownership: MessageOwnership,
        theme: ChatTheme,
        layout: ChatLayout,
        linkDetectionEnabled: Bool,
        onLinkTap: ((URL) -> Void)?
    ) -> UIView {
        let view = TextContentView()
        view.configure(text: text, ownership: ownership, theme: theme, layout: layout, linkDetectionEnabled: linkDetectionEnabled)
        view.onLinkTap = onLinkTap
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

    // MARK: - Реакции

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

    // MARK: - Индикатор треда

    open func threadIndicatorView(
        thread: ThreadInfo,
        ownership: MessageOwnership,
        theme: ChatTheme,
        layout: ChatLayout,
        onTap: @escaping () -> Void
    ) -> UIView {
        let L = layout
        let container = UIView()

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = L.threadBarSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconConfig = UIImage.SymbolConfiguration(pointSize: L.threadBarIconSize, weight: .medium)
        let icon = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right", withConfiguration: iconConfig))
        icon.tintColor = theme.threadBarIcon
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: L.threadBarIconSize),
            icon.heightAnchor.constraint(equalToConstant: L.threadBarIconSize),
        ])
        stack.addArrangedSubview(icon)

        let countLabel = UILabel()
        countLabel.text = Self.threadReplySuffix(thread.replyCount)
        countLabel.font = L.threadBarFont
        countLabel.textColor = theme.threadBarText
        stack.addArrangedSubview(countLabel)

        if let name = thread.lastReplierName {
            let dot = UILabel()
            dot.text = "·"
            dot.font = L.threadBarFont
            dot.textColor = theme.threadBarText.withAlphaComponent(0.5)
            stack.addArrangedSubview(dot)

            let nameLabel = UILabel()
            nameLabel.text = name
            nameLabel.font = L.threadBarFont
            nameLabel.textColor = theme.threadBarText.withAlphaComponent(0.7)
            nameLabel.lineBreakMode = .byTruncatingTail
            stack.addArrangedSubview(nameLabel)
        }

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: L.threadBarChevronSize, weight: .semibold)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: chevronConfig))
        chevron.tintColor = theme.threadBarText.withAlphaComponent(0.4)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chevron.widthAnchor.constraint(equalToConstant: L.threadBarChevronSize),
            chevron.heightAnchor.constraint(equalToConstant: L.threadBarChevronSize),
        ])
        stack.addArrangedSubview(chevron)

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: L.threadBarHeight),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        let target = ThreadTapTarget(action: onTap)
        let tap = UITapGestureRecognizer(target: target, action: #selector(ThreadTapTarget.handleTap))
        container.addGestureRecognizer(tap)
        objc_setAssociatedObject(container, &ThreadTapTarget.key, target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return container
    }

    private static func threadReplySuffix(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 19 { return "\(count) ответов" }
        if mod10 == 1 { return "\(count) ответ" }
        if mod10 >= 2 && mod10 <= 4 { return "\(count) ответа" }
        return "\(count) ответов"
    }

    // MARK: - Превью ответа

    open func replyPreviewView(
        reply: ReplyInfo,
        resolved: ReplyDisplayInfo?,
        ownership: MessageOwnership,
        theme: ChatTheme,
        layout: ChatLayout,
        onTap: @escaping () -> Void
    ) -> UIView {
        let view = ReplyPreviewView()
        view.configure(reply: reply, resolved: resolved, ownership: ownership, theme: theme, layout: layout)
        view.onTap = onTap
        return view
    }

    // MARK: - Подвал сообщения

    open func footerView(
        message: ChatMessage,
        theme: ChatTheme,
        layout: ChatLayout,
        features: ChatFeatures
    ) -> UIView? {
        let ownership = message.ownership
        let isOutgoing = ownership == .mine
        let hasFooter = features.showTimestamp
            || (message.isEdited && features.showEditedMark)
            || (isOutgoing && features.showMessageStatus)
        guard hasFooter else { return nil }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = layout.footerSpacing
        stack.alignment = .center

        let editedLabel = UILabel()
        editedLabel.font = layout.editedFont
        editedLabel.text = "изм."
        switch ownership {
        case .mine:           editedLabel.textColor = theme.outgoingEdited
        case .theirs:         editedLabel.textColor = theme.incomingEdited
        case .system:         editedLabel.textColor = theme.systemTime
        case .pinned:         editedLabel.textColor = theme.pinnedTime
        }
        editedLabel.isHidden = !message.isEdited || !features.showEditedMark
        stack.addArrangedSubview(editedLabel)

        let timeLabel = UILabel()
        timeLabel.font = layout.timeFont
        timeLabel.text = DateHelper.shared.timeString(from: message.timestamp)
        switch ownership {
        case .mine:           timeLabel.textColor = theme.outgoingTime
        case .theirs:         timeLabel.textColor = theme.incomingTime
        case .system:         timeLabel.textColor = theme.systemTime
        case .pinned:         timeLabel.textColor = theme.pinnedTime
        }
        timeLabel.isHidden = !features.showTimestamp
        stack.addArrangedSubview(timeLabel)

        let statusView = MessageStatusView()
        statusView.configure(status: message.status, ownership: ownership, theme: theme)
        statusView.isHidden = !isOutgoing || !features.showMessageStatus
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

    // MARK: - Имя отправителя

    open func senderNameView(name: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.font = layout.senderNameFont
        label.numberOfLines = 1
        label.text = name
        label.textColor = theme.incomingSenderName
        return label
    }

    // MARK: - Заголовок пересылки

    open func forwardedHeaderView(from: String, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let label = UILabel()
        label.font = layout.forwardedFont
        label.numberOfLines = 1
        label.text = "Переслано от \(from)"
        label.textColor = ownership == .mine ? theme.outgoingForwardedLabel : theme.incomingForwardedLabel
        return label
    }

    // MARK: - Разделитель дат

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

    // MARK: - Плавающая дата

    open func floatingDateView(title: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        dateSeparatorView(title: title, theme: theme, layout: layout)
    }

    // MARK: - Пустое состояние

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

    // MARK: - Индикатор загрузки

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

    // MARK: - Аватар

    open func avatarView(name: String, url: String?, size: CGFloat, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = size / 2
        container.layer.masksToBounds = true

        // Фоллбэк на инициалы если нет картинки
        let initials = String(name.prefix(1)).uppercased()
        let hash = abs(name.hashValue)
        let hue = CGFloat(hash % 360) / 360.0
        container.backgroundColor = UIColor(hue: hue, saturation: 0.45, brightness: 0.75, alpha: 1)

        let label = UILabel()
        label.text = initials
        label.font = .systemFont(ofSize: size * 0.42, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        if let url {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: container.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
            ImageCache.shared.load(url: url) { image in
                imageView.image = image
            }
        }

        return container
    }
}

// MARK: - Обработчик нажатия на тред

private final class ThreadTapTarget: NSObject {
    static var key: UInt8 = 0
    let action: () -> Void
    init(action: @escaping () -> Void) { self.action = action }
    @objc func handleTap() { action() }
}
