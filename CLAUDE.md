# IOSChatView

Продакшн-библиотека нативного чат-UI для iOS.

## Стек технологий

- **Язык:** Swift 5.9
- **UI:** UIKit (программный, без storyboard)
- **Diff-движок:** DifferenceKit 1.3 (CocoaPods / SPM)
- **Layout:** Кастомный `ChatCollectionViewLayout` (предвычисленные высоты, бинарный поиск)
- **Аудио:** AVFoundation, AudioToolbox
- **Мин. iOS:** 15.0 (podspec 15.1)

## Архитектура

**Контент-агностичный дизайн.** Ядро библиотеки ничего не знает о типах сообщений (изображения, голос, опрос и т.д.). Всё рендеринг и обработка взаимодействий делегируются `ChatContentFactory`. Встроенные типы поставляются в `DefaultContent/` как опциональные.

Делегатная композиция. `ChatViewController` — главный оркестратор, разбит на 5 расширений:

- `+Data` — построение строк, вычисление layout data, кеш размеров, индекс сообщений
- `+Scroll` — UICollectionViewDelegate с throttle-событиями, пагинация, трекинг видимости
- `+Input` — реализация InputBarDelegate, проброс в ChatViewControllerDelegate
- `+ContextMenu` — показ контекстного меню по долгому нажатию (через KeyboardFreezeManager)
- `+MessageActions` — маршрутизация колбэков ячейки в делегат

Вынесенные менеджеры:
- `MessageUpdateHandler` — маршрутизация обновлений (initial/prepend/append/content/replace/structural), bottom-edge-stable offset, инкрементальный патч
- `FloatingDateManager` — плавающая дата при прокрутке
- `FABManager` — кнопка скролла вниз + бейдж непрочитанных (view из фабрики)
- `EmptyStateManager` — пустое состояние (view из фабрики)
- `KeyboardFreezeManager` — заморозка/восстановление клавиатуры при контекстном меню
- `UnreadManager` — отслеживание и подсчёт непрочитанных
- `SizeCache` — кеш размеров ячеек с привязкой к ширине

### Поток данных

```
[ChatMessage] → buildRows() → [ChatRow] (плоский массив с разделителями дат + загрузка)
                                    ↓
                          computeLayoutData() → [RowLayoutInfo] (предвычисленные высоты)
                                    ↓
                     ChatCollectionViewLayout (кастомный UICollectionViewLayout)
                                    ↓
                  ChatDataSource (стандартный UICollectionViewDataSource)
```

### Стратегии обновлений (MessageUpdateHandler)

Быстрые пути (без DifferenceKit):

| Стратегия | Когда | Метод |
|-----------|-------|-------|
| Initial | Пустой → данные | `reloadData` + скролл вниз |
| Clear | Данные → пустой | `reloadData` |
| Prepend | Старые сообщения сверху | `reloadData` + компенсация offset |
| Append | Новые сообщения снизу | `reloadData` + сохранение позиции / auto-scroll |

DK changeset — единственный diff-движок для всего остального:

| Стратегия | Когда | Метод |
|-----------|-------|-------|
| ContentOnly | DK structural=0 (только updates) | Инкрементальный патч + bottom-stable offset + CATransaction |
| Structural | DK structural>0 (insert/delete/move) | Предвычисление targetOffset + `performBatchUpdates` |
| FullReplace | Большинство ID изменились | `UIView.transition(.transitionCrossDissolve)` |

**Архитектура structural пути:**
1. Предвычисление `newLayoutData` + `targetOffset` (где якорь останется на прежней позиции)
2. DK `cv.reload(using:)` для анимации ячеек
3. Если offset изменился значительно (>3pt) — `performWithoutAnimation` + offset коррекция
4. Если offset не изменился — DK анимация (видимые insert/delete/move)

**Bottom-edge-stable offset** (contentOnly): пинит нижний видимый элемент к экранной позиции.
Изменение высоты расширяется вверх. Prefix sums для O(1) lookup. CATransaction для атомарности.

**ContentOnly при wasAtBottom**: `scrollToBottom(animated: false)` внутри CATransaction — без промежуточного кадра, FAB не мерцает.

