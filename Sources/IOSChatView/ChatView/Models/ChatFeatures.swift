import UIKit

/// Поведенческие флаги чата — ЧТО показывать и как себя вести.
/// Все имеют разумные дефолтные значения для стандартного мессенджера.
public struct ChatFeatures: Equatable {

    // MARK: - Сообщения

    /// Отображение имени отправителя
    public var senderNameMode: SenderNameMode = .incomingOnly
    /// Показывать статус доставки (отправлено/доставлено/прочитано)
    public var showMessageStatus: Bool = true
    /// Показывать метку времени
    public var showTimestamp: Bool = true
    /// Показывать метку «изменено»
    public var showEditedMark: Bool = true
    /// Показывать реакции под сообщением
    public var showReactions: Bool = true
    /// Показывать превью цитаты
    public var showReplyPreview: Bool = true
    /// Показывать метку «переслано»
    public var showForwardedMark: Bool = true

    // MARK: - Список

    /// Показывать кнопку скролла вниз (FAB)
    public var showFab: Bool = true
    /// Показывать плавающую дату при скролле
    public var showFloatingDate: Bool = true
    /// Показывать разделители дат между группами
    public var showDateSeparators: Bool = true
    /// Показывать индикатор загрузки сверху
    public var showTopLoadingIndicator: Bool = true
    /// Показывать индикатор загрузки снизу
    public var showBottomLoadingIndicator: Bool = true
    /// Показывать пустое состояние
    public var showEmptyState: Bool = true

    // MARK: - Ввод

    /// Показывать панель ввода
    public var showInputBar: Bool = true
    /// Показывать кнопку вложений (скрепка)
    public var showAttachButton: Bool = true
    /// Показывать запись голосового сообщения
    public var showVoiceRecording: Bool = true

    // MARK: - Контекстное меню

    /// Включить контекстное меню по долгому нажатию
    public var contextMenuEnabled: Bool = true
    /// Список эмодзи для быстрых реакций в контекстном меню (пустой = без панели)
    public var emojiReactions: [String] = []

    // MARK: - Scroll поведение

    /// Порог от верха для вызова загрузки старых сообщений
    public var topLoadThreshold: CGFloat = 200
    /// Порог от низа для вызова загрузки новых сообщений
    public var bottomLoadThreshold: CGFloat = 200
    /// Расстояние от низа, при котором считается «рядом с низом» (для FAB и auto-scroll)
    public var scrollToBottomThreshold: CGFloat = 150
    /// Автоматически скроллить вниз при своём новом сообщении
    public var autoScrollOnNewMessage: Bool = true

    // MARK: - Types

    public enum SenderNameMode: Equatable {
        /// Никогда не показывать
        case never
        /// Только во входящих сообщениях (дефолт для мессенджеров)
        case incomingOnly
        /// Всегда показывать (для групповых чатов)
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
