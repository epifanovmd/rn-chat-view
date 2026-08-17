import UIKit

public struct ChatTheme {
    /// Тёмная тема или светлая (влияет на пресет InputBarTheme)
    public let isDark: Bool

    // MARK: - Фон

    /// Основной фон чата
    public var backgroundColor: UIColor
    /// Цвет обоев / подложки за пузырями
    public var wallpaperColor: UIColor

    // MARK: - Исходящее сообщение

    /// Фон пузыря исходящего сообщения
    public var outgoingBubble: UIColor
    /// Цвет текста исходящего сообщения
    public var outgoingText: UIColor
    /// Цвет времени отправки в исходящем сообщении
    public var outgoingTime: UIColor
    /// Цвет иконки статуса доставки (отправлено/доставлено)
    public var outgoingStatus: UIColor
    /// Цвет иконки статуса «прочитано»
    public var outgoingStatusRead: UIColor
    /// Цвет метки «изменено» в исходящем сообщении
    public var outgoingEdited: UIColor
    /// Цвет ссылок в исходящем сообщении
    public var outgoingLink: UIColor

    // MARK: - Входящее сообщение

    /// Фон пузыря входящего сообщения
    public var incomingBubble: UIColor
    /// Цвет текста входящего сообщения
    public var incomingText: UIColor
    /// Цвет времени отправки во входящем сообщении
    public var incomingTime: UIColor
    /// Цвет метки «изменено» во входящем сообщении
    public var incomingEdited: UIColor
    /// Цвет имени отправителя во входящем сообщении
    public var incomingSenderName: UIColor
    /// Цвет ссылок во входящем сообщении
    public var incomingLink: UIColor

    // MARK: - Системное сообщение

    /// Фон пузыря системного сообщения
    public var systemBubble: UIColor
    /// Цвет текста системного сообщения
    public var systemText: UIColor
    /// Цвет времени в системном сообщении
    public var systemTime: UIColor

    // MARK: - Закреплённое сообщение

    /// Фон пузыря закреплённого сообщения
    public var pinnedBubble: UIColor
    /// Цвет текста закреплённого сообщения
    public var pinnedText: UIColor
    /// Цвет времени в закреплённом сообщении
    public var pinnedTime: UIColor

    // MARK: - Превью цитаты внутри пузыря

    /// Фон блока цитаты в исходящем сообщении
    public var outgoingReplyBackground: UIColor
    /// Цвет акцентной полоски цитаты в исходящем сообщении
    public var outgoingReplyAccent: UIColor
    /// Цвет имени автора цитаты в исходящем сообщении
    public var outgoingReplySender: UIColor
    /// Цвет текста цитаты в исходящем сообщении
    public var outgoingReplyText: UIColor
    /// Фон блока цитаты во входящем сообщении
    public var incomingReplyBackground: UIColor
    /// Цвет акцентной полоски цитаты во входящем сообщении
    public var incomingReplyAccent: UIColor
    /// Цвет имени автора цитаты во входящем сообщении
    public var incomingReplySender: UIColor
    /// Цвет текста цитаты во входящем сообщении
    public var incomingReplyText: UIColor

    // MARK: - Пересланное сообщение

    /// Цвет метки «переслано» в исходящем сообщении
    public var outgoingForwardedLabel: UIColor
    /// Цвет метки «переслано» во входящем сообщении
    public var incomingForwardedLabel: UIColor
    /// Цвет акцентной полоски пересланного в исходящем сообщении
    public var outgoingForwardedAccent: UIColor
    /// Цвет акцентной полоски пересланного во входящем сообщении
    public var incomingForwardedAccent: UIColor

    // MARK: - Файл

    /// Фон блока файла в исходящем сообщении
    public var outgoingFileBackground: UIColor
    /// Фон блока файла во входящем сообщении
    public var incomingFileBackground: UIColor
    /// Цвет иконки файла
    public var fileIconColor: UIColor

