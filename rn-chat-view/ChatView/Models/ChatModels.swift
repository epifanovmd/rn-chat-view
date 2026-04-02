import UIKit

// MARK: - Message Status

enum MessageStatus: String {
    case sending, sent, delivered, read
}

// MARK: - Media Item (unified image/video)

enum MediaItem: Equatable, Hashable {
    case image(ImageItem)
    case video(VideoItem)

    var thumbnailUrl: String? {
        switch self {
        case .image(let i): return i.thumbnailUrl ?? i.url
        case .video(let v): return v.thumbnailUrl
        }
    }

    var width: CGFloat? {
        switch self {
        case .image(let i): return i.width
        case .video(let v): return v.width
        }
    }

    var height: CGFloat? {
        switch self {
        case .image(let i): return i.height
        case .video(let v): return v.height
        }
    }

    var isVideo: Bool {
        if case .video = self { return true }
        return false
    }

    var imageUrl: String? {
        if case .image(let i) = self { return i.url }
        return nil
    }

    var videoUrl: String? {
        if case .video(let v) = self { return v.url }
        return nil
    }

    var duration: TimeInterval? {
        if case .video(let v) = self { return v.duration }
        return nil
    }
}

// MARK: - Content Payloads

struct ImageItem: Equatable, Hashable {
    let url: String
    let width: CGFloat?
    let height: CGFloat?
    let thumbnailUrl: String?
}

struct VideoItem: Equatable, Hashable {
    let url: String
    let thumbnailUrl: String?
    let width: CGFloat?
    let height: CGFloat?
    let duration: TimeInterval?
}

struct VoicePayload: Equatable, Hashable {
    let url: String
    let duration: TimeInterval
    let waveform: [Float]
}

struct PollOption: Equatable, Hashable {
    let id: String
    let text: String
    let votes: Int
    let percentage: CGFloat
}

struct PollPayload: Equatable, Hashable {
    let id: String
    let question: String
    let options: [PollOption]
    let totalVotes: Int
    let selectedOptionIds: [String]
    let isMultipleChoice: Bool
    let isClosed: Bool
}

struct FilePayload: Equatable, Hashable {
    let url: String
    let name: String
    let size: Int64
    let mimeType: String?
}

// MARK: - Message Content

struct MessageContent: Equatable, Hashable {
    let text: String?
    let media: [MediaItem]?
    let voice: VoicePayload?
    let poll: PollPayload?
    let files: [FilePayload]?

    var hasMedia: Bool {
        (media != nil && !(media!.isEmpty)) || voice != nil || poll != nil || (files != nil && !(files!.isEmpty))
    }
}

// MARK: - Reaction

struct Reaction: Equatable, Hashable {
    let emoji: String
    let count: Int
    let isMine: Bool
}

// MARK: - Reply Info

struct ReplyInfo: Equatable, Hashable {
    let replyToId: String
    let senderName: String?
    let text: String?
    let hasImage: Bool
}

// MARK: - Message Action

struct MessageAction: Equatable, Hashable {
    let id: String
    let title: String
    let systemImage: String?
    let isDestructive: Bool
}

// MARK: - Chat Message

struct ChatMessage: Equatable, Hashable {
    let id: String
    let content: MessageContent
    let timestamp: Date
    let senderName: String?
    let isMine: Bool
    let groupDate: String
    let status: MessageStatus
    let reply: ReplyInfo?
    let forwardedFrom: String?
    let reactions: [Reaction]
    let isEdited: Bool
    let actions: [MessageAction]
}

// MARK: - Input Action

enum ChatInputAction: Equatable, Hashable {
    case none
    case reply(messageId: String)
    case edit(messageId: String)
}

// MARK: - Reply Display

struct ReplyDisplayInfo {
    let senderName: String
    let text: String
    let hasImage: Bool
}