**Disintegration**: конфетти-эффект при удалении. Работает для всех типов пузырей включая полупрозрачные (system). Un-premultiply alpha для корректных цветов частиц.

**pendingScrollToBottom**: ставится при `scrollToBottom()`, `send`, `edit`. Сбрасывается при `scrollViewWillBeginDragging` (пользователь скроллит). Потребляется в `updateMessages`.

**MessageDiff** (вспомогательный, не для классификации):
- `isPrependOnly` / `isAppendOnly` — O(n) проверка порядка ID
- `buildPendingMapping` — pending→real через localId

### Иерархия делегатов

```
ChatViewControllerDelegate (typealias, объединяет 4 протокола):
  ├── ChatScrollDelegate       — скролл, пагинация, FAB
  ├── ChatVisibilityDelegate   — видимые сообщения (throttle) + непрочитанные (debounce)
  ├── ChatMessageDelegate      — тап, долгое нажатие, реакции, ответы, треды, ссылки, chatDidContentInteraction
  └── ChatInputDelegate        — отправка, редактирование, вложения, голосовая запись

InputBarDelegate               — события input bar → ChatViewController → ChatViewControllerDelegate
ContextMenuDelegate            — события контекстного меню (эмодзи, действия, закрытие)
```

### Конфигурация

```
Свойства ChatViewController:
  .theme: ChatTheme        — 66 цветовых свойств, пресеты light/dark
                             цвета system/pinned пузырей, thread/voice/poll/media
  .layout: ChatLayout      — 169 параметров размеров/отступов/шрифтов
                             пузырь, ячейка, аватары, шрифты, footer, ответ, реакции,
                             тред, медиа, видео, голос, опрос, файл, эмодзи, разделитель дат,
                             коллекция, input bar, FAB, тени, запись, анимации,
                             жесты, пустое состояние, скролл
  .features: ChatFeatures  — флаги поведения (показ/скрытие UI-элементов)
  .contentFactory: ChatContentFactory — кастомное создание view (протокол)

  // Трекинг видимости (прямые свойства, не в layout)
  .visibleMessagesThrottleInterval: TimeInterval  — throttle для снимка видимых (по умолчанию 0.3с)
  .unreadMessagesDebounceInterval: TimeInterval   — debounce для пачки непрочитанных (по умолчанию 0.3с)
  .visibilityThreshold: CGFloat                   — порог входа в "видимые" при 80% высоты ячейки
  .visibilityExitThreshold: CGFloat               — порог выхода из "видимых" ниже 50% (гистерезис)
  .unreadVisibilityThreshold: CGFloat             — отметка как прочитанное при 50% видимости

batchUpdate { } — атомарное применение нескольких конфиг-изменений (один reload)
```

Контекстное меню: `ContextMenuTheme.snapOpenShift: CGFloat = 6` — лёгкий горизонтальный сдвиг при открытии.
`snapX` использует `sourceFrame.minX` напрямую (без clamp).

## Структура проекта

