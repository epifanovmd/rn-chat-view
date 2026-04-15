import UIKit

// MARK: - Делегат

public protocol InputBarDelegate: AnyObject {
    func inputBarDidSend(text: String, replyToId: String?)
    func inputBarDidEdit(text: String, messageId: String)
    func inputBarDidCancelMode(type: String)
    func inputBarDidTapAttachment()
    func inputBarDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float])
    func inputBarDidChangeText(_ text: String)
    func inputBarRecordingStateChanged(isRecording: Bool)
}

extension InputBarDelegate {
    func inputBarRecordingStateChanged(isRecording: Bool) {}
}

// MARK: - Режим ввода

public enum InputBarMode: Equatable {
    case normal
    case reply(messageId: String, senderName: String?, text: String?, hasImage: Bool)
    case edit(messageId: String, text: String)
}

// MARK: - Состояние записи

public enum RecordingState {
    case idle
    case recording
    case locked
}

// MARK: - Данные для отображения ответа

public struct InputBarReplyInfo {
    public let messageId: String
    public let senderName: String?
    public let text: String?
    public let hasImage: Bool

    public init(messageId: String, senderName: String?, text: String?, hasImage: Bool) {
        self.messageId = messageId
        self.senderName = senderName
        self.text = text
        self.hasImage = hasImage
    }
}
