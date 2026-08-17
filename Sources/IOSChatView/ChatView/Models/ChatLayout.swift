import UIKit

public struct ChatLayout {
    // MARK: - Пузырь сообщения

    /// Радиус скругления углов пузыря сообщения
    public var bubbleCornerRadius: CGFloat = 18
    /// Ширина хвостика пузыря
    public var bubbleTailWidth: CGFloat = 6
    /// Максимальная ширина пузыря относительно ширины экрана (0…1)
    public var bubbleMaxWidthRatio: CGFloat = 0.85
    /// Минимальная ширина пузыря
    public var bubbleMinWidth: CGFloat = 60
    /// Горизонтальный внутренний отступ пузыря
    public var bubbleHPad: CGFloat = 12
    /// Вертикальный внутренний отступ пузыря
    public var bubbleVPad: CGFloat = 6
    /// Нижний внутренний отступ пузыря (под футером)
    public var bubbleBottomPad: CGFloat = 5
    /// Вертикальный интервал между элементами внутри пузыря
    public var bubbleSpacing: CGFloat = 4
    /// Интервал между текстом и медиа-контентом в пузыре
    public var mixedContentSpacing: CGFloat = 4

    // MARK: - Ячейка сообщения

    /// Горизонтальный отступ ячейки от краёв экрана
    public var cellHMargin: CGFloat = 8
    /// Вертикальный интервал между ячейками сообщений
    public var cellVSpacing: CGFloat = 2
    /// Минимальная высота ячейки сообщения
    public var cellMinHeight: CGFloat = 36
    /// Дополнительный отступ сверху и снизу системного сообщения
    public var systemCellBottomSpacing: CGFloat = 20
    /// Дополнительный отступ сверху и снизу закреплённого сообщения
    public var pinnedCellBottomSpacing: CGFloat = 32

    // MARK: - Аватарки

    /// Размер аватарки (ширина и высота)
    public var avatarSize: CGFloat = 36
    /// Отступ аватарки от левого края экрана
    public var avatarLeadingMargin: CGFloat = 6
    /// Расстояние между аватаркой и пузырём сообщения
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
    /// Шрифт заголовка пересланного сообщения
    public var forwardedFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// Ширина вертикальной акцентной полоски пересланного сообщения
    public var forwardedAccentWidth: CGFloat = 2.5
    /// Отступ контента пересланного сообщения от акцентной полоски
    public var forwardedContentInset: CGFloat = 8

    // MARK: - Футер (время, статус)

    /// Высота футера (время + статус доставки)
    public var footerHeight: CGFloat = 16
    /// Расстояние между элементами футера (время, иконка статуса)
    public var footerSpacing: CGFloat = 3
    /// Размер иконки статуса доставки сообщения
    public var statusIconSize: CGFloat = 11

    // MARK: - Превью цитаты

    /// Высота блока превью цитируемого сообщения
    public var replyHeight: CGFloat = 38
    /// Ширина вертикальной акцентной полоски цитаты
    public var replyAccentWidth: CGFloat = 2.5
    /// Радиус скругления фона цитаты
    public var replyCornerRadius: CGFloat = 6
    /// Шрифт текста цитируемого сообщения
    public var replyFont: UIFont = .systemFont(ofSize: 13)
    /// Шрифт имени автора цитируемого сообщения
    public var replySenderFont: UIFont = .systemFont(ofSize: 13, weight: .semibold)

    // MARK: - Реакции

    /// Высота чипа реакции (эмодзи + счётчик)
    public var reactionChipHeight: CGFloat = 28
    /// Расстояние между чипами реакций
    public var reactionChipSpacing: CGFloat = 4
    /// Горизонтальный внутренний отступ чипа реакции
    public var reactionChipPadding: CGFloat = 8
    /// Толщина рамки чипа реакции
    public var reactionBorderWidth: CGFloat = 1
    /// Шрифт счётчика реакции
    public var reactionFont: UIFont = .systemFont(ofSize: 13)

    // MARK: - Тред

