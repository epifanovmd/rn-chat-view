import UIKit

struct ChatLayout {
    // MARK: - Пузырь сообщения

    /// Радиус скругления пузыря
    var bubbleCornerRadius: CGFloat = 18
    /// Ширина хвостика пузыря
    var bubbleTailWidth: CGFloat = 6
    /// Макс. ширина пузыря как доля ширины экрана
    var bubbleMaxWidthRatio: CGFloat = 0.78
    /// Минимальная ширина пузыря
    var bubbleMinWidth: CGFloat = 60
    /// Горизонтальный отступ внутри пузыря
    var bubbleHPad: CGFloat = 12
    /// Вертикальный отступ сверху внутри пузыря
    var bubbleVPad: CGFloat = 6
    /// Отступ снизу пузыря после футера
    var bubbleBottomPad: CGFloat = 5
    /// Вертикальный интервал между элементами внутри пузыря
    var bubbleSpacing: CGFloat = 4
    /// Интервал между медиа и текстом в смешанном контенте
    var mixedContentSpacing: CGFloat = 4

    // MARK: - Ячейка сообщения

    /// Горизонтальный отступ пузыря от края экрана
    var cellHMargin: CGFloat = 8
    /// Вертикальный интервал между ячейками сообщений
    var cellVSpacing: CGFloat = 2
    /// Минимальная высота ячейки
    var cellMinHeight: CGFloat = 36

    // MARK: - Шрифты контента

    /// Шрифт текста сообщения
    var messageFont: UIFont = .systemFont(ofSize: 16)
    /// Шрифт имени отправителя
    var senderNameFont: UIFont = .systemFont(ofSize: 13, weight: .semibold)
    /// Шрифт метки времени
    var timeFont: UIFont = .systemFont(ofSize: 11)
    /// Шрифт метки «изменено»
    var editedFont: UIFont = .systemFont(ofSize: 11)
    /// Шрифт метки «переслано»
    var forwardedFont: UIFont = .systemFont(ofSize: 13, weight: .medium)

    // MARK: - Футер (время, статус)

    /// Высота строки футера
    var footerHeight: CGFloat = 16
    /// Интервал между элементами футера
    var footerSpacing: CGFloat = 3
    /// Размер иконки статуса доставки
    var statusIconSize: CGFloat = 14

    // MARK: - Превью цитаты

    /// Высота блока превью цитаты
    var replyHeight: CGFloat = 38
    /// Ширина акцентной полоски цитаты
    var replyAccentWidth: CGFloat = 2.5
    /// Радиус скругления блока цитаты
    var replyCornerRadius: CGFloat = 6
    /// Шрифт текста превью цитаты
    var replyFont: UIFont = .systemFont(ofSize: 13)
    /// Шрифт имени отправителя в цитате
    var replySenderFont: UIFont = .systemFont(ofSize: 13, weight: .semibold)

    // MARK: - Реакции

    /// Высота чипа реакции
    var reactionChipHeight: CGFloat = 28
    /// Интервал между чипами реакций
    var reactionChipSpacing: CGFloat = 4
    /// Горизонтальный отступ внутри чипа реакции
    var reactionChipPadding: CGFloat = 8
    /// Ширина рамки чипа моей реакции
    var reactionBorderWidth: CGFloat = 1
    /// Шрифт текста реакции
    var reactionFont: UIFont = .systemFont(ofSize: 13)

    // MARK: - Медиа / изображения

    /// Максимальная высота изображения/видео
    var imageMaxHeight: CGFloat = 280
    /// Минимальная высота изображения/видео
    var imageMinHeight: CGFloat = 100
    /// Радиус скругления изображения/видео
    var imageCornerRadius: CGFloat = 12
    /// Интервал между ячейками в сетке медиа
    var mediaGridSpacing: CGFloat = 2
    /// Размер иконки воспроизведения в сетке медиа
    var mediaPlayIconSize: CGFloat = 36
    /// Шрифт оверлея «+N» на сетке медиа
    var mediaOverlayFont: UIFont = .systemFont(ofSize: 28, weight: .semibold)
    /// Шрифт бейджа длительности видео в сетке
    var mediaDurationFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    /// Радиус скругления бейджа длительности
    var mediaDurationCornerRadius: CGFloat = 6
    /// Непрозрачность тени иконки воспроизведения
    var mediaPlayShadowOpacity: Float = 0.5
    /// Радиус размытия тени иконки воспроизведения
    var mediaPlayShadowRadius: CGFloat = 4
    /// Горизонтальный отступ внутри бейджа длительности
    var mediaDurationPadH: CGFloat = 4
    /// Вертикальный отступ внутри бейджа длительности
    var mediaDurationPadV: CGFloat = 2
    /// Отступ бейджа длительности от края
    var mediaDurationMargin: CGFloat = 4

