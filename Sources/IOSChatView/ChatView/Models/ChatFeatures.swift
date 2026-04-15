import UIKit

public struct ChatFeatures: Equatable {

    // MARK: - Сообщения

    /// Режим отображения имени отправителя: никогда / только входящие / всегда
    public var senderNameMode: SenderNameMode = .incomingOnly
    /// Показывать статус доставки сообщения (отправлено/доставлено/прочитано)
    public var showMessageStatus: Bool = true
    /// Показывать время отправки сообщения
    public var showTimestamp: Bool = true
    /// Показывать метку «изменено» у отредактированных сообщений
    public var showEditedMark: Bool = true
    /// Показывать реакции (эмодзи-чипы) под сообщениями
    public var showReactions: Bool = true
    /// Показывать превью цитируемого сообщения внутри пузыря
    public var showReplyPreview: Bool = true
    /// Показывать метку «переслано» у пересланных сообщений
    public var showForwardedMark: Bool = true
    /// Показывать индикатор треда (количество ответов) под сообщением
    public var showThreadIndicator: Bool = true
    /// Показывать sticky-аватары для входящих сообщений
    public var showAvatars: Bool = false
    /// Включить автоматическое обнаружение ссылок и телефонных номеров в тексте
    public var linkDetectionEnabled: Bool = true

    // MARK: - Список

    /// Показывать кнопку быстрого скролла вниз (FAB)
    public var showFab: Bool = true
    /// Показывать плавающую дату при скролле
    public var showFloatingDate: Bool = true
    /// Показывать разделители дат между группами сообщений
    public var showDateSeparators: Bool = true
    /// Показывать индикатор загрузки сверху (подгрузка старых сообщений)
    public var showTopLoadingIndicator: Bool = true
    /// Показывать индикатор загрузки снизу (подгрузка новых сообщений)
    public var showBottomLoadingIndicator: Bool = true
    /// Показывать заглушку пустого состояния, когда сообщений нет
    public var showEmptyState: Bool = true

    // MARK: - Ввод

    /// Показывать панель ввода сообщения
    public var showInputBar: Bool = true
    /// Показывать кнопку прикрепления файлов в панели ввода
    public var showAttachButton: Bool = true
    /// Показывать кнопку записи голосового сообщения
    public var showVoiceRecording: Bool = true

    // MARK: - Контекстное меню

    /// Включить контекстное меню по долгому нажатию на сообщение
    public var contextMenuEnabled: Bool = true
    /// Список эмодзи для быстрых реакций в контекстном меню
    public var emojiReactions: [String] = []

    // MARK: - Поведение скролла

    /// Порог расстояния до верха списка для запуска подгрузки старых сообщений (pt)
    public var topLoadThreshold: CGFloat = 200
    /// Порог расстояния до низа списка для запуска подгрузки новых сообщений (pt)
    public var bottomLoadThreshold: CGFloat = 200
    /// Порог расстояния до низа, при котором показывается FAB (pt)
    public var scrollToBottomThreshold: CGFloat = 150
    /// Автоматически прокручивать вниз при получении нового сообщения
    public var autoScrollOnNewMessage: Bool = true

    // MARK: - Типы

    public enum SenderNameMode: Equatable {
        case never
        case incomingOnly
        case always
    }

    // MARK: - Init

    public init(
        senderNameMode: SenderNameMode = .incomingOnly,
        showMessageStatus: Bool = true,
        showTimestamp: Bool = true,
        showEditedMark: Bool = true,
        showReactions: Bool = true,
        showReplyPreview: Bool = true,
        showForwardedMark: Bool = true,
        showFab: Bool = true,
        showFloatingDate: Bool = true,
        showDateSeparators: Bool = true,
        showTopLoadingIndicator: Bool = true,
        showBottomLoadingIndicator: Bool = true,
        showEmptyState: Bool = true,
        showInputBar: Bool = true,
        showAttachButton: Bool = true,
        showVoiceRecording: Bool = true,
        contextMenuEnabled: Bool = true,
        emojiReactions: [String] = [],
        topLoadThreshold: CGFloat = 200,
        bottomLoadThreshold: CGFloat = 200,
        scrollToBottomThreshold: CGFloat = 150,
        autoScrollOnNewMessage: Bool = true
    ) {
        self.senderNameMode = senderNameMode
        self.showMessageStatus = showMessageStatus
        self.showTimestamp = showTimestamp
        self.showEditedMark = showEditedMark
        self.showReactions = showReactions
        self.showReplyPreview = showReplyPreview
        self.showForwardedMark = showForwardedMark
        self.showFab = showFab
        self.showFloatingDate = showFloatingDate
        self.showDateSeparators = showDateSeparators
        self.showTopLoadingIndicator = showTopLoadingIndicator
        self.showBottomLoadingIndicator = showBottomLoadingIndicator
        self.showEmptyState = showEmptyState
        self.showInputBar = showInputBar
        self.showAttachButton = showAttachButton
        self.showVoiceRecording = showVoiceRecording
        self.contextMenuEnabled = contextMenuEnabled
        self.emojiReactions = emojiReactions
        self.topLoadThreshold = topLoadThreshold
        self.bottomLoadThreshold = bottomLoadThreshold
        self.scrollToBottomThreshold = scrollToBottomThreshold
        self.autoScrollOnNewMessage = autoScrollOnNewMessage
    }
}
