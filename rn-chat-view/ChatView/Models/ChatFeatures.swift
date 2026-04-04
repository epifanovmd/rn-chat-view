import UIKit

/// Поведенческие флаги чата — ЧТО показывать и как себя вести.
/// Все имеют разумные дефолтные значения для стандартного мессенджера.
struct ChatFeatures: Equatable {

    // MARK: - Сообщения

    /// Отображение имени отправителя
    var senderNameMode: SenderNameMode = .incomingOnly
    /// Показывать статус доставки (отправлено/доставлено/прочитано)
    var showMessageStatus: Bool = true
    /// Показывать метку времени
    var showTimestamp: Bool = true
    /// Показывать метку «изменено»
    var showEditedMark: Bool = true
    /// Показывать реакции под сообщением
    var showReactions: Bool = true
    /// Показывать превью цитаты
    var showReplyPreview: Bool = true
    /// Показывать метку «переслано»
    var showForwardedMark: Bool = true

    // MARK: - Список

    /// Показывать кнопку скролла вниз (FAB)
    var showFab: Bool = true
    /// Показывать плавающую дату при скролле
    var showFloatingDate: Bool = true
    /// Показывать разделители дат между группами
    var showDateSeparators: Bool = true
    /// Показывать индикатор загрузки сверху
    var showTopLoadingIndicator: Bool = true
    /// Показывать индикатор загрузки снизу
    var showBottomLoadingIndicator: Bool = true
    /// Показывать пустое состояние
    var showEmptyState: Bool = true

    // MARK: - Ввод

    /// Показывать панель ввода
    var showInputBar: Bool = true
    /// Показывать кнопку вложений (скрепка)
    var showAttachButton: Bool = true
    /// Показывать запись голосового сообщения
    var showVoiceRecording: Bool = true

    // MARK: - Контекстное меню

    /// Включить контекстное меню по долгому нажатию
    var contextMenuEnabled: Bool = true
    /// Список эмодзи для быстрых реакций в контекстном меню (пустой = без панели)
    var emojiReactions: [String] = []

    // MARK: - Scroll поведение

    /// Порог от верха для вызова загрузки старых сообщений
    var topLoadThreshold: CGFloat = 200
    /// Порог от низа для вызова загрузки новых сообщений
    var bottomLoadThreshold: CGFloat = 200
    /// Расстояние от низа, при котором считается «рядом с низом» (для FAB и auto-scroll)
    var scrollToBottomThreshold: CGFloat = 150
    /// Автоматически скроллить вниз при своём новом сообщении
    var autoScrollOnNewMessage: Bool = true

    // MARK: - Types

    enum SenderNameMode: Equatable {
        /// Никогда не показывать
        case never
        /// Только во входящих сообщениях (дефолт для мессенджеров)
        case incomingOnly
        /// Всегда показывать (для групповых чатов)
        case always
    }
}
