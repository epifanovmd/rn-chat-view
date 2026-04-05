import IGListKit
import UIKit

/// Handles message update logic: detects prepend/append/initial/content updates
/// and applies them to the collection view with appropriate scroll compensation.
public final class MessageUpdateHandler {

    private weak var controller: ChatViewController?

    init(controller: ChatViewController) {
        self.controller = controller
    }

    // MARK: - Update

    func update(with newMessages: [ChatMessage]) {
        guard let vc = controller else { return }

        let wasAtBottom = vc.isNearBottom()
        let wasEmpty = vc.messages.isEmpty
        let oldFirstId = vc.messages.first?.id
        let oldLastId = vc.messages.last?.id
        let oldCount = vc.messages.count

        vc.applyMessages(newMessages)

        let grew = newMessages.count > oldCount

        let isPrepend = !wasEmpty && grew
            && oldFirstId != nil && oldFirstId != newMessages.first?.id
            && oldLastId == newMessages.last?.id

        let isAppend = !wasEmpty && grew
            && oldLastId != nil && oldLastId != newMessages.last?.id

        if isPrepend {
            handlePrepend(vc: vc, count: newMessages.count)
        } else if isAppend {
            handleAppend(vc: vc, wasAtBottom: wasAtBottom, oldCount: oldCount, newMessages: newMessages)
        } else if wasEmpty && !newMessages.isEmpty {
            handleInitialLoad(vc: vc, count: newMessages.count)
        } else {
            handleContentUpdate(vc: vc, count: newMessages.count)
        }
    }

    // MARK: - Strategies

    private func handlePrepend(vc: ChatViewController, count: Int) {
        vc.collectionView.prePrependContentHeight = vc.collectionView.contentSize.height
        vc.collectionView.prePrependContentOffset = vc.collectionView.contentOffset.y
        vc.collectionView.needsPrependCompensation = true
        vc.adapter.performUpdates(animated: false) { [weak vc] _ in
            vc?.finalizeUpdate(count: count, animated: false)
        }
    }

    private func handleAppend(vc: ChatViewController, wasAtBottom: Bool, oldCount: Int, newMessages: [ChatMessage]) {
        let wasLoadingNewer = vc.isLoadingNewerActive
        let wantScroll = vc.pendingScrollToBottom || (wasAtBottom && !vc.isLoadingNewerActive)
        vc.isLoadingNewerActive = false

        if wantScroll {
            vc.pendingScrollToBottom = false
            vc.adapter.performUpdates(animated: false) { [weak vc] _ in
                guard let vc else { return }
                vc.scrollToBottom(animated: true)
                vc.finalizeUpdate(count: newMessages.count, animated: false)
            }
        } else {
            if !wasLoadingNewer && !wasAtBottom {
                vc.trackNewUnread(newMessages: newMessages, oldCount: oldCount)
            }
            let savedOffset = vc.collectionView.contentOffset
            vc.adapter.performUpdates(animated: false) { [weak vc] _ in
                guard let vc else { return }
                vc.collectionView.contentOffset = savedOffset
                vc.finalizeUpdate(count: newMessages.count, animated: false)
            }
        }
    }

    private func handleInitialLoad(vc: ChatViewController, count: Int) {
        vc.adapter.reloadData { [weak vc] _ in
            guard let vc else { return }
            if let scrollId = vc.pendingScrollMessageId {
                vc.scrollToMessage(id: scrollId, position: "center", animated: false, highlight: true)
                vc.pendingScrollMessageId = nil
            } else {
                vc.scrollToBottom(animated: false)
            }
            vc.isInitialScrollProtected = false
            vc.finalizeUpdate(count: count, animated: false)
        }
    }

    private func handleContentUpdate(vc: ChatViewController, count: Int) {
        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }
        vc.adapter.performUpdates(animated: !shouldScroll) { [weak vc] _ in
            guard let vc else { return }
            if shouldScroll { vc.scrollToBottom(animated: true) }
            vc.finalizeUpdate(count: count, animated: !shouldScroll)
        }
    }
}
