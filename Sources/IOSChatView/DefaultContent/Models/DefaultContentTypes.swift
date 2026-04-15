import UIKit

// MARK: - Изображения

public struct ImagesContent: ChatContent {
    public static let contentTypeID = "builtin.images"
    public let items: [MediaItem]
    public init(_ items: [MediaItem]) { self.items = items }
}

public enum MediaItem: Equatable, Hashable, Sendable {
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

public struct ImageItem: Equatable, Hashable, Sendable {
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

public struct VideoItem: Equatable, Hashable, Sendable {
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

// MARK: - Голосовое сообщение

public struct VoicePayload: Equatable, Hashable, Sendable, ChatContent {
    public static let contentTypeID = "builtin.voice"

    public let url: String
    public let duration: TimeInterval
    public let waveform: [Float]

    public init(url: String, duration: TimeInterval, waveform: [Float]) {
        self.url = url
        self.duration = duration
        self.waveform = waveform
    }
}

// MARK: - Опрос

public struct PollOption: Equatable, Hashable, Sendable {
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

public struct PollPayload: Equatable, Hashable, Sendable, ChatContent {
    public static let contentTypeID = "builtin.poll"

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

// MARK: - Файлы

public struct FilePayload: Equatable, Hashable, Sendable {
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

public struct FilesContent: ChatContent {
    public static let contentTypeID = "builtin.files"
    public let items: [FilePayload]
    public init(_ items: [FilePayload]) { self.items = items }
}

// MARK: - Фабричные методы взаимодействий

extension ChatContentInteraction {
    public static func mediaTap(index: Int) -> ChatContentInteraction {
        .init(type: "mediaTap", payload: ["index": index])
    }
    public static func fileTap(index: Int) -> ChatContentInteraction {
        .init(type: "fileTap", payload: ["index": index])
    }
    public static func pollOptionTap(pollId: String, optionId: String) -> ChatContentInteraction {
        .init(type: "pollOptionTap", payload: ["pollId": pollId, "optionId": optionId])
    }
    public static func pollDetailTap(pollId: String) -> ChatContentInteraction {
        .init(type: "pollDetailTap", payload: ["pollId": pollId])
    }
    public static func voiceTap(url: String) -> ChatContentInteraction {
        .init(type: "voiceTap", payload: ["url": url])
    }
}
