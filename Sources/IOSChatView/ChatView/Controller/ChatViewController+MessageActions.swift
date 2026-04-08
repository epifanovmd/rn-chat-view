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

    func messageSectionDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
        delegate?.chatDidContentInteraction(messageId: messageId, interaction: interaction)
    }

    func messageSectionDidTapReaction(messageId: String, emoji: String) {
        delegate?.chatDidTapReaction(messageId: messageId, emoji: emoji)
    }

    func messageSectionDidTapThread(messageId: String, threadId: String) {
        delegate?.chatDidTapThread(messageId: messageId, threadId: threadId)
    }

    func messageSectionDidTapLink(url: URL, messageId: String) {
        delegate?.chatDidTapLink(url: url, messageId: messageId)
    }

    func messageSectionDidTapPhoneNumber(phoneNumber: String, messageId: String) {
        delegate?.chatDidTapPhoneNumber(phoneNumber: phoneNumber, messageId: messageId)
    }
}
