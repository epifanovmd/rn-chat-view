import UIKit

public struct ChatLayout {
    // MARK: - Пузырь сообщения

    /// Радиус скругления пузыря
    public var bubbleCornerRadius: CGFloat = 18
    /// Ширина хвостика пузыря
    public var bubbleTailWidth: CGFloat = 6
    /// Макс. ширина пузыря как доля ширины экрана
    public var bubbleMaxWidthRatio: CGFloat = 0.85
    /// Минимальная ширина пузыря
    public var bubbleMinWidth: CGFloat = 60
    /// Горизонтальный отступ внутри пузыря
    public var bubbleHPad: CGFloat = 12
    /// Вертикальный отступ сверху внутри пузыря
    public var bubbleVPad: CGFloat = 6
    /// Отступ снизу пузыря после футера
    public var bubbleBottomPad: CGFloat = 5
    /// Вертикальный интервал между элементами внутри пузыря
    public var bubbleSpacing: CGFloat = 4
    /// Интервал между медиа и текстом в смешанном контенте
    public var mixedContentSpacing: CGFloat = 4

    // MARK: - Ячейка сообщения

    /// Горизонтальный отступ пузыря от края экрана
    public var cellHMargin: CGFloat = 8
    /// Вертикальный интервал между ячейками сообщений
    public var cellVSpacing: CGFloat = 2
    /// Минимальная высота ячейки
    public var cellMinHeight: CGFloat = 36
    /// Дополнительный вертикальный интервал вокруг системных сообщений
    /// Дополнительный отступ снизу у системного сообщения (между ним и следующим)
    public var systemCellBottomSpacing: CGFloat = 20
    /// Дополнительный отступ снизу у закреплённого сообщения (между ним и следующим)
    public var pinnedCellBottomSpacing: CGFloat = 32

    // MARK: - Аватарки

    /// Размер аватарки (ширина = высота)
    public var avatarSize: CGFloat = 36
    /// Отступ аватарки от левого края экрана
    public var avatarLeadingMargin: CGFloat = 6
    /// Отступ между аватаркой и пузырём
    public var avatarBubbleSpacing: CGFloat = 2

    // MARK: - Шрифты контента

    /// Шрифт текста сообщения
    public var messageFont: UIFont = .systemFont(ofSize: 15)
    /// Шрифт имени отправителя
    public var senderNameFont: UIFont = .systemFont(ofSize: 13, weight: .semibold)
    /// Шрифт метки времени
    public var timeFont: UIFont = .systemFont(ofSize: 11)
    /// Шрифт метки «изменено»
    public var editedFont: UIFont = .systemFont(ofSize: 11)
    /// Шрифт метки «переслано»
    public var forwardedFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// Ширина акцентной полоски пересланного сообщения
    public var forwardedAccentWidth: CGFloat = 2.5
    /// Горизонтальный отступ контента от полоски пересланного
    public var forwardedContentInset: CGFloat = 8

    // MARK: - Футер (время, статус)

    /// Высота строки футера
    public var footerHeight: CGFloat = 16
    /// Интервал между элементами футера
    public var footerSpacing: CGFloat = 3
    /// Размер иконки статуса доставки
    public var statusIconSize: CGFloat = 11

    // MARK: - Превью цитаты

    /// Высота блока превью цитаты
    public var replyHeight: CGFloat = 38
    /// Ширина акцентной полоски цитаты
    public var replyAccentWidth: CGFloat = 2.5
    /// Радиус скругления блока цитаты
    public var replyCornerRadius: CGFloat = 6
    /// Шрифт текста превью цитаты
    public var replyFont: UIFont = .systemFont(ofSize: 13)
    /// Шрифт имени отправителя в цитате
    public var replySenderFont: UIFont = .systemFont(ofSize: 13, weight: .semibold)

    // MARK: - Реакции

    /// Высота чипа реакции
    public var reactionChipHeight: CGFloat = 28
    /// Интервал между чипами реакций
    public var reactionChipSpacing: CGFloat = 4
    /// Горизонтальный отступ внутри чипа реакции
    public var reactionChipPadding: CGFloat = 8
    /// Ширина рамки чипа моей реакции
    public var reactionBorderWidth: CGFloat = 1
    /// Шрифт текста реакции
    public var reactionFont: UIFont = .systemFont(ofSize: 13)

    // MARK: - Тред

    /// Высота бара индикатора треда
    public var threadBarHeight: CGFloat = 28
    /// Шрифт текста индикатора треда
    public var threadBarFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// Интервал между элементами внутри бара треда
    public var threadBarSpacing: CGFloat = 4
    /// Размер иконки треда
    public var threadBarIconSize: CGFloat = 14
    /// Размер шеврона в баре треда
    public var threadBarChevronSize: CGFloat = 10

