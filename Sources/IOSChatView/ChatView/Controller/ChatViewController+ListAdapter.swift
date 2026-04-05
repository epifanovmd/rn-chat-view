import IGListKit
import UIKit

// MARK: - ListAdapterDataSource

extension ChatViewController: ListAdapterDataSource {
    public func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        listItems
    }

    public func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        if object is MessageListItem {
            let sc = MessageSectionController()
            sc.sectionDelegate = self
            sc.theme = theme
            sc.layout = layout
            sc.features = features
            sc.factory = contentFactory
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
            sc.factory = contentFactory
            return sc
        }
        if object is LoadingListItem {
            return LoadingSectionController()
        }
        fatalError("Unknown list item type")
    }

    public func emptyView(for listAdapter: ListAdapter) -> UIView? { nil }
}

// MARK: - MessageSectionDelegate

extension ChatViewController: MessageSectionDelegate {
    public func messageSectionDidTap(messageId: String, attachmentIndex: Int?) {
        delegate?.chatDidTapMessage(id: messageId, attachmentIndex: attachmentIndex)
    }

    public func messageSectionDidLongPress(messageId: String, cell: UICollectionViewCell) {
        guard features.contextMenuEnabled else { return }
        guard let msg = messageIndex[messageId] else { return }
        showContextMenu(for: msg, from: cell)
    }

    public func messageSectionDidTapReply(messageId: String) {
        scrollToMessage(id: messageId, position: "center", animated: true, highlight: true)
        delegate?.chatDidTapReplyMessage(id: messageId)
    }

    public func messageSectionDidTapPollOption(messageId: String, pollId: String, optionId: String) {
        delegate?.chatDidTapPollOption(messageId: messageId, pollId: pollId, optionId: optionId)
    }

    public func messageSectionDidTapPollDetail(messageId: String, pollId: String) {
        delegate?.chatDidTapPollDetail(messageId: messageId, pollId: pollId)
    }

    public func messageSectionDidTapVoice(messageId: String, url: String) {
        VoicePlayer.shared.toggle(url: url)
    }

    public func messageSectionDidTapReaction(messageId: String, emoji: String) {
        delegate?.chatDidTapReaction(messageId: messageId, emoji: emoji)
    }
}
