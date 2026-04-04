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
    /// Цвет акцентной полоски пересланного в исходящем
    var outgoingForwardedAccent: UIColor
    /// Цвет акцентной полоски пересланного во входящем
    var incomingForwardedAccent: UIColor

    // MARK: - Файл

    /// Фон карточки файла в исходящем сообщении
    var outgoingFileBackground: UIColor
    /// Фон карточки файла во входящем сообщении
    var incomingFileBackground: UIColor
    /// Цвет иконки файла
    var fileIconColor: UIColor

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

    // MARK: - FAB (кнопка скролла вниз)

    /// Фон кнопки FAB
    var fabBackground: UIColor
    /// Цвет рамки FAB
    var fabBorder: UIColor
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

    // MARK: - Голосовое сообщение (контент)

    /// Цвет активных (проигранных) полосок волны
    var voiceWaveformActive: UIColor
    /// Цвет неактивных полосок волны
    var voiceWaveformInactive: UIColor

    // MARK: - Опрос

    /// Цвет заполненной полосы варианта опроса
    var pollBarFilled: UIColor
    /// Цвет фона/пустой полосы варианта опроса
    var pollBarEmpty: UIColor
    /// Цвет бордера выбранного варианта
    var pollSelectedBorder: UIColor
    /// Цвет подписи типа опроса
    var pollSubtitleColor: UIColor

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
        outgoingForwardedAccent: UIColor(red: 0.2, green: 0.6, blue: 0.35, alpha: 1),
        incomingForwardedAccent: .systemBlue,
        outgoingFileBackground: UIColor(red: 0.78, green: 0.93, blue: 0.74, alpha: 1),
        incomingFileBackground: UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1),
        fileIconColor: .systemBlue,
        reactionBackground: UIColor(white: 0.93, alpha: 1),
        reactionMineBackground: UIColor.systemBlue.withAlphaComponent(0.15),
        reactionText: .black,
        reactionMineBorder: UIColor.systemBlue.withAlphaComponent(0.5),
        dateSeparatorBackground: UIColor(white: 0.0, alpha: 0.08),
        dateSeparatorText: UIColor(white: 0.0, alpha: 0.5),
        fabBackground: .white,
        fabBorder: UIColor(white: 0.8, alpha: 1),
        fabBlurStyle: .systemUltraThinMaterial,
        fabArrowColor: UIColor(red: 0.25, green: 0.55, blue: 0.9, alpha: 1),
        fabBadgeBackground: UIColor(red: 0.25, green: 0.55, blue: 0.9, alpha: 1),
        fabBadgeTextColor: .white,
        fabShadowColor: UIColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 0.3),
        voiceWaveformActive: .systemBlue,
        voiceWaveformInactive: UIColor(white: 0.75, alpha: 1),
        pollBarFilled: UIColor(red: 0.35, green: 0.65, blue: 0.95, alpha: 1),
        pollBarEmpty: UIColor(white: 0.0, alpha: 0.05),
        pollSelectedBorder: .clear,
        pollSubtitleColor: UIColor(white: 0.0, alpha: 0.4),
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
        outgoingForwardedAccent: UIColor(red: 0.4, green: 0.8, blue: 0.55, alpha: 1),
        incomingForwardedAccent: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        outgoingFileBackground: UIColor(red: 0.14, green: 0.27, blue: 0.40, alpha: 1),
        incomingFileBackground: UIColor(red: 0.14, green: 0.18, blue: 0.24, alpha: 1),
        fileIconColor: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        reactionBackground: UIColor(white: 0.2, alpha: 1),
        reactionMineBackground: UIColor.systemBlue.withAlphaComponent(0.25),
        reactionText: .white,
        reactionMineBorder: UIColor.systemBlue.withAlphaComponent(0.6),
        dateSeparatorBackground: UIColor(white: 1.0, alpha: 0.08),
        dateSeparatorText: UIColor(white: 1.0, alpha: 0.5),
        fabBackground: UIColor(red: 0.15, green: 0.19, blue: 0.25, alpha: 1),
        fabBorder: UIColor(white: 0.25, alpha: 1),
        fabBlurStyle: .systemUltraThinMaterialDark,
        fabArrowColor: UIColor(red: 0.45, green: 0.7, blue: 1.0, alpha: 1),
        fabBadgeBackground: UIColor(red: 0.35, green: 0.6, blue: 0.95, alpha: 1),
        fabBadgeTextColor: .white,
        fabShadowColor: UIColor.black.withAlphaComponent(0.4),
        voiceWaveformActive: UIColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1),
        voiceWaveformInactive: UIColor(white: 0.35, alpha: 1),
        pollBarFilled: UIColor(red: 0.35, green: 0.6, blue: 0.9, alpha: 1),
        pollBarEmpty: UIColor(white: 1.0, alpha: 0.06),
        pollSelectedBorder: .clear,
        pollSubtitleColor: UIColor(white: 1.0, alpha: 0.4),
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