    // MARK: - Медиа / изображения

    /// Максимальная высота изображения/видео
    public var imageMaxHeight: CGFloat = 280
    /// Минимальная высота изображения/видео
    public var imageMinHeight: CGFloat = 100
    /// Радиус скругления изображения/видео
    public var imageCornerRadius: CGFloat = 12
    /// Интервал между ячейками в сетке медиа
    public var mediaGridSpacing: CGFloat = 2
    /// Размер иконки воспроизведения в сетке медиа
    public var mediaPlayIconSize: CGFloat = 36
    /// Шрифт оверлея «+N» на сетке медиа
    public var mediaOverlayFont: UIFont = .systemFont(ofSize: 28, weight: .semibold)
    /// Шрифт бейджа длительности видео в сетке
    public var mediaDurationFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    /// Радиус скругления бейджа длительности
    public var mediaDurationCornerRadius: CGFloat = 6
    /// Непрозрачность тени иконки воспроизведения
    public var mediaPlayShadowOpacity: Float = 0.5
    /// Радиус размытия тени иконки воспроизведения
    public var mediaPlayShadowRadius: CGFloat = 4
    /// Горизонтальный отступ внутри бейджа длительности
    public var mediaDurationPadH: CGFloat = 4
    /// Вертикальный отступ внутри бейджа длительности
    public var mediaDurationPadV: CGFloat = 2
    /// Отступ бейджа длительности от края
    public var mediaDurationMargin: CGFloat = 4

    // MARK: - Видео (отдельное)

