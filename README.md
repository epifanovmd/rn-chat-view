# IOSChatView

Готовая к продакшену iOS библиотека компонентов чат-интерфейса. Построена на UIKit + DifferenceKit для высокопроизводительного рендеринга сообщений при 100K+ сообщениях.

## Возможности

### Типы сообщений
- [x] Текстовые сообщения (одно-/многострочные, ссылки)
- [x] Эмодзи-сообщения (1-3 эмодзи, крупный шрифт, без пузыря)
- [x] Изображения (одно изображение с сохранением пропорций)
- [x] Видеосообщения (превью + иконка воспроизведения + бейдж длительности)
- [x] Сетка медиа (2-4 элемента, оверлей +N)
- [x] Смешанный контент (медиа + текстовая подпись)
- [x] Голосовые сообщения (визуализация волновой формы, воспроизведение, перемотка)
- [x] Опросы (одиночный/множественный выбор, анонимные, закрываемые)
- [x] Файловые вложения (иконка по расширению, имя, размер)
- [x] Пересланные сообщения (акцентная полоска + метка отправителя)
- [x] Превью ответов (цитата сообщения с отправителем + текстом)
- [x] Пользовательские типы контента (через `MessageMedia.custom`)
- [x] Системные сообщения (по центру, нейтральное оформление)
- [x] Закреплённые сообщения (пузырь по центру, контент выровнен влево)
- [x] Обсуждения в тредах (закреплённый корень + ответы)

### Функции сообщений
- [x] Реакции (эмодзи-чипы со счётчиком, подсветка своих)
- [x] Статус сообщения (отправляется, отправлено, доставлено, прочитано)
- [x] Метка редактирования
- [x] Временная метка
- [x] Имя отправителя (никогда / только входящие / всегда)
- [x] Подсветка сообщения при прокрутке к нему
- [x] Индикатор треда (количество ответов, последний отвечающий, нажатие для открытия)
- [x] Прилипающие аватары (группировка по отправителю, supplementary views)
- [x] Распознавание ссылок (URL и номера телефонов, колбэки при нажатии)
- [x] Владение сообщением (своё/чужое/системное/закреплённое — выравнивание)

### Панель ввода
- [x] Автоувеличивающееся поле ввода (1-5 строк)
- [x] Кнопка отправки (появляется при наличии текста)
- [x] Кнопка вложения (настраиваемая)
- [x] Запись голоса (долгое нажатие, свайп для отмены/блокировки)
- [x] Режим ответа (с панелью превью)
- [x] Режим редактирования (с панелью превью)
- [x] Тактильная обратная связь

### Список чата
- [x] Анимированные диффы DifferenceKit (алгоритм Heckel за O(n))
- [x] Кастомный `UICollectionViewLayout` с предвычисленными высотами
- [x] Кэш размеров для получения высоты ячейки за O(1)
- [x] FAB прокрутки вниз с бейджем непрочитанных
- [x] Плавающая таблетка с датой при прокрутке
- [x] Разделители дат между группами сообщений
- [x] Компенсация прокрутки при подгрузке (загрузка старых сообщений без скачка)
- [x] Сохранение позиции при добавлении (новые сообщения при прокрутке вверх)
- [x] Пустое состояние (спиннер + текст «нет сообщений»)
- [x] Индикаторы загрузки сверху/снизу
- [x] Пагинация (по порогу, сверху + снизу)
- [x] Отслеживание видимости (события появления сообщений)
- [x] Анимированное удаление/редактирование/перемещение

### Контекстное меню
- [x] Всплывающее окно по долгому нажатию со снимком
- [x] Панель быстрых эмодзи-реакций
- [x] Список действий (ответить, редактировать, копировать, удалить и т.д.)
- [x] Заморозка/восстановление клавиатуры при закрытии
- [x] Пружинные анимации

### Кастомизация
- [x] `ChatTheme` — 66 свойств цвета (пресеты светлая/тёмная), цвета системных/закреплённых сообщений
- [x] `ChatLayout` — 169 констант компоновки (шрифты, размеры, отступы)
- [x] `ChatFeatures` — 25 флагов функций
- [x] `ChatContentFactory` — полная кастомизация view через протокол
- [x] Вью аватаров через протокол фабрики
- [x] `InputBarTheme` — независимая тема панели ввода
- [x] `ContextMenuTheme` — тема контекстного меню (пресеты светлая/тёмная)
- [x] Пользовательские типы контента через протокол `ChatContent` (типобезопасные, расширяемые)
- [x] `batchUpdate {}` — атомарное изменение конфигурации (один reload)
- [x] Ядро не знает о типах контента — библиотека не зависит от конкретных типов сообщений
- [x] См. [CUSTOMIZATION.md](CUSTOMIZATION.md) для полного руководства по пользовательским типам

