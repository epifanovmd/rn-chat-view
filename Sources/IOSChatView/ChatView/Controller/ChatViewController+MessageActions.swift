import UIKit

// MARK: - Message Cell Action Routing

/// Routes cell interaction callbacks to the public `ChatViewControllerDelegate`.
extension ChatViewController {

    func messageSectionDidTap(messageId: String, attachmentIndex: Int?) {
        delegate?.chatDidTapMessage(id: messageId, attachmentIndex: attachmentIndex)
    }

    func messageSectionDidLongPress(messageId: String, cell: UICollectionViewCell) {
        guard features.contextMenuEnabled else { return }
        guard let msg = messageIndex[messageId] else { return }
        showContextMenu(for: msg, from: cell)
    }

    func messageSectionDidTapReply(messageId: String) {
        scrollToMessage(id: messageId, position: "center", animated: true, highlight: true)
        delegate?.chatDidTapReplyMessage(id: messageId)
    }

    func messageSectionDidTapPollOption(messageId: String, pollId: String, optionId: String) {
        delegate?.chatDidTapPollOption(messageId: messageId, pollId: pollId, optionId: optionId)
    }

    func messageSectionDidTapPollDetail(messageId: String, pollId: String) {
        delegate?.chatDidTapPollDetail(messageId: messageId, pollId: pollId)
    }

    func messageSectionDidTapVoice(messageId: String, url: String) {
        VoicePlayer.shared.toggle(url: url)
    }

    func messageSectionDidTapReaction(messageId: String, emoji: String) {
        delegate?.chatDidTapReaction(messageId: messageId, emoji: emoji)
    }

    func messageSectionDidCustomInteraction(messageId: String, type: String, payload: [String: AnyHashable]) {
        delegate?.chatDidCustomInteraction(messageId: messageId, type: type, payload: payload)
    }
}
