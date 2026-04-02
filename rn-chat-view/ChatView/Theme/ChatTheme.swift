import UIKit

struct ChatTheme {
    let isDark: Bool

    // MARK: - Фон

    /// Основной фон чата
    var backgroundColor: UIColor
    /// Цвет обоев/паттерна
    var wallpaperColor: UIColor

    // MARK: - Исходящее сообщение

    /// Фон пузыря исходящего сообщения
    var outgoingBubble: UIColor
    /// Цвет текста исходящего сообщения
    var outgoingText: UIColor
    /// Цвет метки времени исходящего сообщения
    var outgoingTime: UIColor
    /// Цвет иконки статуса (отправка/отправлено/доставлено)
    var outgoingStatus: UIColor
    /// Цвет иконки статуса «прочитано»
    var outgoingStatusRead: UIColor
    /// Цвет метки «изменено» исходящего сообщения
    var outgoingEdited: UIColor
    /// Цвет ссылок в исходящем сообщении
    var outgoingLink: UIColor

    // MARK: - Входящее сообщение

    /// Фон пузыря входящего сообщения
    var incomingBubble: UIColor
    /// Цвет текста входящего сообщения
    var incomingText: UIColor
    /// Цвет метки времени входящего сообщения
    var incomingTime: UIColor
    /// Цвет метки «изменено» входящего сообщения
    var incomingEdited: UIColor
    /// Цвет имени отправителя во входящем сообщении
    var incomingSenderName: UIColor
    /// Цвет ссылок во входящем сообщении
    var incomingLink: UIColor

    // MARK: - Превью цитаты внутри пузыря

    /// Фон превью цитаты в исходящем сообщении
    var outgoingReplyBackground: UIColor
    /// Цвет акцентной полоски цитаты в исходящем
    var outgoingReplyAccent: UIColor
    /// Цвет имени отправителя в цитате исходящего
    var outgoingReplySender: UIColor
    /// Цвет текста цитаты в исходящем
    var outgoingReplyText: UIColor
    /// Фон превью цитаты во входящем сообщении
    var incomingReplyBackground: UIColor
    /// Цвет акцентной полоски цитаты во входящем
    var incomingReplyAccent: UIColor
    /// Цвет имени отправителя в цитате входящего
    var incomingReplySender: UIColor
    /// Цвет текста цитаты во входящем
    var incomingReplyText: UIColor

    // MARK: - Пересланное сообщение

    /// Цвет метки «переслано» в исходящем сообщении
    var outgoingForwardedLabel: UIColor
    /// Цвет метки «переслано» во входящем сообщении
    var incomingForwardedLabel: UIColor

    // MARK: - Реакции

    /// Фон чипа реакции (чужой)
    var reactionBackground: UIColor
    /// Фон чипа моей реакции
    var reactionMineBackground: UIColor
    /// Цвет текста/эмодзи реакции
    var reactionText: UIColor
    /// Цвет рамки чипа моей реакции
    var reactionMineBorder: UIColor

    // MARK: - Разделитель дат

    /// Фон пилюли разделителя дат
    var dateSeparatorBackground: UIColor
    /// Цвет текста разделителя дат
    var dateSeparatorText: UIColor

    // MARK: - Панель ввода

    /// Фон панели ввода
    var inputBarBackground: UIColor
    /// Цвет верхней разделительной линии панели ввода
    var inputBarSeparator: UIColor
    /// Фон поля ввода текста
    var inputBarTextViewBackground: UIColor
    /// Цвет плейсхолдера в поле ввода
    var inputBarPlaceholder: UIColor
    /// Цвет текста в поле ввода
    var inputBarText: UIColor
    /// Цвет кнопок панели ввода (скрепка, отправить)
    var inputBarTint: UIColor
    /// Цвет рамки поля ввода текста
    var inputBarBorder: UIColor

    // MARK: - Панель ответа/редактирования

    /// Фон панели ответа
    var replyPanelBackground: UIColor
    /// Цвет акцентной полоски панели ответа
    var replyPanelAccent: UIColor
    /// Цвет имени отправителя в панели ответа
    var replyPanelSender: UIColor
    /// Цвет превью текста в панели ответа
    var replyPanelText: UIColor
    /// Цвет кнопки закрытия панели ответа
    var replyPanelClose: UIColor

    // MARK: - FAB (кнопка скролла вниз)

    /// Стиль размытия фона FAB
    var fabBlurStyle: UIBlurEffect.Style
    /// Цвет стрелки FAB
    var fabArrowColor: UIColor
    /// Фон бейджа непрочитанных на FAB
    var fabBadgeBackground: UIColor
    /// Цвет текста бейджа непрочитанных
    var fabBadgeTextColor: UIColor
    /// Цвет тени FAB
    var fabShadowColor: UIColor

    // MARK: - Голосовое сообщение

    /// Цвет активных (проигранных) полосок волны
    var voiceWaveformActive: UIColor
    /// Цвет неактивных полосок волны
    var voiceWaveformInactive: UIColor
    /// Цвет индикатора записи (красная точка)
    var voiceRecordingIndicator: UIColor
    /// Цвет кнопки остановки записи
    var voiceRecordingStopColor: UIColor