```
Sources/IOSChatView/
├── ChatView/                                  # ЯДРО — контент-агностичное
│   ├── Controller/
│   │   ├── ChatViewController.swift           # Главный контроллер, публичный API
│   │   ├── ChatViewController+Data.swift      # Построение строк, layout, кеш размеров
│   │   ├── ChatViewController+Scroll.swift    # Делегат скролла, пагинация, видимость
│   │   ├── ChatViewController+Input.swift     # Проброс делегата input bar
│   │   ├── ChatViewController+ContextMenu.swift # Показ контекстного меню
│   │   ├── ChatViewController+MessageActions.swift # Взаимодействие ячейки → делегат
│   │   └── ChatViewControllerDelegate.swift   # 4 протокола делегата
│   ├── DataSource/
│   │   ├── ChatDataSource.swift               # UICollectionViewDataSource
│   │   └── ChatRow.swift                      # Differentiable row enum
│   ├── Components/
│   │   ├── MessageUpdateHandler.swift         # Роутер обновлений (DK changeset + contentOnly + structural)
│   │   ├── MessageDiff.swift                  # isPrependOnly/isAppendOnly + pending mapping
│   │   ├── DisintegrationAnimator.swift       # Конфетти-эффект удаления (CAEmitterLayer)
│   │   ├── FloatingDateManager.swift          # Плавающая дата
│   │   ├── FABManager.swift                   # Кнопка скролла вниз + бейдж (view из фабрики)
│   │   ├── EmptyStateManager.swift            # Пустое состояние (view из фабрики)
│   │   ├── KeyboardFreezeManager.swift        # Заморозка/восстановление клавиатуры для контекстного меню
│   │   └── UnreadManager.swift                # Отслеживание непрочитанных
│   ├── Views/
│   │   ├── ChatCollectionViewLayout.swift     # Кастомный layout (предвычисление, бинарный поиск, supplementary аватаров)
│   │   ├── MessageCell.swift                  # Ячейка сообщения с обработкой жестов
│   │   ├── MessageBubbleView.swift            # Сборка пузыря (текст, контент, footer и т.д.)
│   │   ├── AvatarSupplementaryView.swift      # Sticky supplementary view аватара
│   │   ├── DateSeparatorCell.swift            # Ячейка разделителя дат
│   │   ├── LoadingCell.swift                  # Ячейка индикатора загрузки (view из фабрики)
│   │   ├── PaddedLabel.swift                  # Утилитарный label
│   │   └── Content/
│   │       ├── TextContentView.swift          # Текст с NSDataDetector для ссылок/телефонов
│   │       ├── ReactionsView.swift            # Чипы эмодзи-реакций
│   │       ├── ReplyPreviewView.swift         # Превью цитируемого сообщения
│   │       └── MessageStatusView.swift        # Индикаторы sent/delivered/read
│   ├── Factory/
│   │   └── ChatContentFactory.swift           # Протокол — все view делегируются сюда
│   ├── Models/
│   │   ├── ChatModels.swift                   # ChatContent, AnyChatContent, MessageBody, MessageOwnership, ThreadInfo, ChatMessage и т.д.
│   │   ├── ChatTheme.swift                    # 66 цветов, пресеты light/dark, contextMenuTheme
│   │   ├── ChatLayout.swift                   # 169 параметров layout
│   │   └── ChatFeatures.swift                 # Флаги фич
│   ├── Audio/
│   │   └── VoicePlayer.swift                  # Синглтон аудиоплеера
│   └── Helpers/
│       ├── MessageSizeCalculator.swift        # Вычисление высоты ячейки
│       ├── SizeCache.swift                    # Кеш размеров с привязкой к ширине
│       ├── ChatTextMeasurer.swift             # Утилиты измерения текста
│       └── DateHelper.swift                   # Форматирование дат
│
├── DefaultContent/                            # Встроенные типы контента (опциональные)
│   ├── DefaultChatContentFactory.swift        # Фабрика по умолчанию: изображения, голос, опрос, файлы
│   ├── Models/
│   │   ├── DefaultContentTypes.swift          # ImagesContent, VoicePayload, PollPayload, FilesContent
│   │   └── ChatParsing.swift                  # NSDictionary → ChatMessage (RN bridge)
│   └── Views/
│       ├── MediaGridView.swift                # Сетка изображений/видео (1-4 элемента)
│       ├── VoiceContentView.swift             # Волновая форма + play/pause
│       ├── PollContentView.swift              # Опрос с анимированными полосками
│       ├── FileContentView.swift              # Строки файловых вложений
│       └── ImageCache.swift                   # Кеш URL → UIImage
├── InputBar/
│   ├── InputBarView.swift                     # Главный input bar + UITextViewDelegate
│   ├── InputBarView+Recording.swift           # Стейт-машина жеста записи голоса
│   ├── InputBarModels.swift                   # InputBarDelegate, InputBarMode
│   ├── InputBarTheme.swift                    # Цвета input bar
│   ├── Audio/
│   │   └── VoiceRecorder.swift                # Обёртка над AVAudioRecorder
│   └── Views/
│       ├── InputBarReplyPanel.swift           # Сворачиваемая панель ответа/редактирования
│       ├── InputBarRecordingRow.swift         # UI записи (таймер, отмена, стоп)
│       └── InputBarLockView.swift             # Иконка замка для записи без удержания
├── ContextMenu/
│   ├── Controller/
│   │   └── ContextMenuViewController.swift    # Показ + закрытие меню
│   ├── Models/
│   │   └── ContextMenuModels.swift            # Структуры Action, Emoji, Configuration
│   ├── Theme/
│   │   └── ContextMenuTheme.swift             # Цвета меню, пресеты light/dark
│   ├── Layout/
│   │   ├── ContextMenuLayout.swift            # Позиционирование меню
│   │   └── ContextMenuAnimator.swift          # Spring-анимации
│   └── Views/
│       ├── ContextMenuEmojiPanel.swift        # Панель быстрых эмодзи-реакций
│       └── ContextMenuActionsView.swift       # Список действий меню
```

