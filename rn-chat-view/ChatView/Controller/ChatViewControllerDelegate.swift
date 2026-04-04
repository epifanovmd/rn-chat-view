import UIKit

// MARK: - Scroll Events

protocol ChatScrollDelegate: AnyObject {
    func chatDidScroll(offset: CGPoint)
    func chatDidReachTop(distance: CGFloat)
    func chatDidReachBottom(distance: CGFloat)
    func chatDidTapFAB()
}

extension ChatScrollDelegate {
    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachTop(distance: CGFloat) {}
    func chatDidReachBottom(distance: CGFloat) {}
    func chatDidTapFAB() {}
}

// MARK: - Visibility

protocol ChatVisibilityDelegate: AnyObject {
    func chatMessagesDidAppear(ids: [String])
}

extension ChatVisibilityDelegate {
    func chatMessagesDidAppear(ids: [String]) {}
}

// MARK: - Message Interactions

protocol ChatMessageDelegate: AnyObject {
    func chatDidTapMessage(id: String, attachmentIndex: Int?)
    func chatDidSelectAction(actionId: String, messageId: String)
    func chatDidSelectEmojiReaction(emoji: String, messageId: String)
    func chatDidTapReaction(messageId: String, emoji: String)
    func chatDidTapReplyMessage(id: String)
    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String)
    func chatDidTapPollDetail(messageId: String, pollId: String)
}

extension ChatMessageDelegate {
    func chatDidTapMessage(id: String, attachmentIndex: Int?) {}
    func chatDidSelectAction(actionId: String, messageId: String) {}
    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {}
    func chatDidTapReaction(messageId: String, emoji: String) {}
    func chatDidTapReplyMessage(id: String) {}
    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String) {}
    func chatDidTapPollDetail(messageId: String, pollId: String) {}
}

// MARK: - Input Events

protocol ChatInputDelegate: AnyObject {
    func chatDidSendMessage(text: String, replyToId: String?)
    func chatDidEditMessage(text: String, messageId: String)
    func chatDidCancelInputAction(type: String)
    func chatDidTapAttachment()
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float])
    func chatDidChangeInputText(_ text: String)
}

extension ChatInputDelegate {
    func chatDidSendMessage(text: String, replyToId: String?) {}
    func chatDidEditMessage(text: String, messageId: String) {}
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() {}
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {}
    func chatDidChangeInputText(_ text: String) {}
}

// MARK: - Composite

typealias ChatViewControllerDelegate = ChatScrollDelegate & ChatVisibilityDelegate & ChatMessageDelegate & ChatInputDelegate