    // MARK: - Опрос

    /// Цвет заполненной полосы варианта опроса
    var pollBarFilled: UIColor
    /// Цвет фона/пустой полосы варианта опроса
    var pollBarEmpty: UIColor
    /// Цвет галочки выбранного варианта опроса
    var pollSelectedCheck: UIColor

    // MARK: - Сетка медиа

    /// Фон плейсхолдера при загрузке изображений
    var mediaPlaceholderBackground: UIColor
    /// Цвет иконки воспроизведения на видео
    var mediaPlayIconColor: UIColor
    /// Цвет тени иконки воспроизведения
    var mediaPlayShadowColor: UIColor
    /// Фон бейджа длительности видео
    var mediaDurationBackground: UIColor
    /// Цвет текста бейджа длительности видео
    var mediaDurationTextColor: UIColor
    /// Фон оверлея «+N» на сетке медиа
    var mediaOverlayBackground: UIColor
    /// Цвет текста оверлея «+N»
    var mediaOverlayTextColor: UIColor

    // MARK: - Подсветка сообщения

    /// Цвет оверлея подсветки при скролле к сообщению
    var messageHighlightColor: UIColor

    // MARK: - Пустое состояние

    /// Цвет текста пустого состояния («Нет сообщений»)
    var emptyStateText: UIColor
}

// MARK: - Presets