    // MARK: - Реакции

    /// Фон чипа реакции (чужой)
    public var reactionBackground: UIColor
    /// Фон чипа реакции, выбранной текущим пользователем
    public var reactionMineBackground: UIColor
    /// Цвет текста (эмодзи + счётчик) в чипе реакции
    public var reactionText: UIColor
    /// Цвет рамки чипа реакции, выбранной текущим пользователем
    public var reactionMineBorder: UIColor

    // MARK: - Индикатор треда

    /// Цвет текста индикатора треда (количество ответов)
    public var threadBarText: UIColor
    /// Цвет иконки индикатора треда
    public var threadBarIcon: UIColor

    // MARK: - Разделитель дат

    /// Фон плашки разделителя дат
    public var dateSeparatorBackground: UIColor
    /// Цвет текста разделителя дат
    public var dateSeparatorText: UIColor

    // MARK: - FAB (кнопка скролла вниз)

    /// Фон кнопки скролла вниз (FAB)
    public var fabBackground: UIColor
    /// Цвет рамки FAB
    public var fabBorder: UIColor
    /// Стиль блюра FAB
    public var fabBlurStyle: UIBlurEffect.Style
    /// Цвет стрелки FAB
    public var fabArrowColor: UIColor
    /// Фон бейджа непрочитанных на FAB
    public var fabBadgeBackground: UIColor
    /// Цвет текста бейджа непрочитанных на FAB
    public var fabBadgeTextColor: UIColor
    /// Цвет тени FAB
    public var fabShadowColor: UIColor

    // MARK: - Голосовое сообщение (контент)

    /// Цвет активной (проигранной) части волны голосового сообщения
    public var voiceWaveformActive: UIColor
    /// Цвет неактивной части волны голосового сообщения
    public var voiceWaveformInactive: UIColor

    // MARK: - Опрос

    /// Цвет заполненной полоски прогресса опроса
    public var pollBarFilled: UIColor
    /// Цвет пустой полоски прогресса опроса
    public var pollBarEmpty: UIColor
    /// Цвет рамки выбранного варианта опроса
    public var pollSelectedBorder: UIColor
    /// Цвет подзаголовка опроса (количество голосов и т.д.)
    public var pollSubtitleColor: UIColor

    // MARK: - Сетка медиа

    /// Фон-заглушка медиа до загрузки изображения
    public var mediaPlaceholderBackground: UIColor
    /// Цвет иконки воспроизведения видео
    public var mediaPlayIconColor: UIColor
    /// Цвет тени иконки воспроизведения видео
    public var mediaPlayShadowColor: UIColor
    /// Фон плашки длительности видео
    public var mediaDurationBackground: UIColor
    /// Цвет текста длительности видео
    public var mediaDurationTextColor: UIColor
    /// Фон оверлея «ещё N фото» в сетке медиа
    public var mediaOverlayBackground: UIColor
    /// Цвет текста оверлея «ещё N фото» в сетке медиа
    public var mediaOverlayTextColor: UIColor

    // MARK: - Подсветка сообщения

    /// Цвет подсветки сообщения при scrollToMessage с highlight
    public var messageHighlightColor: UIColor

    // MARK: - Пустое состояние

    /// Цвет текста заглушки пустого состояния
    public var emptyStateText: UIColor

    // MARK: - Init