## Справочник публичного API

### ChatViewController

```swift
public final class ChatViewController: UIViewController {
    // Конфигурация (наблюдаемые — при изменении обновляют UI)
    public var theme: ChatTheme
    public var layout: ChatLayout
    public var features: ChatFeatures
    public var contentFactory: ChatContentFactory
    public func batchUpdate(_ block: () -> Void)  // атомарные конфиг-изменения

    // Делегат
    public weak var delegate: ChatViewControllerDelegate?

    // Состояние пагинации
    public var hasMore: Bool           // есть старые сообщения
    public var hasNewer: Bool          // есть новые сообщения
    public var isLoading: Bool         // общая загрузка (спиннер в пустом состоянии)
    public var emptyStateText: String? // кастомный текст пустого состояния
    public var isLoadingTop: Bool      // оверлей спиннера сверху
    public var isLoadingBottom: Bool   // индикатор загрузки снизу

    // Управление непрочитанными
    public var unreadCount: Int
    public func setUnreadCount(_ count: Int)  // включает внешнее управление непрочитанными
    public func clearUnread()

    // Доступ к collection view
    public private(set) var collectionView: UICollectionView!
    public var inputBar: InputBarView!
    public var collectionExtraInsetTop: CGFloat
    public var collectionExtraInsetBottom: CGFloat

    // Сообщения
    public internal(set) var messages: [ChatMessage]
    public func updateMessages(_ newMessages: [ChatMessage])
    public func message(forID id: String) -> ChatMessage?

    // Скролл
    public func scrollToBottom(animated: Bool)
    public func scrollToMessage(id: String, position: String, animated: Bool, highlight: Bool)
    public var pendingScrollAnchor: ScrollAnchor?  // пиксель-точное восстановление при инициализации
    public var isInitialScrollProtected: Bool
    public func currentScrollAnchor() -> ScrollAnchor?
    public func currentVisibleAnchors() -> [ScrollAnchor]
    public func restoreBestAnchor(_ anchors: [ScrollAnchor], fallbackOffset: CGFloat?)
    public func restoreScrollAnchor(_ anchor: ScrollAnchor)
    public func distanceFromBottom() -> CGFloat
    public func isNearBottom() -> Bool

    // Эффект рассыпания
    public var disintegrationEnabled: Bool       // по умолчанию false
    public var disintegrationConfig: DisintegrationAnimator.Config

    // Режимы ввода
    public func beginReply(info: ReplyInfo)
    public func beginEdit(messageId: String, text: String)
    public func clearInputMode()
}
```

### Протоколы делегата