    /// Размер кнопки воспроизведения для отдельного видео
    public var videoPlaySize: CGFloat = 48
    /// Шрифт длительности видео
    public var videoDurationFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)

    // MARK: - Голосовое сообщение

    /// Высота визуализации волны
    public var voiceWaveformHeight: CGFloat = 28
    /// Ширина полоски волны
    public var voiceBarWidth: CGFloat = 2.5
    /// Интервал между полосками волны
    public var voiceBarSpacing: CGFloat = 2
    /// Шрифт длительности голосового
    public var voiceDurationFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    /// Размер кнопки воспроизведения голосового
    public var voicePlaySize: CGFloat = 36
    /// Размер иконки воспроизведения голосового
    public var voicePlayIconSize: CGFloat = 18

    // MARK: - Опрос

    /// Шрифт вопроса опроса
    public var pollQuestionFont: UIFont = .systemFont(ofSize: 15, weight: .semibold)
    /// Шрифт подписи типа опроса
    public var pollSubtitleFont: UIFont = .systemFont(ofSize: 12)
    /// Шрифт текста варианта опроса
    public var pollOptionFont: UIFont = .systemFont(ofSize: 14, weight: .medium)
    /// Шрифт процента варианта
    public var pollPercentFont: UIFont = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
    /// Высота полосы варианта опроса
    public var pollBarHeight: CGFloat = 32
    /// Радиус скругления полосы варианта
    public var pollBarCornerRadius: CGFloat = 12
    /// Интервал после заголовка опроса
    public var pollHeaderSpacing: CGFloat = 10
    /// Интервал между вариантами опроса
    public var pollOptionSpacing: CGFloat = 4
    /// Шрифт счётчика голосов опроса
    public var pollVotesFont: UIFont = .systemFont(ofSize: 12)
    /// Внутренний горизонтальный отступ полоски
    public var pollBarHPad: CGFloat = 12
    /// Длительность анимации прогресса опроса
    public var pollAnimationDuration: TimeInterval = 0.3

    // MARK: - Файл

    /// Размер иконки файла
    public var fileIconSize: CGFloat = 32
    /// Размер SF Symbol иконки файла
    public var fileIconPointSize: CGFloat = 16
    /// Шрифт имени файла
    public var fileNameFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// Шрифт размера файла
    public var fileSizeFont: UIFont = .systemFont(ofSize: 11)
    /// Интервал между строками файлов
    public var fileRowSpacing: CGFloat = 2
    /// Интервал между иконкой и текстом в строке файла
    public var fileContentSpacing: CGFloat = 6
    /// Внутренний отступ карточки файла
    public var filePadding: CGFloat = 6
    /// Радиус скругления карточки файла
    public var fileCornerRadius: CGFloat = 8

    // MARK: - Только эмодзи

    /// Шрифт для одного эмодзи
    public var emojiFont1: UIFont = .systemFont(ofSize: 48)
    /// Шрифт для двух эмодзи
    public var emojiFont2: UIFont = .systemFont(ofSize: 40)
    /// Шрифт для трёх эмодзи
    public var emojiFont3: UIFont = .systemFont(ofSize: 34)

    // MARK: - Разделитель дат

    /// Шрифт разделителя дат
    public var dateSeparatorFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// Вертикальный отступ разделителя дат
    public var dateSeparatorVPad: CGFloat = 4
    /// Горизонтальный отступ разделителя дат
    public var dateSeparatorHPad: CGFloat = 12
    /// Радиус скругления разделителя дат
    public var dateSeparatorCornerRadius: CGFloat = 12

    // MARK: - Коллекция

    /// Верхний отступ контента коллекции
    public var collectionTopPadding: CGFloat = 8
    /// Нижний отступ под последним сообщением
    public var collectionBottomPadding: CGFloat = 8
    /// Интервал между секциями дат
    public var sectionSpacing: CGFloat = 6

    // MARK: - Панель ввода

    /// Минимальная высота панели ввода
    public var inputBarMinHeight: CGFloat = 52
    /// Вертикальный отступ панели ввода
    public var inputBarVPad: CGFloat = 8
    /// Горизонтальный отступ панели ввода
    public var inputBarHPad: CGFloat = 12
    /// Минимальная высота поля ввода текста
    public var textViewMinHeight: CGFloat = 40
    /// Максимальная высота поля ввода до прокрутки
    public var textViewMaxHeight: CGFloat = 120
    /// Радиус скругления поля ввода текста
    public var textViewCornerRadius: CGFloat = 20
    /// Шрифт поля ввода текста
    public var textViewFont: UIFont = .systemFont(ofSize: 16)
    /// Внутренние отступы поля ввода текста (right увеличен для внутренней кнопки отправки)
    public var textViewInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 40)
    /// Высота панели ответа/редактирования
    public var inputReplyPanelHeight: CGFloat = 48
    /// Размер кнопки вложения/отправки
    public var inputButtonSize: CGFloat = 40
    /// Высота верхней разделительной линии
    public var inputSeparatorHeight: CGFloat = 0.5
    /// Интервал между элементами панели ввода
    public var inputStackSpacing: CGFloat = 6
    /// Ширина рамки поля ввода
    public var inputBorderWidth: CGFloat = 0.5
    /// Размер иконки в кнопках ввода (скрепка, mic, send)
    public var inputIconSize: CGFloat = 16
    /// Размер иконки ответа в панели ответа
    public var inputReplyIconSize: CGFloat = 10
    /// Размер кнопки отмены ответа
    public var inputReplyCancelSize: CGFloat = 20
    /// Размер иконки крестика отмены ответа
    public var inputReplyCancelIconSize: CGFloat = 10
    /// Внутренний интервал панели ответа
    public var inputReplySpacing: CGFloat = 8
    /// Шрифт стрелки отмены записи
    public var recordSlideArrowFont: UIFont = .systemFont(ofSize: 22, weight: .bold)
    /// Размер иконки плавающего микрофона
    public var recordFloatingMicIconSize: CGFloat = 18
    /// Размер иконки шеврона замка
    public var recordLockChevronSize: CGFloat = 10
    /// Размер иконки замка
    public var recordLockButtonIconSize: CGFloat = 14
    /// Отступ замка от кнопки
    public var recordLockBottomMargin: CGFloat = 8
    /// Отступ шеврона от верха замка
    public var recordLockChevronTopPad: CGFloat = 6
    /// Смещение иконки замка от центра вниз
    public var recordLockIconCenterOffset: CGFloat = 5
    /// Отступ записывающей точки от левого края
    public var recordDotLeading: CGFloat = 12
    /// Отступ таймера от точки
    public var recordTimerLeading: CGFloat = 8
    /// Смещение подсказки отмены от центра
    public var recordSlideHintOffset: CGFloat = 20
    /// Отступ placeholder от левого края textView
    public var inputPlaceholderLeading: CGFloat = 13
    /// Текст placeholder поля ввода
    public var inputPlaceholderText: String = "Сообщение"
    /// Внутренний отступ кнопки отправки от края контейнера
    public var inputSendButtonInset: CGFloat = 4
    /// Размер иконки внутренней кнопки отправки
    public var inputSendButtonIconSize: CGFloat = 14
    /// Ширина акцентной полоски панели ответа
    public var inputReplyAccentWidth: CGFloat = 2.5
    /// Шрифт имени отправителя в панели ответа
    public var inputReplySenderFont: UIFont = .systemFont(ofSize: 13, weight: .semibold)
    /// Шрифт текста превью в панели ответа
    public var inputReplyTextFont: UIFont = .systemFont(ofSize: 13)

    // MARK: - FAB (кнопка скролла вниз)

    /// Диаметр кнопки FAB
    public var fabSize: CGFloat = 40
    /// Отступ FAB над панелью ввода
    public var fabMargin: CGFloat = 12
    /// Правый отступ FAB от края экрана
    public var fabTrailingMargin: CGFloat = 16
    /// Размер иконки стрелки FAB
    public var fabArrowSize: CGFloat = 18
    /// Непрозрачность тени FAB
    public var fabShadowOpacity: Float = 0.18
    /// Радиус размытия тени FAB
    public var fabShadowRadius: CGFloat = 8
    /// Смещение тени FAB
    public var fabShadowOffset: CGSize = CGSize(width: 0, height: 2)
    /// Радиус скругления бейджа FAB
    public var fabBadgeCornerRadius: CGFloat = 10
    /// Высота бейджа FAB
    public var fabBadgeHeight: CGFloat = 20
    /// Минимальная ширина бейджа FAB
    public var fabBadgeMinWidth: CGFloat = 20
    /// Шрифт бейджа FAB
    public var fabBadgeFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
    /// Горизонтальный отступ внутри бейджа FAB
    public var fabBadgePadH: CGFloat = 6

    // MARK: - Тени пузыря

    /// Непрозрачность тени пузыря
    public var bubbleShadowOpacity: Float = 0.12
    /// Радиус размытия тени пузыря
    public var bubbleShadowRadius: CGFloat = 8

    // MARK: - Запись голоса

    /// Размер индикатора записи (красная точка)
    public var recordDotSize: CGFloat = 10
    /// Шрифт таймера записи
    public var recordTimerFont: UIFont = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
    /// Шрифт метки отмены записи
    public var recordCancelFont: UIFont = .systemFont(ofSize: 14)
    /// Размер кнопки остановки записи
    public var recordStopSize: CGFloat = 36
    /// Минимальная прозрачность точки при мигании
    public var recordDotMinAlpha: CGFloat = 0.2
    /// Размер плавающей кнопки микрофона при записи
    public var recordFloatingMicSize: CGFloat = 48
    /// Порог перетаскивания влево для отмены записи
    public var recordCancelThreshold: CGFloat = 100
    /// Порог перетаскивания вверх для блокировки записи
    public var recordLockThreshold: CGFloat = 70
    /// Размер иконки замка
    public var recordLockIconSize: CGFloat = 24
    /// Размер контейнера замка
    public var recordLockContainerSize: CGFloat = 44
    /// Размер иконки корзины при отмене
    public var recordTrashIconSize: CGFloat = 24
    /// Минимальная длительность нажатия для начала записи
    public var recordMinPressDuration: TimeInterval = 0.15
    /// Размер пульсирующего кольца в режиме блокировки
    public var recordPulseRingSize: CGFloat = 56
    /// Базовый масштаб пульсирующей кнопки отправки в режиме блокировки
    public var recordPulseBaseScale: CGFloat = 1.15
    /// Максимальный масштаб пульсирующей кнопки отправки
    public var recordPulseMaxScale: CGFloat = 1.28
    /// Длительность одного цикла пульсации (секунды)
    public var recordPulseDuration: TimeInterval = 0.6

    // MARK: - Анимации

    /// Длительность появления плавающей даты
    public var floatingDateShowDuration: TimeInterval = 0.15
    /// Длительность исчезновения плавающей даты
    public var floatingDateHideDuration: TimeInterval = 0.3
    /// Задержка перед автоскрытием плавающей даты
    public var floatingDateHideDelay: TimeInterval = 0.5
    /// Длительность появления подсветки сообщения
    public var highlightAnimateIn: TimeInterval = 0.2
    /// Длительность исчезновения подсветки сообщения
    public var highlightAnimateOut: TimeInterval = 0.6
    /// Задержка перед началом исчезновения подсветки
    public var highlightDelay: TimeInterval = 0.4
    /// Длительность анимации показа/скрытия FAB
    public var fabAnimationDuration: TimeInterval = 0.25

    // MARK: - Жесты

    /// Минимальная длительность долгого нажатия (секунды)
    public var longPressDuration: TimeInterval = 0.35

    // MARK: - Пустое состояние

    /// Шрифт текста пустого состояния
    public var emptyStateFont: UIFont = .systemFont(ofSize: 16)
    /// Горизонтальный отступ текста пустого состояния
    public var emptyStatePadding: CGFloat = 32

    // MARK: - Скролл

    /// Интервал троттлинга событий скролла (секунды)
    public var scrollThrottleInterval: TimeInterval = 1.0 / 30
    /// Интервал дебаунса подгрузки сообщений при скролле (секунды)
    public var paginationDebounceInterval: TimeInterval = 0.5

    // MARK: - Init

    public init() {}
}
