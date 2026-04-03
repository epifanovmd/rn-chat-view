import UIKit

// MARK: - Delegate

protocol InputBarDelegate: AnyObject {
    func inputBarDidSend(text: String, replyToId: String?)
    func inputBarDidEdit(text: String, messageId: String)
    func inputBarDidCancelMode(type: String)
    func inputBarDidTapAttachment()
    func inputBarDidStartRecording()
    func inputBarDidStopRecording()
    func inputBarDidCancelRecording()
    func inputBarDidChangeText(_ text: String)
    func inputBarRecordingStateChanged(isRecording: Bool)
}

extension InputBarDelegate {
    func inputBarRecordingStateChanged(isRecording: Bool) {}
}

// MARK: - Input Mode

enum InputBarMode: Equatable {
    case normal
    case reply(messageId: String, senderName: String?, text: String?, hasImage: Bool)
    case edit(messageId: String, text: String)
}

// MARK: - Recording State

enum RecordingState {
    case idle
    case recording
    case locked
}

// MARK: - Reply Display Info (for beginReply)

struct InputBarReplyInfo {
    let messageId: String
    let senderName: String?
    let text: String?
    let hasImage: Bool
}