    public init(
        isDark: Bool,
        backgroundColor: UIColor,
        wallpaperColor: UIColor,
        outgoingBubble: UIColor,
        outgoingText: UIColor,
        outgoingTime: UIColor,
        outgoingStatus: UIColor,
        outgoingStatusRead: UIColor,
        outgoingEdited: UIColor,
        outgoingLink: UIColor,
        incomingBubble: UIColor,
        incomingText: UIColor,
        incomingTime: UIColor,
        incomingEdited: UIColor,
        incomingSenderName: UIColor,
        incomingLink: UIColor,
        systemBubble: UIColor = UIColor(white: 0.5, alpha: 0.12),
        systemText: UIColor = UIColor(white: 0.4, alpha: 1),
        systemTime: UIColor = UIColor(white: 0.5, alpha: 1),
        pinnedBubble: UIColor = UIColor(red: 0.91, green: 0.93, blue: 1.0, alpha: 1),
        pinnedText: UIColor = UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1),
        pinnedTime: UIColor = UIColor(red: 0.35, green: 0.4, blue: 0.6, alpha: 1),
        outgoingReplyBackground: UIColor,
        outgoingReplyAccent: UIColor,
        outgoingReplySender: UIColor,
        outgoingReplyText: UIColor,
        incomingReplyBackground: UIColor,
        incomingReplyAccent: UIColor,
        incomingReplySender: UIColor,
        incomingReplyText: UIColor,
        outgoingForwardedLabel: UIColor,
        incomingForwardedLabel: UIColor,
        outgoingForwardedAccent: UIColor,
        incomingForwardedAccent: UIColor,
        outgoingFileBackground: UIColor,
        incomingFileBackground: UIColor,
        fileIconColor: UIColor,
        threadBarText: UIColor = .systemBlue,
        threadBarIcon: UIColor = .systemBlue,
        reactionBackground: UIColor,
        reactionMineBackground: UIColor,
        reactionText: UIColor,
        reactionMineBorder: UIColor,
        dateSeparatorBackground: UIColor,
        dateSeparatorText: UIColor,
        fabBackground: UIColor,
        fabBorder: UIColor,
        fabBlurStyle: UIBlurEffect.Style,
        fabArrowColor: UIColor,
        fabBadgeBackground: UIColor,
        fabBadgeTextColor: UIColor,
        fabShadowColor: UIColor,
        voiceWaveformActive: UIColor,
        voiceWaveformInactive: UIColor,
        pollBarFilled: UIColor,
        pollBarEmpty: UIColor,
        pollSelectedBorder: UIColor,
        pollSubtitleColor: UIColor,
        mediaPlaceholderBackground: UIColor,
        mediaPlayIconColor: UIColor,
        mediaPlayShadowColor: UIColor,
        mediaDurationBackground: UIColor,
        mediaDurationTextColor: UIColor,
        mediaOverlayBackground: UIColor,
        mediaOverlayTextColor: UIColor,
        messageHighlightColor: UIColor,
        emptyStateText: UIColor
    ) {
        self.isDark = isDark
        self.backgroundColor = backgroundColor
        self.wallpaperColor = wallpaperColor
        self.outgoingBubble = outgoingBubble
        self.outgoingText = outgoingText
        self.outgoingTime = outgoingTime
        self.outgoingStatus = outgoingStatus
        self.outgoingStatusRead = outgoingStatusRead
        self.outgoingEdited = outgoingEdited
        self.outgoingLink = outgoingLink
        self.incomingBubble = incomingBubble
        self.incomingText = incomingText
        self.incomingTime = incomingTime
        self.incomingEdited = incomingEdited
        self.incomingSenderName = incomingSenderName
        self.incomingLink = incomingLink
        self.systemBubble = systemBubble
        self.systemText = systemText
        self.systemTime = systemTime
        self.pinnedBubble = pinnedBubble
        self.pinnedText = pinnedText
        self.pinnedTime = pinnedTime
        self.outgoingReplyBackground = outgoingReplyBackground
        self.outgoingReplyAccent = outgoingReplyAccent
        self.outgoingReplySender = outgoingReplySender
        self.outgoingReplyText = outgoingReplyText
        self.incomingReplyBackground = incomingReplyBackground
        self.incomingReplyAccent = incomingReplyAccent
        self.incomingReplySender = incomingReplySender
        self.incomingReplyText = incomingReplyText
        self.outgoingForwardedLabel = outgoingForwardedLabel
        self.incomingForwardedLabel = incomingForwardedLabel
        self.outgoingForwardedAccent = outgoingForwardedAccent
        self.incomingForwardedAccent = incomingForwardedAccent
        self.outgoingFileBackground = outgoingFileBackground
        self.incomingFileBackground = incomingFileBackground
        self.fileIconColor = fileIconColor
        self.threadBarText = threadBarText
        self.threadBarIcon = threadBarIcon
        self.reactionBackground = reactionBackground
        self.reactionMineBackground = reactionMineBackground
        self.reactionText = reactionText
        self.reactionMineBorder = reactionMineBorder
        self.dateSeparatorBackground = dateSeparatorBackground
        self.dateSeparatorText = dateSeparatorText
        self.fabBackground = fabBackground
        self.fabBorder = fabBorder
        self.fabBlurStyle = fabBlurStyle
        self.fabArrowColor = fabArrowColor
        self.fabBadgeBackground = fabBadgeBackground
        self.fabBadgeTextColor = fabBadgeTextColor
        self.fabShadowColor = fabShadowColor
        self.voiceWaveformActive = voiceWaveformActive
        self.voiceWaveformInactive = voiceWaveformInactive
        self.pollBarFilled = pollBarFilled
        self.pollBarEmpty = pollBarEmpty
        self.pollSelectedBorder = pollSelectedBorder
        self.pollSubtitleColor = pollSubtitleColor
        self.mediaPlaceholderBackground = mediaPlaceholderBackground
        self.mediaPlayIconColor = mediaPlayIconColor
        self.mediaPlayShadowColor = mediaPlayShadowColor
        self.mediaDurationBackground = mediaDurationBackground
        self.mediaDurationTextColor = mediaDurationTextColor
        self.mediaOverlayBackground = mediaOverlayBackground
        self.mediaOverlayTextColor = mediaOverlayTextColor
        self.messageHighlightColor = messageHighlightColor
        self.emptyStateText = emptyStateText
    }
}