---

## Установка

### CocoaPods

```ruby
pod 'IOSChatView', :path => '../rn-chat-view'
pod 'DifferenceKit', :modular_headers => true

# или из git:
# pod 'IOSChatView', :git => 'https://github.com/epifanovmd/rn-chat-view.git'
```

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/epifanovmd/rn-chat-view.git", from: "1.0.0")
]
```

### Требования

- iOS 15.0+
- Swift 5.9+
- DifferenceKit 1.3+

---

## Быстрый старт

```swift
import IOSChatView

class MyChatVC: UIViewController, ChatViewControllerDelegate {
    private let chatVC = ChatViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Конфигурация
        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥"]

        // 2. Встроить как дочерний контроллер
        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.frame = view.bounds
        chatVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chatVC.didMove(toParent: self)

        // 3. Загрузить сообщения
        chatVC.hasMore = true  // включить пагинацию сверху
        chatVC.updateMessages(myMessages)
    }

    // MARK: - Отправка сообщения

    func chatDidSendMessage(text: String, replyToId: String?) {
        let msg = createMessage(text: text, replyToId: replyToId)
        chatVC.updateMessages(chatVC.messages + [msg])
        chatVC.clearInputMode()
    }

    // MARK: - Пагинация

    func chatDidReachTop(distance: CGFloat) {
        chatVC.isLoadingTop = true
        api.loadOlderMessages { [weak self] older in
            guard let self else { return }
            chatVC.isLoadingTop = false
            chatVC.hasMore = older.count >= pageSize
            chatVC.updateMessages(older + chatVC.messages)
        }
    }

    // MARK: - Действия с сообщениями

    func chatDidSelectAction(actionId: String, messageId: String) {
        switch actionId {
        case "reply":
            if let msg = chatVC.message(forID: messageId) {
                chatVC.beginReply(info: ReplyInfo(
                    replyToId: messageId,
                    senderName: msg.senderName,
                    text: msg.content.text,
                    hasImage: false
                ))
            }
        case "edit":
            if let msg = chatVC.message(forID: messageId) {
                chatVC.beginEdit(messageId: messageId, text: msg.content.text ?? "")
            }
        case "delete":
            var msgs = chatVC.messages
            msgs.removeAll { $0.id == messageId }
            chatVC.updateMessages(msgs)  // анимированное удаление
        default: break
        }
    }

    func chatDidEditMessage(text: String, messageId: String) {
        // Обновить сообщение на сервере, затем обновить список сообщений
        chatVC.clearInputMode()
    }

    // MARK: - Реакции

    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {
        // Переключить реакцию на сервере, затем обновить сообщения
    }

    func chatDidTapReaction(messageId: String, emoji: String) {
        // Переключить существующую реакцию
    }

    // MARK: - Навигация

    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }

    func chatDidTapFAB() {
        chatVC.clearUnread()
        chatVC.scrollToBottom(animated: true)
    }

    // MARK: - Остальные делегаты

    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachBottom(distance: CGFloat) {}
    func chatVisibleMessagesDidChange(ids: [String]) { /* отслеживание прокрутки */ }
    func chatUnreadMessagesDidAppear(ids: [String]) { /* отметить прочитанным на сервере */ }
    func chatDidTapMessage(id: String, attachmentIndex: Int?) { /* открыть просмотр медиа */ }
    func chatDidTapThread(messageId: String, threadId: String) { /* открыть вид треда */ }
    func chatDidTapLink(url: URL, messageId: String) { UIApplication.shared.open(url) }
    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String) {}
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() { /* показать выбор изображения */ }
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {
        // Загрузить голосовой файл, создать голосовое сообщение
    }
    func chatDidChangeInputText(_ text: String) { /* индикатор набора */ }
    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
        // Обработать взаимодействия с контентом (голосование в опросе, пользовательские нажатия и т.д.)
    }
}
```

---

## Сообщения

### Создание сообщений

```swift
// Текстовое сообщение
let textMsg = ChatMessage(
    id: "1",
    localId: nil,                  // для маппинга pending→real
    content: MessageBody(text: "Привет!"),
    timestamp: Date(),
    senderName: "Алиса",
    ownership: .theirs,
    groupDate: "2026-04-06",
    status: .read,
    reply: nil,
    forwardedFrom: nil,
    reactions: [],
    isEdited: false,
    actions: []
)

