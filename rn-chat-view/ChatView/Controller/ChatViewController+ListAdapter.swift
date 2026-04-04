import IGListKit
import UIKit

// MARK: - ListAdapterDataSource

extension ChatViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        listItems
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        if object is MessageListItem {
            let sc = MessageSectionController()
            sc.sectionDelegate = self
            sc.theme = theme
            sc.layout = layout
            sc.features = features
            sc.replyResolver = { [weak self] info in
                guard let original = self?.messageIndex[info.replyToId] else { return nil }
                return ReplyDisplayInfo(
                    senderName: original.senderName ?? "Неизвестный",
                    text: original.content.text ?? "",
                    hasImage: original.content.media != nil
                )
            }
            return sc
        }
        if object is DateSeparatorListItem {
            let sc = DateSeparatorSectionController()
            sc.theme = theme
            sc.layout = layout
            return sc
        }
        if object is LoadingListItem {
            return LoadingSectionController()
        }
        fatalError("Unknown list item type")
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? { nil }
}

// MARK: - MessageSectionDelegate

extension ChatViewController: MessageSectionDelegate {
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
}