```swift
// Составной протокол
public typealias ChatViewControllerDelegate =
    ChatScrollDelegate & ChatVisibilityDelegate & ChatMessageDelegate & ChatInputDelegate

public protocol ChatScrollDelegate: AnyObject {
    func chatDidScroll(offset: CGPoint)
    func chatDidReachTop(distance: CGFloat)       // загрузка старых сообщений
    func chatDidReachBottom(distance: CGFloat)     // загрузка новых сообщений
    func chatDidTapFAB()
    func chatScrollAnchorChanged(anchor: ScrollAnchor)  // throttle ~300мс
}

public protocol ChatVisibilityDelegate: AnyObject {
    func chatVisibleMessagesDidChange(ids: [String])  // throttle-снимок видимых сообщений
    func chatUnreadMessagesDidAppear(ids: [String])   // debounce-пачка непрочитанных
}

public protocol ChatMessageDelegate: AnyObject {
    func chatDidTapMessage(id: String, attachmentIndex: Int?)
    func chatDidSelectAction(actionId: String, messageId: String)
    func chatDidSelectEmojiReaction(emoji: String, messageId: String)
    func chatDidTapReaction(messageId: String, emoji: String)
    func chatDidTapReplyMessage(id: String)
    func chatDidTapThread(messageId: String, threadId: String)
    func chatDidTapLink(url: URL, messageId: String)
    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String)
    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction)  // универсальное взаимодействие с контентом (опрос, голос и т.д.)
}

public protocol ChatInputDelegate: AnyObject {
    func chatDidSendMessage(text: String, replyToId: String?)
    func chatDidEditMessage(text: String, messageId: String)
    func chatDidCancelInputAction(type: String)    // "reply" или "edit"
    func chatDidTapAttachment()
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float])
    func chatDidChangeInputText(_ text: String)
}
```

### Модели данных

```swift
// Система типов контента — библиотека агностична к конкретным типам
public protocol ChatContent: Equatable, Hashable, Sendable {
    static var contentTypeID: String { get }
}

public struct AnyChatContent: Equatable, Hashable, Sendable {
    public init<T: ChatContent>(_ content: T)
    public func content<T: ChatContent>(as type: T.Type) -> T?
}

public struct MessageBody: Equatable, Hashable {
    public let text: String?
    public let content: AnyChatContent?    // любой ChatContent тип
}

// Принадлежность сообщения
public enum MessageOwnership: String, Sendable {
    case mine       // → MessageAlignment.trailing
    case theirs     // → MessageAlignment.leading
    case system     // → MessageAlignment.center (центрированный пузырь, нейтральные цвета)
    case pinned     // → MessageAlignment.center (центрированный пузырь, контент по левому краю)
}

public enum MessageAlignment {
    case leading, trailing, center
}

// Информация о треде — опциональные метаданные на ChatMessage
public struct ThreadInfo: Equatable, Hashable {
    public let threadId: String
    public let replyCount: Int
    public let lastReplierName: String?
}

// Якорь скролла для пиксельно-точного восстановления
public struct ScrollAnchor: Codable, Equatable {
    public let messageId: String
    public let offset: CGFloat             // расстояние от нижнего края viewport до нижнего края ячейки
    public let wasAtBottom: Bool
}

public struct ChatMessage: Equatable, Hashable {
    public let id: String
    public let localId: String?            // для маппинга pending→real
    public let content: MessageBody        // текст + опциональный контент
    public let timestamp: Date
    public let senderName: String?
    public let senderAvatarUrl: String?    // URL аватара для sticky-аватаров
    public let ownership: MessageOwnership // .mine, .theirs, .system, .pinned
    public let groupDate: String           // "yyyy-MM-dd" для разделителей дат
    public let status: MessageStatus       // .sending, .sent, .delivered, .read
    public let reply: ReplyInfo?
    public let forwardedFrom: String?
    public let reactions: [Reaction]       // Reaction.isSelected вместо прежнего isMine
    public let isEdited: Bool
    public let actions: [MessageAction]    // действия контекстного меню
    public let thread: ThreadInfo?         // индикатор треда (по умолчанию nil)
}

// Универсальное взаимодействие — библиотека маршрутизирует без инспекции
public struct ChatContentInteraction: Sendable {
    public let type: String
    public let payload: [String: AnyHashable]
}
```

### ChatContentFactory