// Сообщение с изображением и подписью (с использованием встроенного ImagesContent)
let imageMsg = ChatMessage(
    id: "2",
    localId: nil,
    content: MessageBody(
        text: "Посмотри!",
        content: AnyChatContent(ImagesContent([
            .image(ImageItem(url: "https://example.com/photo.jpg", width: 400, height: 300, thumbnailUrl: nil))
        ]))
    ),
    timestamp: Date(),
    senderName: nil,
    ownership: .mine,
    groupDate: "2026-04-06",
    status: .sent,
    reply: nil,
    forwardedFrom: nil,
    reactions: [Reaction(emoji: "👍", count: 2, isSelected: true)],
    isEdited: false,
    actions: []
)

// Голосовое сообщение (с использованием встроенного VoicePayload)
let voiceMsg = ChatMessage(
    id: "3",
    content: MessageBody(
        content: AnyChatContent(VoicePayload(url: "https://...", duration: 12.5, waveform: [0.2, 0.5, 0.8, 0.3]))
    ),
    // ...
)

// Опрос (с использованием встроенного PollPayload)
let pollMsg = ChatMessage(
    id: "4",
    content: MessageBody(
        content: AnyChatContent(PollPayload(
            id: "poll1", question: "Любимый цвет?",
            options: [
                PollOption(id: "r", text: "Красный", votes: 5, percentage: 0.5),
                PollOption(id: "b", text: "Синий", votes: 5, percentage: 0.5),
            ],
            totalVotes: 10, selectedOptionIds: ["r"],
            isMultipleChoice: false, isClosed: false, isAnonymous: false
        ))
    ),
    // ...
)

// Пользовательский тип контента — определите свою структуру, реализующую ChatContent
struct LocationContent: ChatContent {
    static let contentTypeID = "location"
    let latitude: Double
    let longitude: Double
    let address: String
}

let locationMsg = ChatMessage(
    id: "5",
    content: MessageBody(
        text: "Моя геопозиция",
        content: AnyChatContent(LocationContent(latitude: 55.75, longitude: 37.62, address: "Москва"))
    ),
    // ...
)
// Системное сообщение (по центру, нейтральное оформление)
let systemMsg = ChatMessage(
    id: "6",
    localId: nil,
    content: MessageBody(text: "Алиса присоединилась к группе"),
    timestamp: Date(),
    senderName: nil,
    ownership: .system,
    groupDate: "2026-04-06",
    status: .read,
    reply: nil,
    forwardedFrom: nil,
    reactions: [],
    isEdited: false,
    actions: []
)

// Закреплённое сообщение (пузырь по центру, контент выровнен влево)
let pinnedMsg = ChatMessage(
    id: "7",
    localId: nil,
    content: MessageBody(text: "Встреча завтра в 15:00"),
    timestamp: Date(),
    senderName: "Админ",
    ownership: .pinned,
    groupDate: "2026-04-06",
    status: .read,
    reply: nil,
    forwardedFrom: nil,
    reactions: [],
    isEdited: false,
    actions: []
)

// См. CUSTOMIZATION.md для полного руководства по пользовательским типам контента
```

### Действия с сообщениями

Определение действий контекстного меню для каждого сообщения:

```swift
let actions = [
    MessageAction(id: "reply", title: "Ответить", systemImage: "arrowshape.turn.up.left", isDestructive: false),
    MessageAction(id: "edit", title: "Редактировать", systemImage: "pencil", isDestructive: false),
    MessageAction(id: "copy", title: "Копировать", systemImage: "doc.on.doc", isDestructive: false),
    MessageAction(id: "forward", title: "Переслать", systemImage: "arrowshape.turn.up.right", isDestructive: false),
    MessageAction(id: "delete", title: "Удалить", systemImage: "trash", isDestructive: true),
]
```

### Обновление сообщений

```swift
// Полное обновление — библиотека автоматически определяет тип:
// - Первичная загрузка (было пусто)
// - Подгрузка сверху (старые сообщения, с компенсацией прокрутки)
// - Добавление снизу (новые сообщения, авто-прокрутка если рядом с низом)
// - Изменение контента (редактирование, удаление, реакции — анимированный diff)
chatVC.updateMessages(newMessages)
```

### Прокрутка и навигация

```swift
chatVC.scrollToBottom(animated: true)
chatVC.scrollToMessage(id: "msg-42", position: "center", animated: true, highlight: true)
// position: "top", "center", "bottom"

