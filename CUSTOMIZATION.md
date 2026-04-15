# Кастомные типы контента и руководство по Factory

IOSChatView — это контент-агностичный UI для чата. Библиотека ничего не знает о типах сообщений — вся отрисовка, расчёт размеров и обработка взаимодействий делегируется `ChatContentFactory`. Это руководство показывает, как определить кастомные типы контента, создать кастомную factory и обрабатывать взаимодействия.

## Содержание

- [Обзор архитектуры](#обзор-архитектуры)
- [Определение кастомных типов контента](#определение-кастомных-типов-контента)
- [Создание сообщений с кастомным контентом](#создание-сообщений-с-кастомным-контентом)
- [Создание кастомной Factory](#создание-кастомной-factory)
- [Обработка взаимодействий с контентом](#обработка-взаимодействий-с-контентом)
- [Справочник по Delegate](#справочник-по-delegate)
- [Встроенные типы контента](#встроенные-типы-контента)
- [Полный пример](#полный-пример)

---

## Обзор архитектуры

```
┌───────────────────────────────────────────────────────────────────┐
│  Ваше приложение                                                  │
│  ┌─────────────────┐  ┌───────────────┐  ┌───────────────────┐    │
│  │ Типы            │  │ Factory       │  │ Delegate          │    │
│  │ контента        │  │               │  │                   │    │
│  │ PaymentContent  │  │ MyFactory     │  │ MyVC              │    │
│  │ LocationContent │  │ contentView() │  │ chatDid...()      │    │
│  └──────┬──────────┘  └─────┬─────────┘  └──────┬────────────┘    │
│         │                   │                   │                 │
├─────────┼───────────────────┼───────────────────┼─────────────────┤
│  Библиотека IOSChatView     │                   │                 │
│         │                   │                   │                 │
│  ┌──────▼──────────┐  ┌─────▼─────────┐  ┌──────▼──────────────┐  │
│  │AnyChatContent   │  │ ChatContent   │  │ ChatViewController  │  │
│  │(непрозрачная    │  │ Factory       │  │ Delegate            │  │
│  │ обёртка)        │  │ (protocol)    │  │ (protocol)          │  │
│  └─────────────────┘  └───────────────┘  └─────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

**Ключевой принцип:** Ядро библиотеки работает только с `AnyChatContent` (непрозрачная обёртка) и `ChatContentInteraction` (универсальная структура события). Оно никогда не заглядывает внутрь — всю работу выполняет ваша factory.

---

## Определение кастомных типов контента

Любая структура, реализующая `ChatContent`, может использоваться как контент сообщения:

```swift
import IOSChatView

// 1. Определяем свой тип контента
struct PaymentContent: ChatContent {
    // Обязательно: уникальный идентификатор типа
    static let contentTypeID = "payment"
    
    // Ваши кастомные поля — полностью типобезопасные
    let amount: Decimal
    let currency: String
    let recipientName: String
    let status: PaymentStatus
    
    enum PaymentStatus: String, Hashable, Sendable {
        case pending, completed, failed
    }
}

struct LocationContent: ChatContent {
    static let contentTypeID = "location"
    
    let latitude: Double
    let longitude: Double
    let address: String
    let mapSnapshotURL: String?
}

struct ContactContent: ChatContent {
    static let contentTypeID = "contact"
    
    let name: String
    let phone: String
    let avatarURL: String?
}
```

**Требования к `ChatContent`:**
- Должен соответствовать `Equatable`, `Hashable`, `Sendable` (наследуется от protocol)
- Должен иметь `static var contentTypeID: String` — уникальная строка для каждого типа
- Все свойства должны быть `Hashable` и `Sendable`

---

## Создание сообщений с кастомным контентом

Оберните ваш контент в `AnyChatContent` и передайте в `MessageBody`:

```swift
// Сообщение с кастомным контентом
let paymentMessage = ChatMessage(
    id: "msg-1",
    content: MessageBody(
        text: "Payment sent",  // опциональная текстовая подпись
        content: AnyChatContent(PaymentContent(
            amount: 42.50,
            currency: "USD",
            recipientName: "Alice",
            status: .completed
        ))
    ),
    timestamp: Date(),
    senderName: "Bob",
    ownership: .mine,
    groupDate: "2026-04-06",
    status: .delivered,
    reply: nil,
    forwardedFrom: nil,
    reactions: [],
    isEdited: false,
    actions: []
)

// Текстовое сообщение (без контента)
let textMessage = ChatMessage(
    id: "msg-2",
    content: MessageBody(text: "Hello!"),
    // ... остальные поля
)

// Сообщение только с контентом (без текста)
let locationMessage = ChatMessage(
    id: "msg-3",
    content: MessageBody(
        text: nil,
        content: AnyChatContent(LocationContent(
            latitude: 55.7539,
            longitude: 37.6208,
            address: "Red Square, Moscow",
            mapSnapshotURL: nil
        ))
    ),
    // ... остальные поля
)
```

---

## Создание кастомной Factory

### Вариант A: Наследование от DefaultChatContentFactory

Лучший вариант, когда нужно **добавить** кастомные типы, сохранив встроенные (изображения, голос, опросы, файлы):

```swift
class MyFactory: DefaultChatContentFactory {
    
    override func contentView(
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        // Обработка кастомных типов
        if let payment = media.content(as: PaymentContent.self) {
            return makePaymentView(payment, onInteraction: onInteraction)
        }
        if let location = media.content(as: LocationContent.self) {
            return makeLocationView(location, onInteraction: onInteraction)
        }
        // Делегируем встроенным типам
        return super.contentView(for: media, message: message, width: width,
                                  theme: theme, layout: layout, onInteraction: onInteraction)
    }
    
    override func contentHeight(
        for media: AnyChatContent,
        width: CGFloat,
        layout: ChatLayout
    ) -> CGFloat {
        if media.content(as: PaymentContent.self) != nil { return 80 }
        if media.content(as: LocationContent.self) != nil { return 160 }
        return super.contentHeight(for: media, width: width, layout: layout)
    }
    
    // Создание кастомных view
    private func makePaymentView(
        _ payment: PaymentContent,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        let view = PaymentCardView()
        view.configure(payment: payment)
        view.onTap = {
            onInteraction(ChatContentInteraction(
                type: "paymentTap",
                payload: ["amount": payment.amount as AnyHashable]
            ))
        }
        return view
    }
}
```

### Вариант B: Реализация ChatContentFactory с нуля

Для полностью кастомного чата без встроенных типов:

```swift
class MinimalFactory: NSObject, ChatContentFactory {
    
    func contentView(for media: AnyChatContent, message: ChatMessage,
                     width: CGFloat, theme: ChatTheme, layout: ChatLayout,
                     onInteraction: @escaping (ChatContentInteraction) -> Void) -> UIView {
        // Обработка ВСЕХ ваших типов — без fallback
        if let payment = media.content(as: PaymentContent.self) {
            return makePaymentView(payment)
        }
        // Fallback для неизвестных типов
        let label = UILabel()
        label.text = "[\(media.contentTypeID)]"
        return label
    }
    
    func contentHeight(for media: AnyChatContent, width: CGFloat,
                       layout: ChatLayout) -> CGFloat {
        if media.content(as: PaymentContent.self) != nil { return 80 }
        return 44
    }
    
    func reconfigureContentView(_ view: UIView, for media: AnyChatContent,
                                 message: ChatMessage, width: CGFloat,
                                 theme: ChatTheme, layout: ChatLayout,
                                 onInteraction: @escaping (ChatContentInteraction) -> Void) -> Bool {
        // Верните true, если удалось обновить view на месте
        // Верните false для полной пересборки view
        if let payment = media.content(as: PaymentContent.self),
           let paymentView = view as? PaymentCardView {
            paymentView.configure(payment: payment)
            return true
        }
        return false
    }
    
    // ... реализуйте остальные методы protocol (text, emoji, reactions и т.д.)
}
```

### Вариант C: Переопределение только отдельных UI-элементов

```swift
class ThemedFactory: DefaultChatContentFactory {
    
    // Кастомное имя отправителя с аватаром
    override func senderNameView(name: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        // ... добавляем кружок аватара + label
        return stack
    }
    
    // Кастомный footer с иконкой шифрования
    override func footerView(message: ChatMessage, theme: ChatTheme,
                              layout: ChatLayout, features: ChatFeatures) -> UIView? {
        let view = EncryptedFooterView()
        view.configure(message: message, theme: theme)
        return view
    }
    
    // Кастомное пустое состояние
    override func emptyStateView(theme: ChatTheme, layout: ChatLayout) -> UIView {
        let view = AnimatedEmptyStateView()
        view.configure(theme: theme)
        return view
    }
    
    // Кастомная FAB-кнопка
    override func fabView(theme: ChatTheme, layout: ChatLayout) -> UIView {
        let button = GradientFABButton()
        button.configure(theme: theme, size: layout.inputButtonSize)
        return button
    }
}
```

### Назначение factory

```swift
let chatVC = ChatViewController()
chatVC.contentFactory = MyFactory()  // или ThemedFactory(), MinimalFactory() и т.д.
```

---

## Обработка взаимодействий с контентом

### Отправка взаимодействий из кастомных view

Внутри `contentView(for:...)` вашей factory используйте колбэк `onInteraction`:

```swift
func makePaymentView(
    _ payment: PaymentContent,
    onInteraction: @escaping (ChatContentInteraction) -> Void
) -> UIView {
    let view = PaymentCardView()
    view.configure(payment: payment)
    
    // Нажатие на всю карточку
    view.onTap = {
        onInteraction(ChatContentInteraction(
            type: "paymentTap",
            payload: [
                "amount": payment.amount as AnyHashable,
                "currency": payment.currency as AnyHashable,
                "status": payment.status.rawValue as AnyHashable,
            ]
        ))
    }
    
    // Нажатие на кнопку "Оплатить снова"
    view.onPayAgain = {
        onInteraction(ChatContentInteraction(
            type: "paymentPayAgain",
            payload: ["amount": payment.amount as AnyHashable]
        ))
    }
    
    // Нажатие на ссылку "Подробнее"
    view.onDetails = {
        onInteraction(ChatContentInteraction(
            type: "paymentDetails",
            payload: ["transactionId": payment.transactionId as AnyHashable]
        ))
    }
    
    return view
}
```

### Получение взаимодействий в delegate

Все взаимодействия с контентом приходят через единственный метод delegate:

```swift
func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
    switch interaction.type {
    case "paymentTap":
        let amount = interaction.payload["amount"] as? Decimal ?? 0
        showPaymentDetails(messageId: messageId, amount: amount)
        
    case "paymentPayAgain":
        let amount = interaction.payload["amount"] as? Decimal ?? 0
        initiatePayment(amount: amount)
        
    case "locationTap":
        let lat = interaction.payload["lat"] as? Double ?? 0
        let lon = interaction.payload["lon"] as? Double ?? 0
        openMap(latitude: lat, longitude: lon)
        
    case "contactCall":
        let phone = interaction.payload["phone"] as? String ?? ""
        callPhone(phone)
        
    default:
        break
    }
}
```

### Встроенные конструкторы взаимодействий

`DefaultChatContentFactory` использует их для встроенных типов:

```swift
// Определены как статические методы ChatContentInteraction:
ChatContentInteraction.mediaTap(index: 0)           // type: "mediaTap"
ChatContentInteraction.fileTap(index: 2)             // type: "fileTap"
ChatContentInteraction.pollOptionTap(pollId: "p1", optionId: "o1")  // type: "pollOptionTap"
ChatContentInteraction.pollDetailTap(pollId: "p1")   // type: "pollDetailTap"
ChatContentInteraction.voiceTap(url: "https://...")   // type: "voiceTap"
```

---

## Справочник по Delegate

`ChatViewControllerDelegate` — это композиция четырёх специализированных protocol. Все методы имеют пустые реализации по умолчанию — реализуйте только то, что нужно.

### ChatScrollDelegate

```swift
/// Вызывается при каждом событии скролла (с троттлингом через `layout.scrollThrottleInterval`).
func chatDidScroll(offset: CGPoint)

/// Вызывается, когда пользователь прокрутил близко к верху (в пределах `features.topLoadThreshold`).
/// Используйте для загрузки старых сообщений.
func chatDidReachTop(distance: CGFloat)

/// Вызывается, когда пользователь прокрутил близко к низу (в пределах `features.bottomLoadThreshold`).
/// Используйте для загрузки новых сообщений.
func chatDidReachBottom(distance: CGFloat)

/// Вызывается, когда пользователь нажимает FAB (кнопка прокрутки вниз).
func chatDidTapFAB()
```

**Типичная реализация:**

```swift
func chatDidReachTop(distance: CGFloat) {
    guard !chatVC.isLoadingTop else { return }
    chatVC.isLoadingTop = true
    api.loadOlderMessages { [weak self] messages in
        self?.chatVC.isLoadingTop = false
        self?.chatVC.updateMessages(messages + self!.chatVC.messages)
    }
}

func chatDidTapFAB() {
    chatVC.clearUnread()
    chatVC.scrollToBottom(animated: true)
}
```

### ChatVisibilityDelegate

```swift
/// Снимок текущих видимых ID сообщений (с троттлингом).
func chatVisibleMessagesDidChange(ids: [String])

/// Накопленные ID непрочитанных сообщений, появившихся на экране (с debounce).
/// Используйте для отправки подтверждений прочтения.
func chatUnreadMessagesDidAppear(ids: [String])
```

**Типичная реализация:**

```swift
func chatVisibleMessagesDidChange(ids: [String]) {
    // Отслеживание позиции скролла, аналитика и т.д.
}

func chatUnreadMessagesDidAppear(ids: [String]) {
    api.markAsRead(messageIds: ids)
}
```

### ChatMessageDelegate

```swift
/// Вызывается при нажатии на пузырь сообщения.
func chatDidTapMessage(id: String, attachmentIndex: Int?)

/// Вызывается, когда пользователь выбирает действие из контекстного меню.
func chatDidSelectAction(actionId: String, messageId: String)

/// Вызывается, когда пользователь выбирает эмодзи из панели реакций контекстного меню.
func chatDidSelectEmojiReaction(emoji: String, messageId: String)

/// Вызывается, когда пользователь нажимает на существующий чип реакции под сообщением.
func chatDidTapReaction(messageId: String, emoji: String)

/// Вызывается, когда пользователь нажимает на превью ответа внутри сообщения.
func chatDidTapReplyMessage(id: String)

/// Вызывается, когда view контента, созданный factory, генерирует взаимодействие.
/// ВСЕ взаимодействия, специфичные для типа контента, проходят через этот единственный метод.
func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction)

/// Вызывается, когда пользователь нажимает на индикатор треда в сообщении.
func chatDidTapThread(messageId: String, threadId: String)

/// Вызывается, когда пользователь нажимает на обнаруженную ссылку в сообщении.
func chatDidTapLink(url: URL, messageId: String)

/// Вызывается, когда пользователь нажимает на обнаруженный номер телефона в сообщении.
func chatDidTapPhoneNumber(phoneNumber: String, messageId: String)
```

**Типичная реализация:**

```swift
func chatDidSelectAction(actionId: String, messageId: String) {
    switch actionId {
    case "reply":
        guard let msg = chatVC.message(forID: messageId) else { return }
        chatVC.beginReply(info: ReplyInfo(
            replyToId: messageId,
            senderName: msg.senderName ?? "You",
            text: msg.content.text,
            hasImage: msg.content.content != nil
        ))
    case "edit":
        guard let msg = chatVC.message(forID: messageId) else { return }
        chatVC.beginEdit(messageId: messageId, text: msg.content.text ?? "")
    case "delete":
        var msgs = chatVC.messages
        msgs.removeAll { $0.id == messageId }
        chatVC.updateMessages(msgs)
    default:
        break
    }
}

func chatDidTapReplyMessage(id: String) {
    chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
}

func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
    switch interaction.type {
    case "pollOptionTap":
        let optionId = interaction.payload["optionId"] as? String ?? ""
        togglePollVote(messageId: messageId, optionId: optionId)
    case "paymentTap":
        showPaymentDetails(messageId: messageId)
    default:
        break
    }
}
```

### ChatInputDelegate

```swift
/// Вызывается, когда пользователь отправляет сообщение.
func chatDidSendMessage(text: String, replyToId: String?)

/// Вызывается, когда пользователь подтверждает редактирование.
func chatDidEditMessage(text: String, messageId: String)

/// Вызывается, когда пользователь отменяет ответ или редактирование. `type` — "reply" или "edit".
func chatDidCancelInputAction(type: String)

/// Вызывается, когда пользователь нажимает кнопку вложения.
func chatDidTapAttachment()

/// Вызывается при завершении записи голосового сообщения.
func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float])

/// Вызывается при изменении текста ввода (с троттлингом).
func chatDidChangeInputText(_ text: String)
```

**Типичная реализация:**

```swift
func chatDidSendMessage(text: String, replyToId: String?) {
    let message = createMessage(text: text, replyToId: replyToId)
    var messages = chatVC.messages
    messages.append(message)
    chatVC.updateMessages(messages)
    api.sendMessage(message)
}

func chatDidEditMessage(text: String, messageId: String) {
    var messages = chatVC.messages
    guard let idx = messages.firstIndex(where: { $0.id == messageId }) else { return }
    let old = messages[idx]
    messages[idx] = ChatMessage(
        id: old.id,
        content: MessageBody(text: text, content: old.content.content),
        // ... копируем остальные поля, устанавливаем isEdited: true
    )
    chatVC.updateMessages(messages)
}
```

---

## Встроенные типы контента

Поставляются с библиотекой в `DefaultContent/` и обрабатываются `DefaultChatContentFactory`:

| Тип | contentTypeID | Данные | View |
|-----|--------------|--------|------|
| `ImagesContent` | `builtin.images` | `[MediaItem]` — изображения и видео | Сетка (1-4 элемента) |
| `VoicePayload` | `builtin.voice` | URL, длительность, осциллограмма | Кнопка воспроизведения + осциллограмма |
| `PollPayload` | `builtin.poll` | Вопрос, варианты, голоса | Анимированные полосы опроса |
| `FilesContent` | `builtin.files` | `[FilePayload]` — файлы | Строки файлов с иконками |

```swift
// Использование встроенных типов
let imageMsg = MessageBody(
    text: "Check this out",
    content: AnyChatContent(ImagesContent([
        .image(ImageItem(url: "https://...", width: 400, height: 300, thumbnailUrl: nil)),
    ]))
)

let voiceMsg = MessageBody(
    text: nil,
    content: AnyChatContent(VoicePayload(
        url: "https://...",
        duration: 12.5,
        waveform: [0.1, 0.4, 0.8, 0.6, 0.3]
    ))
)
```

---

## Полный пример

Полный view controller с кастомными типами контента:

```swift
import IOSChatView
import UIKit

// MARK: - Кастомные типы

struct PaymentContent: ChatContent {
    static let contentTypeID = "payment"
    let amount: Decimal
    let currency: String
}

// MARK: - Кастомная Factory

class MyFactory: DefaultChatContentFactory {
    override func contentView(
        for media: AnyChatContent, message: ChatMessage, width: CGFloat,
        theme: ChatTheme, layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        if let payment = media.content(as: PaymentContent.self) {
            let label = UILabel()
            label.text = "\(payment.amount) \(payment.currency)"
            label.font = .monospacedDigitSystemFont(ofSize: 24, weight: .bold)
            label.textColor = .systemGreen
            label.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: nil, action: nil)
            // ... подключаем onInteraction
            return label
        }
        return super.contentView(for: media, message: message, width: width,
                                  theme: theme, layout: layout, onInteraction: onInteraction)
    }
    
    override func contentHeight(for media: AnyChatContent, width: CGFloat,
                                 layout: ChatLayout) -> CGFloat {
        if media.content(as: PaymentContent.self) != nil { return 50 }
        return super.contentHeight(for: media, width: width, layout: layout)
    }
}

// MARK: - View Controller

class MyChatVC: UIViewController, ChatViewControllerDelegate {
    let chatVC = ChatViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatVC.contentFactory = MyFactory()
        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "💸"]
        
        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.frame = view.bounds
        chatVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chatVC.didMove(toParent: self)
        
        chatVC.updateMessages(makeSampleMessages())
    }
    
    func makeSampleMessages() -> [ChatMessage] {
        [
            ChatMessage(
                id: "1",
                content: MessageBody(
                    text: "Payment received!",
                    content: AnyChatContent(PaymentContent(amount: 42.50, currency: "USD"))
                ),
                timestamp: Date(),
                senderName: "Alice",
                ownership: .theirs,
                groupDate: "2026-04-06",
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: []
            )
        ]
    }
    
    // MARK: - Delegate
    
    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
        print("Взаимодействие: \(interaction.type) с сообщением \(messageId)")
    }
    
    func chatDidSendMessage(text: String, replyToId: String?) {
        // Добавляем и обновляем
    }
}
```

---

## Методы ChatContentFactory

Protocol factory покрывает все кастомизируемые view:

| Категория | Методы |
|-----------|--------|
| **Контент** | `contentView(for:...)`, `contentHeight(for:...)`, `reconfigureContentView(_:for:...)` |
| **Текст** | `textView(text:ownership:theme:layout:linkDetectionEnabled:onLinkTap:)`, `textHeight(text:...)` |
| **Эмодзи** | `emojiView(text:emojiCount:...)` |
| **Реакции** | `reactionsView(reactions:...)` |
| **Ответ** | `replyPreviewView(reply:...)` |
| **Footer** | `footerView(message:...)` |
| **Отправитель** | `senderNameView(name:...)` |
| **Пересылка** | `forwardedHeaderView(from:...)` |
| **Даты** | `dateSeparatorView(title:...)`, `dateSeparatorHeight(...)`, `floatingDateView(title:...)` |
| **Пустое состояние** | `emptyStateView(...)`, `emptyStateLoadingView(...)` |
| **Загрузка** | `loadingIndicatorView(...)` |
| **Тред** | `threadIndicatorView(thread:ownership:theme:layout:onTap:)` |
| **Аватар** | `avatarView(name:url:size:theme:layout:)` |
| **FAB** | `fabView(...)`, `fabBadgeView(...)` |

Переопределите любой из этих методов в вашем подклассе factory, чтобы кастомизировать соответствующий UI-элемент.
