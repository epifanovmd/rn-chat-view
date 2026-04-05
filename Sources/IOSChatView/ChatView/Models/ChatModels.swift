import UIKit

// MARK: - Message Status

public enum MessageStatus: String {
    case sending, sent, delivered, read
}

// MARK: - Media Item (unified image/video)

public enum MediaItem: Equatable, Hashable {
    case image(ImageItem)
    case video(VideoItem)

    public var thumbnailUrl: String? {
        switch self {
        case .image(let i): return i.thumbnailUrl ?? i.url
        case .video(let v): return v.thumbnailUrl
        }
    }

    public var width: CGFloat? {
        switch self {
        case .image(let i): return i.width
        case .video(let v): return v.width
        }
    }

    public var height: CGFloat? {
        switch self {
        case .image(let i): return i.height
        case .video(let v): return v.height
        }
    }

    public var isVideo: Bool {
        if case .video = self { return true }
        return false
    }

    public var imageUrl: String? {
        if case .image(let i) = self { return i.url }
        return nil
    }

    public var videoUrl: String? {
        if case .video(let v) = self { return v.url }
        return nil
    }

    public var duration: TimeInterval? {
        if case .video(let v) = self { return v.duration }
        return nil
    }
}

// MARK: - Content Payloads

public struct ImageItem: Equatable, Hashable {
    public let url: String
    public let width: CGFloat?
    public let height: CGFloat?
    public let thumbnailUrl: String?

    public init(url: String, width: CGFloat?, height: CGFloat?, thumbnailUrl: String?) {
        self.url = url
        self.width = width
        self.height = height
        self.thumbnailUrl = thumbnailUrl
    }
}

public struct VideoItem: Equatable, Hashable {
    public let url: String
    public let thumbnailUrl: String?
    public let width: CGFloat?
    public let height: CGFloat?
    public let duration: TimeInterval?

    public init(url: String, thumbnailUrl: String?, width: CGFloat?, height: CGFloat?, duration: TimeInterval?) {
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.width = width
        self.height = height
        self.duration = duration
    }
}

public struct VoicePayload: Equatable, Hashable {
    public let url: String
    public let duration: TimeInterval
    public let waveform: [Float]

    public init(url: String, duration: TimeInterval, waveform: [Float]) {
        self.url = url
        self.duration = duration
        self.waveform = waveform
    }
}

public struct PollOption: Equatable, Hashable {
    public let id: String
    public let text: String
    public let votes: Int
    public let percentage: CGFloat

    public init(id: String, text: String, votes: Int, percentage: CGFloat) {
        self.id = id
        self.text = text
        self.votes = votes
        self.percentage = percentage
    }
}

public struct PollPayload: Equatable, Hashable {
    public let id: String
    public let question: String
    public let options: [PollOption]
    public let totalVotes: Int
    public let selectedOptionIds: [String]
    public let isMultipleChoice: Bool
    public let isClosed: Bool
    public let isAnonymous: Bool

    public init(id: String, question: String, options: [PollOption], totalVotes: Int, selectedOptionIds: [String], isMultipleChoice: Bool, isClosed: Bool, isAnonymous: Bool) {
        self.id = id
        self.question = question
        self.options = options
        self.totalVotes = totalVotes
        self.selectedOptionIds = selectedOptionIds
        self.isMultipleChoice = isMultipleChoice
        self.isClosed = isClosed
        self.isAnonymous = isAnonymous
    }
}

public struct FilePayload: Equatable, Hashable {
    public let url: String
    public let name: String
    public let size: Int64
    public let mimeType: String?

    public init(url: String, name: String, size: Int64, mimeType: String?) {
        self.url = url
        self.name = name
        self.size = size
        self.mimeType = mimeType
    }
}

// MARK: - Message Media (enum — ровно один тип медиа)

public enum MessageMedia: Equatable, Hashable {
    case images([MediaItem])
    case voice(VoicePayload)
    case poll(PollPayload)
    case files([FilePayload])
    case custom(type: String, payload: AnyHashable)
}

// MARK: - Message Content

public struct MessageContent: Equatable, Hashable {
    public let text: String?
    public let media: MessageMedia?

    public init(text: String?, media: MessageMedia?) {
        self.text = text
        self.media = media
    }
}

// MARK: - Content Interaction

public enum ChatContentInteraction {
    case mediaTap(index: Int)
    case fileTap(index: Int)
    case pollOptionTap(pollId: String, optionId: String)
    case pollDetailTap(pollId: String)
    case voiceTap(url: String)
    /// Generic interaction for custom content views.
    /// Use `type` to distinguish actions, `payload` for arbitrary data.
    case custom(type: String, payload: [String: AnyHashable])
}

// MARK: - Reaction

public struct Reaction: Equatable, Hashable {
    public let emoji: String
    public let count: Int
    public let isMine: Bool

    public init(emoji: String, count: Int, isMine: Bool) {
        self.emoji = emoji
        self.count = count
        self.isMine = isMine
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
    public let content: MessageContent
    public let timestamp: Date
    public let senderName: String?
    public let isMine: Bool
    public let groupDate: String
    public let status: MessageStatus
    public let reply: ReplyInfo?
    public let forwardedFrom: String?
    public let reactions: [Reaction]
    public let isEdited: Bool
    public let actions: [MessageAction]

    public init(id: String, content: MessageContent, timestamp: Date, senderName: String?, isMine: Bool, groupDate: String, status: MessageStatus, reply: ReplyInfo?, forwardedFrom: String?, reactions: [Reaction], isEdited: Bool, actions: [MessageAction]) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.senderName = senderName
        self.isMine = isMine
        self.groupDate = groupDate
        self.status = status
        self.reply = reply
        self.forwardedFrom = forwardedFrom
        self.reactions = reactions
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