// Точное восстановление позиции прокрутки при первичной загрузке
chatVC.pendingScrollAnchor = ScrollAnchor(messageId: "msg-42", offset: 0, wasAtBottom: false)
chatVC.updateMessages(messages)

// Управление непрочитанными
chatVC.clearUnread()
chatVC.setUnreadCount(5)  // включает внешнее управление непрочитанными
```

---

## Тема

```swift
// Использование пресетов
chatVC.theme = .light
chatVC.theme = .dark

// Кастомизация отдельных цветов
var theme = ChatTheme.dark
theme.outgoingBubble = .systemBlue
theme.incomingSenderName = .systemOrange
theme.fabBackground = .systemGray6
chatVC.theme = theme
```

### Группы цветов

| Группа | Свойства |
|---|---|
| Фон | `backgroundColor`, `wallpaperColor` |
| Исходящий пузырь | `outgoingBubble`, `outgoingText`, `outgoingTime`, `outgoingStatus`, `outgoingStatusRead`, `outgoingEdited`, `outgoingLink` |
| Входящий пузырь | `incomingBubble`, `incomingText`, `incomingTime`, `incomingEdited`, `incomingSenderName`, `incomingLink` |
| Превью ответа | `outgoing/incomingReplyBackground`, `outgoing/incomingReplyAccent`, `outgoing/incomingReplySender`, `outgoing/incomingReplyText` |
| Пересылка | `outgoing/incomingForwardedLabel`, `outgoing/incomingForwardedAccent` |
| Файлы | `outgoingFileBackground`, `incomingFileBackground`, `fileIconColor` |
| Реакции | `reactionBackground`, `reactionMineBackground`, `reactionText`, `reactionMineBorder` |
| Разделитель дат | `dateSeparatorBackground`, `dateSeparatorText` |
| FAB | `fabBackground`, `fabBorder`, `fabBlurStyle`, `fabArrowColor`, `fabBadgeBackground`, `fabBadgeTextColor`, `fabShadowColor` |
| Голос | `voiceWaveformActive`, `voiceWaveformInactive` |
| Опросы | `pollBarFilled`, `pollBarEmpty`, `pollSelectedBorder`, `pollSubtitleColor` |
| Медиа | `mediaPlaceholderBackground`, `mediaPlayIconColor`, `mediaPlayShadowColor`, `mediaDurationBackground`, `mediaDurationTextColor`, `mediaOverlayBackground`, `mediaOverlayTextColor` |
| Подсветка | `messageHighlightColor` |
| Пустое состояние | `emptyStateText` |

---

## Компоновка

169 параметров компоновки для точной настройки до пикселя:

```swift
var layout = ChatLayout()

// Пузырь
layout.bubbleCornerRadius = 20
layout.bubbleMaxWidthRatio = 0.8
layout.bubbleHPad = 12
layout.bubbleVPad = 8

// Шрифты
layout.messageFont = .systemFont(ofSize: 16)
layout.senderNameFont = .boldSystemFont(ofSize: 13)
layout.timeFont = .systemFont(ofSize: 11)

// Отступы
layout.cellVSpacing = 4
layout.cellHMargin = 8

// Медиа
layout.imageMaxHeight = 280
layout.imageCornerRadius = 12
layout.mediaGridSpacing = 2

// Голос
layout.voiceWaveformHeight = 32
layout.voiceBarWidth = 3
layout.voiceBarSpacing = 2

// Опросы
layout.pollBarHeight = 8
layout.pollBarCornerRadius = 4

// Панель ввода
layout.inputBarMinHeight = 52
layout.textViewCornerRadius = 20
layout.textViewFont = .systemFont(ofSize: 16)

chatVC.layout = layout
```

### Пакетное обновление

Применение нескольких изменений конфигурации атомарно (один reload):

```swift
chatVC.batchUpdate {
    chatVC.theme = .dark
    chatVC.layout = customLayout
    chatVC.features.showFab = false
    chatVC.features.showDateSeparators = true
}
```

---

## Флаги функций

```swift
var features = ChatFeatures()