    /// Высота индикатора треда под пузырём
    public var threadBarHeight: CGFloat = 28
    /// Шрифт текста индикатора треда
    public var threadBarFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// Расстояние между элементами индикатора треда
    public var threadBarSpacing: CGFloat = 4
    /// Размер иконки сообщения в индикаторе треда
    public var threadBarIconSize: CGFloat = 14
    /// Размер шеврона (стрелки) в индикаторе треда
    public var threadBarChevronSize: CGFloat = 10

    // MARK: - Медиа / изображения

    /// Максимальная высота изображения в пузыре
    public var imageMaxHeight: CGFloat = 280
    /// Минимальная высота изображения в пузыре
    public var imageMinHeight: CGFloat = 100
    /// Радиус скругления углов изображения
    public var imageCornerRadius: CGFloat = 12
    /// Расстояние между элементами сетки медиа (для нескольких изображений)
    public var mediaGridSpacing: CGFloat = 2
    /// Размер иконки воспроизведения поверх видео
    public var mediaPlayIconSize: CGFloat = 36
    /// Шрифт оверлея количества медиа ("+N")
    public var mediaOverlayFont: UIFont = .systemFont(ofSize: 28, weight: .semibold)
    /// Шрифт метки длительности видео
    public var mediaDurationFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    /// Радиус скругления бейджа длительности видео
    public var mediaDurationCornerRadius: CGFloat = 6
    /// Прозрачность тени иконки воспроизведения
    public var mediaPlayShadowOpacity: Float = 0.5
    /// Радиус тени иконки воспроизведения
    public var mediaPlayShadowRadius: CGFloat = 4
    /// Горизонтальный отступ внутри бейджа длительности видео
    public var mediaDurationPadH: CGFloat = 4
    /// Вертикальный отступ внутри бейджа длительности видео
    public var mediaDurationPadV: CGFloat = 2
    /// Отступ бейджа длительности от края изображения
    public var mediaDurationMargin: CGFloat = 4

    // MARK: - Видео (отдельное)