// MARK: - Пресеты

public extension ChatTheme {
    public static let light = ChatTheme(
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

    public static let dark = ChatTheme(
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
        systemBubble: UIColor(white: 1.0, alpha: 0.08),
        systemText: UIColor(white: 1.0, alpha: 0.6),
        systemTime: UIColor(white: 1.0, alpha: 0.4),
        pinnedBubble: UIColor(red: 0.15, green: 0.18, blue: 0.28, alpha: 1),
        pinnedText: UIColor(red: 0.82, green: 0.85, blue: 0.95, alpha: 1),
        pinnedTime: UIColor(red: 0.5, green: 0.55, blue: 0.72, alpha: 1),
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

// MARK: - Цвета по принадлежности сообщения

public extension ChatTheme {
    /// Единая точка выбора цвета по ownership — вместо повторяющихся
    /// switch по всему коду. Новый ownership добавляется только здесь.
    func bubbleColor(for ownership: MessageOwnership) -> UIColor {
        switch ownership {
        case .mine:   return outgoingBubble
        case .theirs: return incomingBubble
        case .system: return systemBubble
        case .pinned: return pinnedBubble
        }
    }

    func textColor(for ownership: MessageOwnership) -> UIColor {
        switch ownership {
        case .mine:   return outgoingText
        case .theirs: return incomingText
        case .system: return systemText
        case .pinned: return pinnedText
        }
    }

    func linkColor(for ownership: MessageOwnership) -> UIColor {
        ownership == .mine ? outgoingLink : incomingLink
    }

    func timeColor(for ownership: MessageOwnership) -> UIColor {
        switch ownership {
        case .mine:   return outgoingTime
        case .theirs: return incomingTime
        case .system: return systemTime
        case .pinned: return pinnedTime
        }
    }

    func editedColor(for ownership: MessageOwnership) -> UIColor {
        switch ownership {
        case .mine:   return outgoingEdited
        case .theirs: return incomingEdited
        case .system: return systemTime
        case .pinned: return pinnedTime
        }
    }
}