// Сообщения
features.senderNameMode = .incomingOnly  // .never | .incomingOnly | .always
features.showMessageStatus = true        // иконки отправлено/доставлено/прочитано
features.showTimestamp = true
features.showEditedMark = true
features.showReactions = true
features.showReplyPreview = true
features.showForwardedMark = true

// Список
features.showFab = true                  // плавающая кнопка действия
features.showFloatingDate = true         // таблетка даты при прокрутке
features.showDateSeparators = true       // заголовки дат между группами
features.showTopLoadingIndicator = true
features.showBottomLoadingIndicator = true
features.showEmptyState = true           // вид «нет сообщений»

// Ввод
features.showInputBar = true
features.showAttachButton = true
features.showVoiceRecording = true

// Контекстное меню
features.contextMenuEnabled = true
features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥", "🎉", "👎"]

// Пороги прокрутки (расстояние от края для срабатывания пагинации, в точках)
features.topLoadThreshold = 200
features.bottomLoadThreshold = 200
features.scrollToBottomThreshold = 150
features.autoScrollOnNewMessage = true

chatVC.features = features
```

---

## Фабрика контента (продвинутая кастомизация)

Библиотека не зависит от типов контента — весь рендеринг делегируется `ChatContentFactory`. Наследуйте `DefaultChatContentFactory` для добавления пользовательских типов или кастомизации встроенных view:

```swift
class MyFactory: DefaultChatContentFactory {

    // Обработка пользовательских типов контента
    override func contentView(for media: AnyChatContent, message: ChatMessage,
                              width: CGFloat, theme: ChatTheme, layout: ChatLayout,
                              onInteraction: @escaping (ChatContentInteraction) -> Void) -> UIView {
        if let location = media.content(as: LocationContent.self) {
            let view = LocationMapView()
            view.configure(location: location)
            view.onTap = {
                onInteraction(ChatContentInteraction(type: "locationTap", payload: [
                    "lat": location.latitude as AnyHashable,
                    "lon": location.longitude as AnyHashable,
                ]))
            }
            return view
        }
        return super.contentView(for: media, message: message, width: width,
                                 theme: theme, layout: layout, onInteraction: onInteraction)
    }

    // Высота пользовательского контента
    override func contentHeight(for media: AnyChatContent, width: CGFloat, layout: ChatLayout) -> CGFloat {
        if media.content(as: LocationContent.self) != nil { return 200 }
        return super.contentHeight(for: media, width: width, layout: layout)
    }
}

chatVC.contentFactory = MyFactory()
```

Полное руководство по пользовательским типам контента, паттернам фабрики и обработке взаимодействий см. в **[CUSTOMIZATION.md](CUSTOMIZATION.md)**.

### Все методы фабрики

| Метод | Назначение |
|---|---|
| `contentView(for:message:width:theme:layout:onInteraction:)` | Рендеринг контента (любой тип) |
| `contentHeight(for:width:layout:)` | Вычисление высоты контента |
| `reconfigureContentView(_:for:message:...)` | Обновление контента на месте (анимации) |
| `textView(text:ownership:theme:layout:)` | Текстовая часть сообщения |
| `textHeight(text:font:width:)` | Вычисление высоты текста |
| `emojiView(text:emojiCount:layout:)` | Эмодзи-сообщения (1-3 эмодзи) |
| `reactionsView(reactions:theme:maxWidth:layout:onTap:)` | Панель чипов реакций |
| `replyPreviewView(reply:resolved:ownership:theme:layout:onTap:)` | Блок цитаты сообщения |
| `footerView(message:theme:layout:features:)` | Время + метка редактирования + иконка статуса |
| `senderNameView(name:theme:layout:)` | Метка имени отправителя |
| `forwardedHeaderView(from:ownership:theme:layout:)` | Заголовок «Переслано от X» |
| `dateSeparatorView(title:theme:layout:)` | Таблетка разделителя дат |
| `dateSeparatorHeight(layout:)` | Высота разделителя дат |
| `floatingDateView(title:theme:layout:)` | Плавающая дата при прокрутке |
| `emptyStateView(theme:layout:)` | Заглушка пустого состояния |
| `emptyStateLoadingView(theme:layout:)` | Спиннер загрузки в пустом состоянии |
| `loadingIndicatorView(theme:layout:)` | Индикатор загрузки пагинации |
| `fabView(theme:layout:)` | FAB кнопка прокрутки вниз |
| `fabBadgeView(theme:layout:)` | Бейдж непрочитанных на FAB |
| `threadIndicatorView(thread:ownership:theme:layout:onTap:)` | Индикатор треда (количество ответов) |
| `avatarView(name:url:size:theme:layout:)` | Прилипающий аватар отправителя |

---

## Справочник делегатов

```swift
// Составной протокол (реализуйте все 4):
typealias ChatViewControllerDelegate =
    ChatScrollDelegate & ChatVisibilityDelegate & ChatMessageDelegate & ChatInputDelegate