```swift
public protocol ChatContentFactory: AnyObject {
    // Контент (кастомные типы рендерятся здесь)
    func contentView(for media: AnyChatContent, ...) -> UIView
    func contentHeight(for media: AnyChatContent, ...) -> CGFloat
    func reconfigureContentView(_ view: UIView, for media: AnyChatContent, ...) -> Bool

    // Универсальные элементы
    func textView(text: String, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout, linkDetectionEnabled: Bool, onLinkTap: ((URL) -> Void)?) -> UIView
    func textHeight(text: String, ...) -> CGFloat
    func emojiView(text: String, emojiCount: Int, ...) -> UIView
    func reactionsView(reactions: [Reaction], ...) -> UIView
    func replyPreviewView(reply: ReplyInfo, ...) -> UIView
    func footerView(message: ChatMessage, ...) -> UIView?
    func senderNameView(name: String, ...) -> UIView
    func forwardedHeaderView(from: String, ...) -> UIView
    func dateSeparatorView(title: String, ...) -> UIView
    func dateSeparatorHeight(layout: ChatLayout) -> CGFloat
    func floatingDateView(title: String, ...) -> UIView

    // Индикатор треда
    func threadIndicatorView(thread: ThreadInfo, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout, onTap: (() -> Void)?) -> UIView

    // Аватары
    func avatarView(name: String, url: String?, size: CGFloat, theme: ChatTheme, layout: ChatLayout) -> UIView

    // UI-компоненты
    func emptyStateView(...) -> UIView
    func emptyStateLoadingView(...) -> UIView
    func loadingIndicatorView(...) -> UIView
    func fabView(...) -> UIView
    func fabBadgeView(...) -> UIView
}
// DefaultChatContentFactory — обрабатывает встроенные типы, наследуйтесь для кастомизации
```

### Флаги фич (ChatFeatures)

```swift
public struct ChatFeatures {
    // Сообщения
    public var senderNameMode: SenderNameMode  // .never, .incomingOnly, .always
    public var showMessageStatus: Bool         // иконки sent/delivered/read
    public var showTimestamp: Bool
    public var showEditedMark: Bool
    public var showReactions: Bool
    public var showReplyPreview: Bool
    public var showForwardedMark: Bool

    // Список
    public var showFab: Bool                   // кнопка скролла вниз
    public var showFloatingDate: Bool          // плавающая дата при прокрутке
    public var showDateSeparators: Bool
    public var showTopLoadingIndicator: Bool
    public var showBottomLoadingIndicator: Bool
    public var showEmptyState: Bool

    // Ввод
    public var showInputBar: Bool
    public var showAttachButton: Bool
    public var showVoiceRecording: Bool

    // Треды
    public var showThreadIndicator: Bool       // по умолчанию true

    // Аватары
    public var showAvatars: Bool               // по умолчанию false — sticky-аватары для .theirs сообщений

    // Обнаружение ссылок
    public var linkDetectionEnabled: Bool       // по умолчанию true — URL и номера телефонов

    // Контекстное меню
    public var contextMenuEnabled: Bool
    public var emojiReactions: [String]        // напр. ["👍", "❤️", "😂", "😮", "😢", "🔥"]

    // Пороги скролла
    public var topLoadThreshold: CGFloat       // по умолчанию 200
    public var bottomLoadThreshold: CGFloat    // по умолчанию 200
    public var scrollToBottomThreshold: CGFloat // по умолчанию 150
    public var autoScrollOnNewMessage: Bool
}
```

## Пример интеграции

