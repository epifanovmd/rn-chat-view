import UIKit

// MARK: - События скролла

public protocol ChatScrollDelegate: AnyObject {
    func chatDidScroll(offset: CGPoint)
    func chatDidReachTop(distance: CGFloat)
    func chatDidReachBottom(distance: CGFloat)
    func chatDidTapFAB()
    /// Throttled (~300ms) якорь скролла для сохранения/восстановления позиции.
    func chatScrollAnchorChanged(anchor: ScrollAnchor)
}

public extension ChatScrollDelegate {
    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachTop(distance: CGFloat) {}
    func chatDidReachBottom(distance: CGFloat) {}
    func chatDidTapFAB() {}
    func chatScrollAnchorChanged(anchor: ScrollAnchor) {}
}

// MARK: - Видимость

public protocol ChatVisibilityDelegate: AnyObject {
    func chatVisibleMessagesDidChange(ids: [String])
    func chatUnreadMessagesDidAppear(ids: [String])
}

public extension ChatVisibilityDelegate {
    func chatVisibleMessagesDidChange(ids: [String]) {}
    func chatUnreadMessagesDidAppear(ids: [String]) {}
}

// MARK: - Взаимодействие с сообщениями

public protocol ChatMessageDelegate: AnyObject {
    func chatDidTapMessage(id: String, attachmentIndex: Int?)
    func chatDidSelectAction(actionId: String, messageId: String)
    func chatDidSelectEmojiReaction(emoji: String, messageId: String)
    func chatDidTapReaction(messageId: String, emoji: String)
    func chatDidTapReplyMessage(id: String)
    func chatDidTapThread(messageId: String, threadId: String)
    func chatDidTapLink(url: URL, messageId: String)
    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String)

    /// Универсальный callback для взаимодействий из factory-created views (poll, voice и т.д.).
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

// MARK: - События ввода

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

// MARK: - Композитный протокол

public typealias ChatViewControllerDelegate = ChatScrollDelegate & ChatVisibilityDelegate & ChatMessageDelegate & ChatInputDelegate