```

### ChatScrollDelegate

```swift
func chatDidScroll(offset: CGPoint)          // позиция прокрутки изменилась
func chatDidReachTop(distance: CGFloat)      // рядом с верхом — загрузить старые сообщения
func chatDidReachBottom(distance: CGFloat)   // рядом с низом — загрузить новые сообщения
func chatDidTapFAB()                         // нажата кнопка прокрутки вниз
func chatScrollAnchorChanged(anchor: ScrollAnchor)  // с троттлингом ~300мс, для сохранения позиции прокрутки
```

### ChatVisibilityDelegate

```swift
func chatVisibleMessagesDidChange(ids: [String])  // снимок видимых сообщений с троттлингом
func chatUnreadMessagesDidAppear(ids: [String])   // пакет непрочитанных с дебаунсом (для отчётов о прочтении)
```

### ChatMessageDelegate

```swift
func chatDidTapMessage(id: String, attachmentIndex: Int?)               // нажатие на сообщение/медиа
func chatDidSelectAction(actionId: String, messageId: String)           // действие контекстного меню
func chatDidSelectEmojiReaction(emoji: String, messageId: String)       // эмодзи из контекстного меню
func chatDidTapReaction(messageId: String, emoji: String)               // нажатие на чип реакции
func chatDidTapReplyMessage(id: String)                                 // нажатие на цитату
func chatDidTapThread(messageId: String, threadId: String)              // нажатие на индикатор треда
func chatDidTapLink(url: URL, messageId: String)                        // нажатие на распознанную ссылку
func chatDidTapPhoneNumber(phoneNumber: String, messageId: String)      // нажатие на распознанный телефон
func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction)  // все взаимодействия с контентом
```

### ChatInputDelegate

```swift
func chatDidSendMessage(text: String, replyToId: String?)               // кнопка отправки
func chatDidEditMessage(text: String, messageId: String)                // подтверждение редактирования
func chatDidCancelInputAction(type: String)                             // отмена «reply» или «edit»
func chatDidTapAttachment()                                             // кнопка вложения
func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float])
func chatDidChangeInputText(_ text: String)                             // текст изменён (индикатор набора)
```

Все методы делегата имеют пустые реализации по умолчанию — реализуйте только то, что вам нужно.

---

## Панель ввода

Панель ввода встроена в `ChatViewController`, но может использоваться и отдельно:

```swift
let inputBar = InputBarView()
inputBar.delegate = self
inputBar.applyTheme(.dark)
inputBar.applyLayout(ChatLayout())

// Показать/скрыть кнопки
inputBar.showAttachButton = true
inputBar.voiceRecordingEnabled = true

// Режимы ответа/редактирования
inputBar.beginReply(info: InputBarReplyInfo(
    messageId: "1", senderName: "Алиса", text: "Привет", hasImage: false
))
inputBar.beginEdit(messageId: "1", text: "Обновлённый текст")
inputBar.cancelMode()

// Клавиатура
inputBar.activateKeyboard()
inputBar.dismissKeyboard()
inputBar.isKeyboardActive  // только для чтения
```

### InputBarMode

```swift
public enum InputBarMode: Equatable {
    case normal
    case reply(messageId: String, senderName: String?, text: String?, hasImage: Bool)
    case edit(messageId: String, text: String)
}
```

### Запись голоса

Запись голоса использует жест долгого нажатия на кнопку микрофона:
- **Свайп влево** для отмены
- **Свайп вверх** для блокировки (запись без удержания)
- **Отпустить** для отправки

Запись создаёт файл `.m4a` с данными волновой формы, передаваемый через `chatDidCompleteVoiceRecording`.

---

## Контекстное меню

Отображается при долгом нажатии на пузырь сообщения. Настраивается для каждого сообщения через массив `MessageAction` и глобально через `features.emojiReactions`.

```swift
// Действия для каждого сообщения
let msg = ChatMessage(
    // ...
    actions: [
        MessageAction(id: "reply", title: "Ответить", systemImage: "arrowshape.turn.up.left", isDestructive: false),
        MessageAction(id: "delete", title: "Удалить", systemImage: "trash", isDestructive: true),
    ]
)