```swift
class MyChatVC: UIViewController, ChatViewControllerDelegate {

    let chatVC = ChatViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Конфигурация
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥"]
        chatVC.delegate = self

        // 2. Встраивание как дочерний контроллер
        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.frame = view.bounds
        chatVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chatVC.didMove(toParent: self)

        // 3. Загрузка сообщений
        chatVC.hasMore = true
        chatVC.updateMessages(myMessages)
    }

    // MARK: - Пагинация
    func chatDidReachTop(distance: CGFloat) {
        chatVC.isLoadingTop = true
        loadOlderMessages { [weak self] older in
            self?.chatVC.isLoadingTop = false
            self?.chatVC.updateMessages(older + self!.chatVC.messages)
        }
    }

    // MARK: - Отправка
    func chatDidSendMessage(text: String, replyToId: String?) {
        let msg = createMessage(text: text, replyToId: replyToId)
        chatVC.updateMessages(chatVC.messages + [msg])
    }

    // MARK: - Действия
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
            chatVC.updateMessages(msgs)
        default: break
        }
    }

    // MARK: - Реакции
    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {
        // Переключить реакцию на сервере, затем обновить сообщения
    }

    // MARK: - Остальные обязательные методы делегата
    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachBottom(distance: CGFloat) {}
    func chatDidTapFAB() { chatVC.scrollToBottom(animated: true) }
    func chatVisibleMessagesDidChange(ids: [String]) {}
    func chatUnreadMessagesDidAppear(ids: [String]) {}
    func chatDidTapMessage(id: String, attachmentIndex: Int?) {}
    func chatDidTapReaction(messageId: String, emoji: String) {}
    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }
    func chatDidTapThread(messageId: String, threadId: String) {}
    func chatDidTapLink(url: URL, messageId: String) {
        UIApplication.shared.open(url)
    }
    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String) {}
    func chatDidEditMessage(text: String, messageId: String) {}
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() {}
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {}
    func chatDidChangeInputText(_ text: String) {}
    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {}
    func chatScrollAnchorChanged(anchor: ScrollAnchor) {}
}
```

## Тестирование

Интеграционные тесты в `Example/rn-chat-view-tests/` (Swift Testing, запуск на устройстве).
Unit-тесты в `Example/Tests/MessageDiffTests.swift`.

Полный список тестов: [TESTS.md](TESTS.md)

```bash
# Запуск всех тестов
cd Example
xcodebuild test -workspace rn-chat-view.xcworkspace \
  -scheme rn-chat-view \
  -destination 'id=00008110-000C0CA03A21801E' \
  -allowProvisioningUpdates \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  -only-testing:'rn-chat-view-tests'
```

**Правило: перед исправлением бага или добавлением фичи — написать тест, воспроизводящий проблему или проверяющий новое поведение.** Тесты на русском (`@Suite("Кейс N: ...")`, `@Test("описание")`).

## Соглашения

- Весь UI построен программно с AutoLayout constraints
- View используют замыкания для передачи событий; контроллеры используют протоколы делегатов
- `layout`/`theme`/`features` передаются через параметры, не глобальные синглтоны
- Новые типы контента добавляются в `ChatView/Views/Content/`
- При добавлении функциональности ChatViewController — следовать паттерну расширений
- Кастомные view контента — наследуйтесь от `DefaultChatContentFactory` и переопределяйте нужные методы
- Horizontal constraints во view с frame-based позиционированием (ContextMenu, InputBar) — `.defaultHigh` (RN bridge начинает с width=0)
- Debug-логи через `log()` wrapper с `#if DEBUG`

## Сборка

```bash
# Demo app (Example/) — всегда Debug конфигурация
cd Example
pod install
xcodebuild -workspace rn-chat-view.xcworkspace \
  -scheme rn-chat-view \
  -destination 'id=00008110-000C0CA03A21801E' \
  -allowProvisioningUpdates \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  -configuration Debug \
  build

# Установка на устройство
xcrun devicectl device install app --device 00008110-000C0CA03A21801E \
  ~/Library/Developer/Xcode/DerivedData/rn-chat-view-*/Build/Products/Debug-iphoneos/rn-chat-view.app

# Запуск (bundle ID: com.rn-chat-view.rn-chat-view)
xcrun devicectl device process launch --device 00008110-000C0CA03A21801E \
  com.rn-chat-view.rn-chat-view
```

## Установка

### CocoaPods
```ruby
pod 'IOSChatView', :path => '../path-to-lib'
pod 'DifferenceKit', :modular_headers => true
```

### Swift Package Manager
```swift
.package(url: "https://github.com/epifanovmd/rn-chat-view.git", from: "1.0.0")
```

## Известные проблемы

- `ENABLE_USER_SCRIPT_SANDBOXING` должен быть `NO` — скрипты rsync CocoaPods несовместимы с песочницей Xcode

## Память проекта

Основная память проекта хранится в [.claude/memory/](.claude/memory/). Индекс: [.claude/memory/MEMORY.md](.claude/memory/MEMORY.md).