    /// Размер кнопки воспроизведения видео
    public var videoPlaySize: CGFloat = 48
    /// Шрифт метки длительности видео
    public var videoDurationFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)

    // MARK: - Голосовое сообщение

    /// Высота области волновой формы голосового сообщения
    public var voiceWaveformHeight: CGFloat = 28
    /// Ширина одного столбика волновой формы
    public var voiceBarWidth: CGFloat = 2.5
    /// Расстояние между столбиками волновой формы
    public var voiceBarSpacing: CGFloat = 2
    /// Шрифт метки длительности голосового сообщения
    public var voiceDurationFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    /// Размер кнопки воспроизведения голосового сообщения
    public var voicePlaySize: CGFloat = 36
    /// Размер иконки play/pause внутри кнопки воспроизведения
    public var voicePlayIconSize: CGFloat = 18
    /// Предпочтительная ширина области волновой формы (задаёт ширину пузыря)
    public var voiceWaveformWidth: CGFloat = 140
    /// Отступ волновой формы от правого края контента — столбики не упираются в край пузыря
    public var voiceWaveformTrailingInset: CGFloat = 8
    /// Расстояние между кнопкой воспроизведения и волновой формой
    public var voiceContentSpacing: CGFloat = 10
    /// Минимальная высота столбика волновой формы (тишина)
    public var voiceBarMinHeight: CGFloat = 2

    // MARK: - Опрос

    /// Шрифт вопроса опроса
    public var pollQuestionFont: UIFont = .systemFont(ofSize: 15, weight: .semibold)
    /// Шрифт подзаголовка опроса (тип голосования)
    public var pollSubtitleFont: UIFont = .systemFont(ofSize: 12)
    /// Шрифт текста варианта ответа
    public var pollOptionFont: UIFont = .systemFont(ofSize: 14, weight: .medium)
    /// Шрифт процента голосов
    public var pollPercentFont: UIFont = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
    /// Высота полоски прогресса варианта ответа
    public var pollBarHeight: CGFloat = 32
    /// Радиус скругления полоски прогресса
    public var pollBarCornerRadius: CGFloat = 12
    /// Расстояние между заголовком и вариантами ответа
    public var pollHeaderSpacing: CGFloat = 10
    /// Расстояние между вариантами ответа
    public var pollOptionSpacing: CGFloat = 4
    /// Шрифт счётчика голосов
    public var pollVotesFont: UIFont = .systemFont(ofSize: 12)
    /// Горизонтальный отступ внутри полоски варианта ответа
    public var pollBarHPad: CGFloat = 12
    /// Длительность анимации заполнения полоски прогресса
    public var pollAnimationDuration: TimeInterval = 0.3

    // MARK: - Файл

    /// Размер иконки типа файла
    public var fileIconSize: CGFloat = 32
    /// Размер символа внутри иконки файла (SF Symbol point size)
    public var fileIconPointSize: CGFloat = 16
    /// Шрифт имени файла
    public var fileNameFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// Шрифт размера файла
    public var fileSizeFont: UIFont = .systemFont(ofSize: 11)
    /// Вертикальное расстояние между строками файлов
    public var fileRowSpacing: CGFloat = 2
    /// Расстояние между иконкой и текстом файла
    public var fileContentSpacing: CGFloat = 6
    /// Внутренний отступ контейнера файла
    public var filePadding: CGFloat = 6
    /// Радиус скругления фона контейнера файла
    public var fileCornerRadius: CGFloat = 8

    // MARK: - Только эмодзи

    /// Шрифт для сообщения из одного эмодзи
    public var emojiFont1: UIFont = .systemFont(ofSize: 48)
    /// Шрифт для сообщения из двух эмодзи
    public var emojiFont2: UIFont = .systemFont(ofSize: 40)
    /// Шрифт для сообщения из трёх эмодзи
    public var emojiFont3: UIFont = .systemFont(ofSize: 34)

    // MARK: - Разделитель дат

    /// Шрифт текста разделителя дат
    public var dateSeparatorFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// Вертикальный внутренний отступ разделителя дат
    public var dateSeparatorVPad: CGFloat = 4
    /// Горизонтальный внутренний отступ разделителя дат
    public var dateSeparatorHPad: CGFloat = 12
    /// Радиус скругления фона разделителя дат
    public var dateSeparatorCornerRadius: CGFloat = 12

    // MARK: - Коллекция

    /// Верхний отступ содержимого коллекции
    public var collectionTopPadding: CGFloat = 8
    /// Нижний отступ содержимого коллекции
    public var collectionBottomPadding: CGFloat = 8
    /// Расстояние между секциями (группами сообщений по дате)
    public var sectionSpacing: CGFloat = 6

    // MARK: - Панель ввода

    /// Минимальная высота панели ввода
    public var inputBarMinHeight: CGFloat = 52
    /// Вертикальный отступ внутри панели ввода
    public var inputBarVPad: CGFloat = 8
    /// Горизонтальный отступ внутри панели ввода
    public var inputBarHPad: CGFloat = 12
    /// Минимальная высота текстового поля ввода
    public var textViewMinHeight: CGFloat = 40
    /// Максимальная высота текстового поля ввода (до скролла)
    public var textViewMaxHeight: CGFloat = 120
    /// Радиус скругления текстового поля ввода
    public var textViewCornerRadius: CGFloat = 20
    /// Шрифт текстового поля ввода
    public var textViewFont: UIFont = .systemFont(ofSize: 16)
    /// Внутренние отступы текстового поля (right увеличен для кнопки отправки)
    public var textViewInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 40)
    /// Высота панели превью ответа/редактирования
    public var inputReplyPanelHeight: CGFloat = 48
    /// Размер кнопок в панели ввода (вложение, голос)
    public var inputButtonSize: CGFloat = 40
    /// Высота разделительной линии над панелью ввода
    public var inputSeparatorHeight: CGFloat = 0.5
    /// Расстояние между элементами в стеке панели ввода
    public var inputStackSpacing: CGFloat = 6
    /// Толщина рамки текстового поля
    public var inputBorderWidth: CGFloat = 0.5
    /// Размер иконок кнопок панели ввода
    public var inputIconSize: CGFloat = 16
    /// Размер иконки ответа в панели превью
    public var inputReplyIconSize: CGFloat = 10
    /// Размер кнопки отмены ответа/редактирования
    public var inputReplyCancelSize: CGFloat = 20
    /// Размер иконки крестика отмены ответа
    public var inputReplyCancelIconSize: CGFloat = 10
    /// Расстояние между элементами в панели превью ответа
    public var inputReplySpacing: CGFloat = 8
    /// Шрифт стрелки подсказки «сдвиньте для отмены»
    public var recordSlideArrowFont: UIFont = .systemFont(ofSize: 22, weight: .bold)
    /// Размер иконки микрофона в плавающей кнопке записи
    public var recordFloatingMicIconSize: CGFloat = 18
    /// Размер шеврона в индикаторе блокировки записи
    public var recordLockChevronSize: CGFloat = 10
    /// Размер иконки в кнопке блокировки записи
    public var recordLockButtonIconSize: CGFloat = 14
    /// Нижний отступ контейнера блокировки записи
    public var recordLockBottomMargin: CGFloat = 8
    /// Верхний отступ шеврона блокировки записи
    public var recordLockChevronTopPad: CGFloat = 6
    /// Смещение иконки замка от центра контейнера
    public var recordLockIconCenterOffset: CGFloat = 5
    /// Отступ красной точки записи от левого края
    public var recordDotLeading: CGFloat = 12
    /// Отступ таймера записи от красной точки
    public var recordTimerLeading: CGFloat = 8
    /// Смещение подсказки «сдвиньте для отмены» от центра
    public var recordSlideHintOffset: CGFloat = 20
    /// Отступ плейсхолдера от левого края текстового поля
    public var inputPlaceholderLeading: CGFloat = 13
    /// Текст плейсхолдера в поле ввода
    public var inputPlaceholderText: String = "Сообщение"
    /// Отступ кнопки отправки от края текстового поля
    public var inputSendButtonInset: CGFloat = 4
    /// Размер иконки кнопки отправки
    public var inputSendButtonIconSize: CGFloat = 14
    /// Ширина акцентной полоски в панели превью ответа
    public var inputReplyAccentWidth: CGFloat = 2.5
    /// Шрифт имени отправителя в панели превью ответа
    public var inputReplySenderFont: UIFont = .systemFont(ofSize: 13, weight: .semibold)
    /// Шрифт текста в панели превью ответа
    public var inputReplyTextFont: UIFont = .systemFont(ofSize: 13)

    // MARK: - FAB (кнопка скролла вниз)

    /// Размер кнопки скролла вниз (FAB)
    public var fabSize: CGFloat = 40
    /// Нижний отступ FAB от края коллекции
    public var fabMargin: CGFloat = 12
    /// Правый отступ FAB от края экрана
    public var fabTrailingMargin: CGFloat = 16
    /// Размер иконки стрелки внутри FAB
    public var fabArrowSize: CGFloat = 18
    /// Прозрачность тени FAB
    public var fabShadowOpacity: Float = 0.18
    /// Радиус тени FAB
    public var fabShadowRadius: CGFloat = 8
    /// Смещение тени FAB
    public var fabShadowOffset: CGSize = CGSize(width: 0, height: 2)
    /// Радиус скругления бейджа непрочитанных на FAB
    public var fabBadgeCornerRadius: CGFloat = 10
    /// Высота бейджа непрочитанных на FAB
    public var fabBadgeHeight: CGFloat = 20
    /// Минимальная ширина бейджа непрочитанных на FAB
    public var fabBadgeMinWidth: CGFloat = 20
    /// Шрифт счётчика непрочитанных на FAB
    public var fabBadgeFont: UIFont = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
    /// Горизонтальный отступ внутри бейджа непрочитанных
    public var fabBadgePadH: CGFloat = 6

    // MARK: - Тени пузыря

    /// Прозрачность тени пузыря сообщения
    public var bubbleShadowOpacity: Float = 0.12
    /// Радиус тени пузыря сообщения
    public var bubbleShadowRadius: CGFloat = 8

    // MARK: - Запись голоса

    /// Размер мигающей красной точки индикатора записи
    public var recordDotSize: CGFloat = 10
    /// Шрифт таймера записи голоса
    public var recordTimerFont: UIFont = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
    /// Шрифт подсказки «сдвиньте для отмены»
    public var recordCancelFont: UIFont = .systemFont(ofSize: 14)
    /// Размер кнопки остановки записи (в заблокированном режиме)
    public var recordStopSize: CGFloat = 36
    /// Минимальная прозрачность мигающей точки записи
    public var recordDotMinAlpha: CGFloat = 0.2
    /// Размер плавающей кнопки микрофона при записи
    public var recordFloatingMicSize: CGFloat = 48
    /// Порог сдвига влево для отмены записи (в точках)
    public var recordCancelThreshold: CGFloat = 100
    /// Порог сдвига вверх для блокировки записи (в точках)
    public var recordLockThreshold: CGFloat = 70
    /// Размер иконки замка
    public var recordLockIconSize: CGFloat = 24
    /// Размер контейнера иконки замка
    public var recordLockContainerSize: CGFloat = 44
    /// Размер иконки корзины (удаление записи)
    public var recordTrashIconSize: CGFloat = 24
    /// Минимальная длительность нажатия для начала записи
    public var recordMinPressDuration: TimeInterval = 0.15
    /// Размер пульсирующего кольца вокруг кнопки микрофона
    public var recordPulseRingSize: CGFloat = 56
    /// Базовый масштаб пульсирующего кольца
    public var recordPulseBaseScale: CGFloat = 1.15
    /// Максимальный масштаб пульсирующего кольца
    public var recordPulseMaxScale: CGFloat = 1.28
    /// Длительность одного цикла пульсации
    public var recordPulseDuration: TimeInterval = 0.6

    // MARK: - Анимации

    /// Длительность анимации появления плавающей даты
    public var floatingDateShowDuration: TimeInterval = 0.15
    /// Длительность анимации скрытия плавающей даты
    public var floatingDateHideDuration: TimeInterval = 0.3
    /// Задержка перед скрытием плавающей даты после остановки скролла
    public var floatingDateHideDelay: TimeInterval = 0.5
    /// Длительность анимации появления подсветки сообщения
    public var highlightAnimateIn: TimeInterval = 0.2
    /// Длительность анимации затухания подсветки сообщения
    public var highlightAnimateOut: TimeInterval = 0.6
    /// Задержка перед началом затухания подсветки
    public var highlightDelay: TimeInterval = 0.4
    /// Длительность анимации появления/скрытия FAB
    public var fabAnimationDuration: TimeInterval = 0.25

    // MARK: - Жесты

    /// Минимальная длительность долгого нажатия для вызова контекстного меню
    public var longPressDuration: TimeInterval = 0.35

    // MARK: - Пустое состояние

    /// Шрифт текста пустого состояния (когда нет сообщений)
    public var emptyStateFont: UIFont = .systemFont(ofSize: 16)
    /// Отступ содержимого пустого состояния от краёв экрана
    public var emptyStatePadding: CGFloat = 32

    // MARK: - Скролл

    /// Интервал throttle для событий скролла (частота обновления)
    public var scrollThrottleInterval: TimeInterval = 1.0 / 30
    /// Интервал debounce для запросов подгрузки страниц
    public var paginationDebounceInterval: TimeInterval = 0.5

    // MARK: - Init

    public init() {}
}

// MARK: - Разделяемый экземпляр

public extension ChatLayout {
    /// Дефолтный экземпляр для переиспользования: создание `ChatLayout()`
    /// инициализирует ~30 шрифтов — не создавайте новые в горячих путях.
    static let shared = ChatLayout()
}