extension ChatTheme {
    static let light = ChatTheme(
        isDark: false,
        backgroundColor: UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1),
        wallpaperColor: UIColor(red: 0.84, green: 0.88, blue: 0.93, alpha: 1),
        outgoingBubble: UIColor(red: 0.88, green: 0.98, blue: 0.84, alpha: 1),
        outgoingText: .black,
        outgoingTime: UIColor(white: 0.0, alpha: 0.45),
        outgoingStatus: UIColor(white: 0.0, alpha: 0.35),
        outgoingStatusRead: UIColor(red: 0.2, green: 0.6, blue: 0.35, alpha: 1),
        outgoingEdited: UIColor(white: 0.0, alpha: 0.4),
        outgoingLink: .systemBlue,
        incomingBubble: .white,
        incomingText: .black,
        incomingTime: UIColor(white: 0.0, alpha: 0.45),
        incomingEdited: UIColor(white: 0.0, alpha: 0.4),
        incomingSenderName: .systemBlue,
        incomingLink: .systemBlue,
        outgoingReplyBackground: UIColor(red: 0.78, green: 0.93, blue: 0.74, alpha: 1),
        outgoingReplyAccent: UIColor(red: 0.2, green: 0.6, blue: 0.35, alpha: 1),
        outgoingReplySender: UIColor(red: 0.2, green: 0.6, blue: 0.35, alpha: 1),
        outgoingReplyText: UIColor(white: 0.0, alpha: 0.7),
        incomingReplyBackground: UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1),
        incomingReplyAccent: .systemBlue,
        incomingReplySender: .systemBlue,
        incomingReplyText: UIColor(white: 0.0, alpha: 0.7),
        outgoingForwardedLabel: UIColor(red: 0.2, green: 0.6, blue: 0.35, alpha: 1),
        incomingForwardedLabel: .systemBlue,
        reactionBackground: UIColor(white: 0.93, alpha: 1),
        reactionMineBackground: UIColor.systemBlue.withAlphaComponent(0.15),
        reactionText: .black,
        reactionMineBorder: UIColor.systemBlue.withAlphaComponent(0.5),
        dateSeparatorBackground: UIColor(white: 0.0, alpha: 0.08),
        dateSeparatorText: UIColor(white: 0.0, alpha: 0.5),
        inputBarBackground: UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1),
        inputBarSeparator: UIColor(white: 0.8, alpha: 1),
        inputBarTextViewBackground: .white,
        inputBarPlaceholder: UIColor(white: 0.6, alpha: 1),
        inputBarText: .black,
        inputBarTint: .systemBlue,
        inputBarBorder: UIColor(white: 0.8, alpha: 1),
        replyPanelBackground: UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1),
        replyPanelAccent: .systemBlue,
        replyPanelSender: .systemBlue,
        replyPanelText: UIColor(white: 0.3, alpha: 1),
        replyPanelClose: UIColor(white: 0.5, alpha: 1),
        fabBlurStyle: .systemMaterial,
        fabArrowColor: UIColor(white: 0.15, alpha: 1),
        fabBadgeBackground: .systemBlue,
        fabBadgeTextColor: .white,
        fabShadowColor: .black,
        voiceWaveformActive: .systemBlue,
        voiceWaveformInactive: UIColor(white: 0.75, alpha: 1),
        voiceRecordingIndicator: .systemRed,
        voiceRecordingStopColor: .systemRed,
        pollBarFilled: .systemBlue,
        pollBarEmpty: UIColor(white: 0.9, alpha: 1),
        pollSelectedCheck: .systemBlue,
        mediaPlaceholderBackground: UIColor(white: 0.9, alpha: 1),
        mediaPlayIconColor: .white,
        mediaPlayShadowColor: .black,
        mediaDurationBackground: UIColor.black.withAlphaComponent(0.5),
        mediaDurationTextColor: .white,
        mediaOverlayBackground: UIColor.black.withAlphaComponent(0.55),
        mediaOverlayTextColor: .white,
        messageHighlightColor: UIColor.systemYellow.withAlphaComponent(0.3),
        emptyStateText: UIColor(white: 0.5, alpha: 1)
    )

    static let dark = ChatTheme(
        isDark: true,
        backgroundColor: UIColor(red: 0.06, green: 0.09, blue: 0.13, alpha: 1),
        wallpaperColor: UIColor(red: 0.06, green: 0.09, blue: 0.13, alpha: 1),
        outgoingBubble: UIColor(red: 0.17, green: 0.32, blue: 0.47, alpha: 1),
        outgoingText: .white,
        outgoingTime: UIColor(white: 1.0, alpha: 0.5),
        outgoingStatus: UIColor(white: 1.0, alpha: 0.4),
        outgoingStatusRead: UIColor(red: 0.4, green: 0.8, blue: 0.55, alpha: 1),
        outgoingEdited: UIColor(white: 1.0, alpha: 0.45),
        outgoingLink: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        incomingBubble: UIColor(red: 0.11, green: 0.15, blue: 0.20, alpha: 1),
        incomingText: .white,
        incomingTime: UIColor(white: 1.0, alpha: 0.5),
        incomingEdited: UIColor(white: 1.0, alpha: 0.45),
        incomingSenderName: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        incomingLink: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        outgoingReplyBackground: UIColor(red: 0.14, green: 0.27, blue: 0.40, alpha: 1),
        outgoingReplyAccent: UIColor(red: 0.4, green: 0.8, blue: 0.55, alpha: 1),
        outgoingReplySender: UIColor(red: 0.4, green: 0.8, blue: 0.55, alpha: 1),
        outgoingReplyText: UIColor(white: 1.0, alpha: 0.6),
        incomingReplyBackground: UIColor(red: 0.14, green: 0.18, blue: 0.24, alpha: 1),
        incomingReplyAccent: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        incomingReplySender: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        incomingReplyText: UIColor(white: 1.0, alpha: 0.6),
        outgoingForwardedLabel: UIColor(red: 0.4, green: 0.8, blue: 0.55, alpha: 1),
        incomingForwardedLabel: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        reactionBackground: UIColor(white: 0.2, alpha: 1),
        reactionMineBackground: UIColor.systemBlue.withAlphaComponent(0.25),
        reactionText: .white,
        reactionMineBorder: UIColor.systemBlue.withAlphaComponent(0.6),
        dateSeparatorBackground: UIColor(white: 1.0, alpha: 0.08),
        dateSeparatorText: UIColor(white: 1.0, alpha: 0.5),
        inputBarBackground: UIColor(red: 0.11, green: 0.14, blue: 0.19, alpha: 1),
        inputBarSeparator: UIColor(white: 0.25, alpha: 1),
        inputBarTextViewBackground: UIColor(red: 0.15, green: 0.19, blue: 0.25, alpha: 1),
        inputBarPlaceholder: UIColor(white: 0.45, alpha: 1),
        inputBarText: .white,
        inputBarTint: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        inputBarBorder: UIColor(white: 0.25, alpha: 1),
        replyPanelBackground: UIColor(red: 0.11, green: 0.14, blue: 0.19, alpha: 1),
        replyPanelAccent: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        replyPanelSender: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        replyPanelText: UIColor(white: 0.65, alpha: 1),
        replyPanelClose: UIColor(white: 0.5, alpha: 1),
        fabBlurStyle: .systemMaterialDark,
        fabArrowColor: UIColor(white: 0.7, alpha: 1),
        fabBadgeBackground: .systemBlue,
        fabBadgeTextColor: .white,
        fabShadowColor: .black,
        voiceWaveformActive: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        voiceWaveformInactive: UIColor(white: 0.35, alpha: 1),
        voiceRecordingIndicator: .systemRed,
        voiceRecordingStopColor: .systemRed,
        pollBarFilled: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        pollBarEmpty: UIColor(white: 0.2, alpha: 1),
        pollSelectedCheck: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        mediaPlaceholderBackground: UIColor(white: 0.2, alpha: 1),
        mediaPlayIconColor: .white,
        mediaPlayShadowColor: .black,
        mediaDurationBackground: UIColor.black.withAlphaComponent(0.5),
        mediaDurationTextColor: .white,
        mediaOverlayBackground: UIColor.black.withAlphaComponent(0.55),
        mediaOverlayTextColor: .white,
        messageHighlightColor: UIColor.systemYellow.withAlphaComponent(0.3),
        emptyStateText: UIColor(white: 0.5, alpha: 1)
    )
}
