import UIKit

// MARK: - Message Ownership

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

// MARK: - Message Alignment

public enum MessageAlignment: Sendable {
    case leading, trailing, center
}

// MARK: - Message Status

public enum MessageStatus: String {
    case sending, sent, delivered, read
}

// MARK: - ChatContent (extensible protocol)

/// Protocol for any content type attached to a message.
/// The library is agnostic to concrete types — all rendering and interaction
/// logic lives in `ChatContentFactory`.
///
/// Conform your own types to use them as first-class message content:
/// ```swift
/// struct PaymentContent: ChatContent {
///     static let contentTypeID = "payment"
///     let amount: Decimal
///     let currency: String
/// }
/// ```
public protocol ChatContent: Equatable, Hashable, Sendable {
    /// Stable identifier for this content type. Must be unique per type.
    /// Used for in-place reconfiguration optimization (same typeID = same view structure).
    static var contentTypeID: String { get }
}

// MARK: - AnyChatContent (type-erased wrapper)

/// Type-erased wrapper for any `ChatContent`. Preserves `Equatable`/`Hashable`
/// for DifferenceKit diffing while hiding the concrete type from the library core.
public struct AnyChatContent: Equatable, Hashable, Sendable {
    public let contentTypeID: String
    private let box: AnyHashable

    public init<T: ChatContent>(_ content: T) {
        self.contentTypeID = T.contentTypeID
        self.box = AnyHashable(content)
    }

    /// Unwrap to a specific type. Returns nil if the type doesn't match.
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

// MARK: - Message Content

public struct MessageBody: Equatable, Hashable {
    public let text: String?
    public let content: AnyChatContent?

    public init(text: String?, content: AnyChatContent? = nil) {
        self.text = text
        self.content = content
    }
}

// MARK: - Content Interaction

/// Generic content interaction. The library routes it without inspecting contents.
/// Factory-created views fire these; the delegate receives them.
public struct ChatContentInteraction: Sendable {
    public let type: String
    public let payload: [String: AnyHashable]

    public init(type: String, payload: [String: AnyHashable] = [:]) {
        self.type = type
        self.payload = payload
    }
}

// MARK: - Reaction

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

// MARK: - Reply Info

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

// MARK: - Thread Info

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

// MARK: - Message Action

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

// MARK: - Chat Message

public struct ChatMessage: Equatable, Hashable {
    public let id: String
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

    public init(id: String, content: MessageBody, timestamp: Date, senderName: String?, senderAvatarUrl: String? = nil, ownership: MessageOwnership, groupDate: String, status: MessageStatus, reply: ReplyInfo?, forwardedFrom: String?, reactions: [Reaction], thread: ThreadInfo? = nil, isEdited: Bool, actions: [MessageAction]) {
        self.id = id
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

// MARK: - Reply Display

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
