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
            return sc
        }
        if object is DateSeparatorListItem {
            let sc = DateSeparatorSectionController()
            sc.themeProvider = self
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
    var currentTheme: ChatTheme { theme }
    var showSenderName: Bool { showsSenderName }

    func resolveReply(for info: ReplyInfo) -> ReplyDisplayInfo? {
        guard let original = messageIndex[info.replyToId] else { return nil }
        return ReplyDisplayInfo(
            senderName: original.senderName ?? "Unknown",
            text: original.content.text ?? "",
            hasImage: original.content.media != nil
        )
    }

    func messageSectionDidTap(messageId: String, attachmentIndex: Int?) {
        delegate?.chatDidTapMessage(id: messageId, attachmentIndex: attachmentIndex)
    }

    func messageSectionDidLongPress(messageId: String, cell: UICollectionViewCell) {
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

// MARK: - Visibility Tracking

extension ChatViewController {
    func updateVisibleMessages() {
        guard !messages.isEmpty else { return }
        var ids: Set<String> = []
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  indexPath.section < listItems.count,
                  let msgItem = listItems[indexPath.section] as? MessageListItem,
                  msgItem.message.status != .read else { continue }
            ids.insert(msgItem.message.id)
        }

        let newIDs = ids.subtracting(visibleMessageIDs)
        guard !newIDs.isEmpty else { return }
        visibleMessageIDs = ids

        // Декремент счётчика непрочитанных
        let readUnread = newIDs.intersection(unreadMessageIDs)
        if !readUnread.isEmpty {
            unreadMessageIDs.subtract(readUnread)
            unreadCount = unreadMessageIDs.count
        }

        pendingVisibleIDs.formUnion(newIDs)
        visibilityDebounceTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self, !self.pendingVisibleIDs.isEmpty else { return }
            let batch = Array(self.pendingVisibleIDs)
            self.pendingVisibleIDs.removeAll()
            self.delegate?.chatMessagesDidAppear(ids: batch)
        }
        visibilityDebounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + visibilityDebounceInterval, execute: task)
    }
}
