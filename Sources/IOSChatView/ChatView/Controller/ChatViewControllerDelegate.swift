import UIKit

// MARK: - Scroll Events

public protocol ChatScrollDelegate: AnyObject {
    func chatDidScroll(offset: CGPoint)
    func chatDidReachTop(distance: CGFloat)
    func chatDidReachBottom(distance: CGFloat)
    func chatDidTapFAB()
}

public extension ChatScrollDelegate {
    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachTop(distance: CGFloat) {}
    func chatDidReachBottom(distance: CGFloat) {}
    func chatDidTapFAB() {}
}

// MARK: - Visibility

public protocol ChatVisibilityDelegate: AnyObject {
    /// Snapshot of currently visible message IDs (throttled).
    func chatVisibleMessagesDidChange(ids: [String])
    /// Accumulated unread message IDs that appeared on screen (debounced).
    func chatUnreadMessagesDidAppear(ids: [String])
}

public extension ChatVisibilityDelegate {
    func chatVisibleMessagesDidChange(ids: [String]) {}
    func chatUnreadMessagesDidAppear(ids: [String]) {}
}

// MARK: - Message Interactions

public protocol ChatMessageDelegate: AnyObject {
    func chatDidTapMessage(id: String, attachmentIndex: Int?)
    func chatDidSelectAction(actionId: String, messageId: String)
    func chatDidSelectEmojiReaction(emoji: String, messageId: String)
    func chatDidTapReaction(messageId: String, emoji: String)
    func chatDidTapReplyMessage(id: String)
    func chatDidTapThread(messageId: String, threadId: String)
    func chatDidTapLink(url: URL, messageId: String)
    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String)

    /// Generic content interaction from factory-created views.
    /// All media-type-specific interactions (poll tap, voice tap, etc.) go through this.
    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction)
}

public extension ChatMessageDelegate {
    func chatDidTapMessage(id: String, attachmentIndex: Int?) {}
    func chatDidSelectAction(actionId: String, messageId: String) {}
    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {}
    func chatDidTapReaction(messageId: String, emoji: String) {}
    func chatDidTapReplyMessage(id: String) {}
    func chatDidTapThread(messageId: String, threadId: String) {}
    func chatDidTapLink(url: URL, messageId: String) {}
    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String) {}
    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {}
}

// MARK: - Input Events

public protocol ChatInputDelegate: AnyObject {
    func chatDidSendMessage(text: String, replyToId: String?)
    func chatDidEditMessage(text: String, messageId: String)
    func chatDidCancelInputAction(type: String)
    func chatDidTapAttachment()
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float])
    func chatDidChangeInputText(_ text: String)
}

public extension ChatInputDelegate {
    func chatDidSendMessage(text: String, replyToId: String?) {}
    func chatDidEditMessage(text: String, messageId: String) {}
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() {}
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {}
    func chatDidChangeInputText(_ text: String) {}
}

// MARK: - Composite

public typealias ChatViewControllerDelegate = ChatScrollDelegate & ChatVisibilityDelegate & ChatMessageDelegate & ChatInputDelegate