    // MARK: - Видео (отдельное)

    /// Размер кнопки воспроизведения для отдельного видео
    var videoPlaySize: CGFloat = 48
    /// Шрифт длительности видео
    var videoDurationFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)

    // MARK: - Голосовое сообщение

    /// Высота визуализации волны
    var voiceWaveformHeight: CGFloat = 28
    /// Ширина полоски волны
    var voiceBarWidth: CGFloat = 2.5
    /// Интервал между полосками волны
    var voiceBarSpacing: CGFloat = 2
    /// Шрифт длительности голосового
    var voiceDurationFont: UIFont = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
    /// Размер кнопки воспроизведения голосового
    var voicePlaySize: CGFloat = 36
    /// Размер иконки воспроизведения голосового
    var voicePlayIconSize: CGFloat = 18

    // MARK: - Опрос

    /// Шрифт вопроса опроса
    var pollQuestionFont: UIFont = .systemFont(ofSize: 15, weight: .semibold)
    /// Шрифт текста варианта опроса
    var pollOptionFont: UIFont = .systemFont(ofSize: 15)
    /// Высота полосы варианта опроса
    var pollBarHeight: CGFloat = 30
    /// Радиус скругления полосы варианта
    var pollBarCornerRadius: CGFloat = 6
    /// Интервал после вопроса опроса
    var pollSpacing: CGFloat = 6
    /// Интервал между вариантами опроса
    var pollOptionSpacing: CGFloat = 4
    /// Шрифт счётчика голосов опроса
    var pollVotesFont: UIFont = .systemFont(ofSize: 13)
    /// Размер иконки галочки опроса
    var pollCheckmarkSize: CGFloat = 14
    /// Левый отступ галочки опроса
    var pollCheckmarkLeading: CGFloat = 8
    /// Левый отступ текста варианта опроса
    var pollLabelLeading: CGFloat = 6
    /// Правый отступ процентов варианта опроса
    var pollPercentTrailing: CGFloat = 8
    /// Прозрачность невыбранной полосы варианта
    var pollUnselectedAlpha: CGFloat = 0.3

    // MARK: - Файл

    /// Размер иконки файла
    var fileIconSize: CGFloat = 40
    /// Размер SF Symbol иконки файла
    var fileIconPointSize: CGFloat = 22
    /// Шрифт имени файла
    var fileNameFont: UIFont = .systemFont(ofSize: 15, weight: .medium)
    /// Шрифт размера файла
    var fileSizeFont: UIFont = .systemFont(ofSize: 13)
    /// Интервал между строками файлов
    var fileRowSpacing: CGFloat = 2
    /// Интервал между иконкой и текстом в строке файла
    var fileContentSpacing: CGFloat = 8

    // MARK: - Только эмодзи

    /// Шрифт для одного эмодзи
    var emojiFont1: UIFont = .systemFont(ofSize: 48)
    /// Шрифт для двух эмодзи
    var emojiFont2: UIFont = .systemFont(ofSize: 40)
    /// Шрифт для трёх эмодзи
    var emojiFont3: UIFont = .systemFont(ofSize: 34)

    // MARK: - Разделитель дат

    /// Шрифт разделителя дат
    var dateSeparatorFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// Вертикальный отступ разделителя дат
    var dateSeparatorVPad: CGFloat = 4
    /// Горизонтальный отступ разделителя дат
    var dateSeparatorHPad: CGFloat = 12
    /// Радиус скругления разделителя дат
    var dateSeparatorCornerRadius: CGFloat = 12

    // MARK: - Коллекция

    /// Верхний отступ контента коллекции
    var collectionTopPadding: CGFloat = 8
    /// Нижний отступ под последним сообщением
    var collectionBottomPadding: CGFloat = 8
    /// Интервал между секциями дат
    var sectionSpacing: CGFloat = 6

    // MARK: - Панель ввода

    /// Минимальная высота панели ввода
    var inputBarMinHeight: CGFloat = 52
    /// Вертикальный отступ панели ввода
    var inputBarVPad: CGFloat = 8
    /// Горизонтальный отступ панели ввода
    var inputBarHPad: CGFloat = 8
    /// Минимальная высота поля ввода текста
    var textViewMinHeight: CGFloat = 36
    /// Максимальная высота поля ввода до прокрутки
    var textViewMaxHeight: CGFloat = 120
    /// Радиус скругления поля ввода текста
    var textViewCornerRadius: CGFloat = 18
    /// Шрифт поля ввода текста
    var textViewFont: UIFont = .systemFont(ofSize: 16)
    /// Внутренние отступы поля ввода текста
    var textViewInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    /// Высота панели ответа/редактирования
    var inputReplyPanelHeight: CGFloat = 48
    /// Размер кнопки вложения/отправки
    var inputButtonSize: CGFloat = 36
    /// Высота верхней разделительной линии
    var inputSeparatorHeight: CGFloat = 0.5
    /// Интервал между элементами панели ввода
    var inputStackSpacing: CGFloat = 6
    /// Ширина рамки поля ввода
    var inputBorderWidth: CGFloat = 0.5
    /// Размер иконки ответа в панели
    var inputReplyIconSize: CGFloat = 16
    /// Размер кнопки отмены ответа
    var inputReplyCancelSize: CGFloat = 28
    /// Внутренний интервал панели ответа
    var inputReplySpacing: CGFloat = 8

    // MARK: - FAB (кнопка скролла вниз)

    /// Диаметр кнопки FAB
    var fabSize: CGFloat = 40
    /// Отступ FAB над панелью ввода
    var fabMargin: CGFloat = 12
    /// Правый отступ FAB от края экрана
    var fabTrailingMargin: CGFloat = 16
    /// Размер иконки стрелки FAB
    var fabArrowSize: CGFloat = 18
    /// Непрозрачность тени FAB
    var fabShadowOpacity: Float = 0.18
    /// Радиус размытия тени FAB
    var fabShadowRadius: CGFloat = 8
    /// Смещение тени FAB
    var fabShadowOffset: CGSize = CGSize(width: 0, height: 2)
    /// Радиус скругления бейджа FAB
    var fabBadgeCornerRadius: CGFloat = 10
    /// Высота бейджа FAB
    var fabBadgeHeight: CGFloat = 20
    /// Минимальная ширина бейджа FAB
    var fabBadgeMinWidth: CGFloat = 20
    /// Шрифт бейджа FAB
    var fabBadgeFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
    /// Горизонтальный отступ внутри бейджа FAB
    var fabBadgePadH: CGFloat = 6

    // MARK: - Тени пузыря

    /// Непрозрачность тени пузыря
    var bubbleShadowOpacity: Float = 0.12
    /// Радиус размытия тени пузыря
    var bubbleShadowRadius: CGFloat = 8

    // MARK: - Запись голоса

    /// Размер индикатора записи (красная точка)
    var recordDotSize: CGFloat = 10
    /// Шрифт таймера записи
    var recordTimerFont: UIFont = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
    /// Шрифт метки отмены записи
    var recordCancelFont: UIFont = .systemFont(ofSize: 14)
    /// Размер кнопки остановки записи
    var recordStopSize: CGFloat = 36
    /// Минимальная прозрачность точки при мигании
    var recordDotMinAlpha: CGFloat = 0.2

    // MARK: - Анимации

    /// Длительность появления плавающей даты
    var floatingDateShowDuration: TimeInterval = 0.15
    /// Длительность исчезновения плавающей даты
    var floatingDateHideDuration: TimeInterval = 0.3
    /// Задержка перед автоскрытием плавающей даты
    var floatingDateHideDelay: TimeInterval = 1.5
    /// Длительность появления подсветки сообщения
    var highlightAnimateIn: TimeInterval = 0.2
    /// Длительность исчезновения подсветки сообщения
    var highlightAnimateOut: TimeInterval = 0.6
    /// Задержка перед началом исчезновения подсветки
    var highlightDelay: TimeInterval = 0.4
    /// Длительность анимации показа/скрытия FAB
    var fabAnimationDuration: TimeInterval = 0.25

    // MARK: - Жесты

    /// Минимальная длительность долгого нажатия (секунды)
    var longPressDuration: TimeInterval = 0.35

    // MARK: - Пустое состояние

    /// Шрифт текста пустого состояния
    var emptyStateFont: UIFont = .systemFont(ofSize: 16)
    /// Горизонтальный отступ текста пустого состояния
    var emptyStatePadding: CGFloat = 32

    // MARK: - Скролл

    /// Интервал троттлинга событий скролла (секунды)
    var scrollThrottleInterval: TimeInterval = 1.0 / 30
    /// Интервал дебаунса отслеживания видимости (секунды)
    var visibilityDebounceInterval: TimeInterval = 0.3
}

// MARK: - Общий экземпляр по умолчанию

extension ChatLayout {
    /// Общий экземпляр layout, используемый во всём приложении.
    static var current = ChatLayout()
}
