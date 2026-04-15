import UIKit

// MARK: - Владение сообщением

public enum MessageOwnership: String, Sendable {
    case mine
    case theirs
    case system
    /// Закреплённое сообщение (пузырь по центру, контент без центрирования)
    case pinned

    public var alignment: MessageAlignment {
        switch self {
        case .mine: return .trailing
        case .theirs: return .leading
        case .system, .pinned: return .center
        }
    }
}

// MARK: - Выравнивание сообщения

public enum MessageAlignment: Sendable {
    case leading, trailing, center
}

// MARK: - Статус сообщения

public enum MessageStatus: String {
    case sending, sent, delivered, read
}

// MARK: - ChatContent (расширяемый протокол)

/// Протокол для любого типа контента в сообщении.
/// Библиотека не знает о конкретных типах — всё отображение и обработка
/// взаимодействий делегированы `ChatContentFactory`.
///
/// Реализуйте протокол для своих типов контента:
/// ```swift
/// struct PaymentContent: ChatContent {
///     static let contentTypeID = "payment"
///     let amount: Decimal
///     let currency: String
/// }
/// ```
public protocol ChatContent: Equatable, Hashable, Sendable {
    /// Стабильный идентификатор типа контента. Должен быть уникальным.
    /// Используется для оптимизации in-place реконфигурации (одинаковый typeID = та же структура view).
    static var contentTypeID: String { get }
}

// MARK: - AnyChatContent (type-erased обёртка)

/// Type-erased обёртка для `ChatContent`. Сохраняет `Equatable`/`Hashable`
/// для DifferenceKit, скрывая конкретный тип от ядра библиотеки.
public struct AnyChatContent: Equatable, Hashable, Sendable {
    public let contentTypeID: String
    private let box: AnyHashable

    public init<T: ChatContent>(_ content: T) {
        self.contentTypeID = T.contentTypeID
        self.box = AnyHashable(content)
    }

    public func content<T: ChatContent>(as type: T.Type) -> T? {
        box.base as? T
    }

    public static func == (lhs: AnyChatContent, rhs: AnyChatContent) -> Bool {
        lhs.box == rhs.box
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(box)
    }
}

// MARK: - Тело сообщения

public struct MessageBody: Equatable, Hashable {
    public let text: String?
    public let content: AnyChatContent?

    public init(text: String?, content: AnyChatContent? = nil) {
        self.text = text
        self.content = content
    }
}

// MARK: - Взаимодействие с контентом

/// Обобщённое взаимодействие с контентом. Библиотека маршрутизирует без анализа содержимого.
/// View из фабрики генерируют эти события; делегат их получает.
public struct ChatContentInteraction: Sendable {
    public let type: String
    public let payload: [String: AnyHashable]

    public init(type: String, payload: [String: AnyHashable] = [:]) {
        self.type = type
        self.payload = payload
    }
}

// MARK: - Реакция

public struct Reaction: Equatable, Hashable {
    public let emoji: String
    public let count: Int
    public let isSelected: Bool

    public init(emoji: String, count: Int, isSelected: Bool) {
        self.emoji = emoji
        self.count = count
        self.isSelected = isSelected
    }
}

// MARK: - Информация о цитате

public struct ReplyInfo: Equatable, Hashable {
    public let replyToId: String
    public let senderName: String?
    public let text: String?
    public let hasImage: Bool

    public init(replyToId: String, senderName: String?, text: String?, hasImage: Bool) {
        self.replyToId = replyToId
        self.senderName = senderName
        self.text = text
        self.hasImage = hasImage
    }
}

// MARK: - Информация о треде

public struct ThreadInfo: Equatable, Hashable {
    public let threadId: String
    public let replyCount: Int
    public let lastReplierName: String?

    public init(threadId: String, replyCount: Int, lastReplierName: String? = nil) {
        self.threadId = threadId
        self.replyCount = replyCount
        self.lastReplierName = lastReplierName
    }
}

// MARK: - Действие контекстного меню

public struct MessageAction: Equatable, Hashable {
    public let id: String
    public let title: String
    public let systemImage: String?
    public let isDestructive: Bool

    public init(id: String, title: String, systemImage: String?, isDestructive: Bool) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.isDestructive = isDestructive
    }
}

// MARK: - Сообщение чата

public struct ChatMessage: Equatable, Hashable {
    public let id: String
    /// Локальный ID для маппинга pending→real. Когда pending-сообщение (id="pending_1")
    /// подтверждается сервером (id="real_1"), оба делят один `localId`.
    /// Это позволяет diff-движку трактовать смену ID как обновление контента, а не delete+insert.
    public let localId: String?
    public let content: MessageBody
    public let timestamp: Date
    public let senderName: String?
    public let senderAvatarUrl: String?
    public let ownership: MessageOwnership
    public let groupDate: String
    public let status: MessageStatus
    public let reply: ReplyInfo?
    public let forwardedFrom: String?
    public let reactions: [Reaction]
    public let thread: ThreadInfo?
    public let isEdited: Bool
    public let actions: [MessageAction]

    public init(id: String, localId: String? = nil, content: MessageBody, timestamp: Date, senderName: String?, senderAvatarUrl: String? = nil, ownership: MessageOwnership, groupDate: String, status: MessageStatus, reply: ReplyInfo?, forwardedFrom: String?, reactions: [Reaction], thread: ThreadInfo? = nil, isEdited: Bool, actions: [MessageAction]) {
        self.id = id
        self.localId = localId
        self.content = content
        self.timestamp = timestamp
        self.senderName = senderName
        self.senderAvatarUrl = senderAvatarUrl
        self.ownership = ownership
        self.groupDate = groupDate
        self.status = status
        self.reply = reply
        self.forwardedFrom = forwardedFrom
        self.reactions = reactions
        self.thread = thread
        self.isEdited = isEdited
        self.actions = actions
    }
}

// MARK: - Отображение цитаты

public struct ReplyDisplayInfo {
    public let senderName: String
    public let text: String
    public let hasImage: Bool

    public init(senderName: String, text: String, hasImage: Bool) {
        self.senderName = senderName
        self.text = text
        self.hasImage = hasImage
    }
}