// Глобальная палитра эмодзи
chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥"]

// Полностью отключить контекстное меню
chatVC.features.contextMenuEnabled = false
```

### ContextMenuTheme

```swift
var menuTheme = ContextMenuTheme.dark
menuTheme.emojiPanelBackground = .systemGray6
menuTheme.menuCornerRadius = 16
menuTheme.openDuration = 0.3
```

---

## Управление непрочитанными

Два режима:

### Автоматический (по умолчанию)
Библиотека отслеживает видимые сообщения и автоматически уменьшает счётчик непрочитанных:

```swift
chatVC.unreadCount = 5  // показывает бейдж на FAB
// По мере прокрутки пользователем видимые непрочитанные сообщения отмечаются, счётчик уменьшается
```

### Внешний
Для приложений, которые управляют состоянием прочтения на сервере:

```swift
chatVC.setUnreadCount(10)  // переключает во внешний режим
// Библиотека больше не уменьшает автоматически — вы контролируете счётчик
chatVC.clearUnread()       // сбросить до нуля
```

---

## Мост React Native

Парсинг сообщений из JavaScript-словарей:

```swift
let msg = ChatMessage.from(dict: jsDict)
```

Поддерживает все типы контента, реакции, ответы, действия и статусы.

---

## Архитектура

Ядро библиотеки (`ChatView/`) не зависит от типов контента — оно ничего не знает о типах сообщений. Весь рендеринг контента находится в `DefaultContent/`, который пользователи могут полностью заменить.

```
Sources/IOSChatView/
├── ChatView/              # ЯДРО — не зависит от типов контента
│   ├── Controller/        # ChatViewController + 5 расширений
│   ├── DataSource/        # UICollectionViewDataSource + ChatRow (Differentiable)
│   ├── Components/        # MessageUpdateHandler, FAB, FloatingDate, EmptyState,
│   │                      # KeyboardFreezeManager, UnreadManager
│   ├── Factory/           # Протокол ChatContentFactory (без реализации)
│   ├── Models/            # ChatContent, AnyChatContent, MessageBody, ChatMessage, Theme, Layout
│   ├── Views/             # MessageCell, MessageBubbleView, ChatCollectionViewLayout
│   │   └── Content/       # Text, Reactions, Reply, Status (универсальные элементы)
│   ├── Audio/             # VoicePlayer (синглтон)
│   └── Helpers/           # MessageSizeCalculator, SizeCache, ChatTextMeasurer, DateHelper
├── DefaultContent/        # Встроенные типы контента (опционально)
│   ├── DefaultChatContentFactory.swift
│   ├── Models/            # ImagesContent, VoicePayload, PollPayload, FilesContent, ChatParsing
│   └── Views/             # MediaGrid, Voice, Poll, File, ImageCache
├── InputBar/
│   ├── InputBarView       # Основной view + расширение записи
│   ├── Audio/             # VoiceRecorder
│   └── Views/             # ReplyPanel, RecordingRow, LockView
└── ContextMenu/
    ├── Controller/        # ContextMenuViewController
    ├── Models/            # Action, Emoji, Configuration
    ├── Theme/             # ContextMenuTheme (светлая/тёмная)
    ├── Layout/            # Позиционирование + пружинные анимации
    └── Views/             # EmojiPanel, ActionsView
```

### Производительность

- **Кастомный layout:** Предвычисленные высоты, бинарный поиск для видимой области, никаких вызовов делегата во время прокрутки
- **Кэш размеров:** Кэш с учётом ширины (ключ: id + width), автоматическая инвалидация при повороте
- **DifferenceKit:** Diff по алгоритму Heckel за O(n), анимированные пакетные обновления только для затронутых ячеек
- **Подгрузка сверху:** O(delta) — вычисляются только новые строки, смещение прокрутки компенсируется
- **Добавление снизу:** За константное время — строки добавляются в конец, авто-прокрутка если рядом с низом

---

## Лицензия

Лицензия MIT. Подробности см. в [LICENSE](LICENSE).
