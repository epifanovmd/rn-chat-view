import UIKit
import DifferenceKit

/// Detects the type of message update (initial / prepend / append / content)
/// and applies it to the collection view using the optimal strategy.
///
/// - **Initial**: `reloadData` + deferred scroll to bottom.
/// - **Prepend**: `reloadData` + manual content-offset compensation.
/// - **Append**: `reloadData` + scroll to bottom (if near bottom).
/// - **Content** (edit, delete, reorder, reactions, polls):
///   DifferenceKit `StagedChangeset` → animated `performBatchUpdates`.
final class MessageUpdateHandler {

    private weak var controller: ChatViewController?

    init(controller: ChatViewController) {
        self.controller = controller
    }

    // MARK: - Entry Point

    func update(with newMessages: [ChatMessage]) {
        guard let vc = controller else { return }

        let wasAtBottom = vc.isNearBottom()
        let wasEmpty    = vc.messages.isEmpty
        let oldFirstId  = vc.messages.first?.id
        let oldLastId   = vc.messages.last?.id
        let oldCount    = vc.messages.count

        // Update model
        vc.messages = newMessages
        vc.rebuildMessageIndex()

        // Build target row array
        let newRows = vc.buildRows(from: newMessages)
        let grew = newMessages.count > oldCount

        let isPrepend = !wasEmpty && grew
            && oldFirstId != nil && oldFirstId != newMessages.first?.id
            && oldLastId == newMessages.last?.id

        let isAppend = !wasEmpty && grew
            && oldLastId != nil && oldLastId != newMessages.last?.id

        if wasEmpty && !newMessages.isEmpty {
            applyInitial(vc: vc, newRows: newRows)
        } else if isPrepend {
            applyPrepend(vc: vc, newRows: newRows)
        } else if isAppend {
            applyAppend(vc: vc, newRows: newRows, wasAtBottom: wasAtBottom, oldCount: oldCount)
        } else {
            applyContent(vc: vc, newRows: newRows, wasAtBottom: wasAtBottom)
        }
    }

    // MARK: - Strategies

    /// First batch of messages — reload + scroll to bottom.
    private func applyInitial(vc: ChatViewController, newRows: [ChatRow]) {
        vc.rows = newRows
        vc.chatLayout.rowLayoutData = vc.computeLayoutData()
        vc.collectionView.reloadData()

        // Defer scroll — content insets may not be final yet on first layout pass.
        DispatchQueue.main.async { [weak vc] in
            guard let vc else { return }
            vc.collectionView.layoutIfNeeded()
            if let scrollId = vc.pendingScrollMessageId {
                vc.scrollToMessage(id: scrollId, position: "center", animated: false, highlight: true)
                vc.pendingScrollMessageId = nil
            } else {
                vc.scrollToBottom(animated: false)
            }
            vc.isInitialScrollProtected = false
            vc.finalizeUpdate(count: newRows.count, animated: false)
        }
    }

    /// Older messages inserted at the top — reload + offset compensation.
    private func applyPrepend(vc: ChatViewController, newRows: [ChatRow]) {
        let oldRowCount = vc.rows.count
        vc.rows = newRows

        let layoutData = vc.computeLayoutData()
        vc.chatLayout.rowLayoutData = layoutData

        // Sum heights of prepended rows to compute scroll compensation.
        let insertedCount = newRows.count - oldRowCount
        var compensatingOffset: CGFloat = 0
        for i in 0..<max(0, insertedCount) {
            compensatingOffset += layoutData[i].totalHeight
        }

        let savedOffset = vc.collectionView.contentOffset
        vc.collectionView.reloadData()
        vc.collectionView.layoutIfNeeded()

        vc.collectionView.contentOffset = CGPoint(
            x: savedOffset.x,
            y: savedOffset.y + compensatingOffset
        )

        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }

    /// New messages at the bottom — reload + scroll if near bottom.
    private func applyAppend(vc: ChatViewController, newRows: [ChatRow], wasAtBottom: Bool, oldCount: Int) {
        let wantScroll = vc.pendingScrollToBottom || (wasAtBottom && !vc.isLoadingNewerActive)
        let wasLoadingNewer = vc.isLoadingNewerActive
        vc.isLoadingNewerActive = false
        if wantScroll { vc.pendingScrollToBottom = false }

        if !wasLoadingNewer && !wasAtBottom {
            vc.trackNewUnread(newMessages: vc.messages, oldCount: oldCount)
        }

        let savedOffset = vc.collectionView.contentOffset
        vc.rows = newRows
        vc.chatLayout.rowLayoutData = vc.computeLayoutData()
        vc.collectionView.reloadData()
        vc.collectionView.layoutIfNeeded()

        if wantScroll {
            vc.scrollToBottom(animated: true)
        } else {
            vc.collectionView.contentOffset = savedOffset
        }

        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }

    /// Content change (edit, delete, reorder, reactions, polls) —
    /// DifferenceKit animated diff, only affected cells animate.
    private func applyContent(vc: ChatViewController, newRows: [ChatRow], wasAtBottom: Bool) {
        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }

        // Invalidate size cache for messages whose content changed.
        invalidateChangedSizes(oldRows: vc.rows, newRows: newRows, vc: vc)

        let changeset = StagedChangeset(source: vc.rows, target: newRows)

        guard !changeset.isEmpty else {
            vc.rows = newRows
            return
        }

        let savedOffset = vc.collectionView.contentOffset

        vc.collectionView.reload(using: changeset) { [weak vc] data in
            guard let vc else { return }
            vc.rows = data
            vc.chatLayout.rowLayoutData = vc.computeLayoutData()
        }

        // Safety: if DifferenceKit left rows in intermediate state, force final.
        if vc.rows.count != newRows.count {
            vc.rows = newRows
            vc.chatLayout.rowLayoutData = vc.computeLayoutData()
            vc.collectionView.reloadData()
        }

        vc.collectionView.layoutIfNeeded()

        if shouldScroll {
            vc.scrollToBottom(animated: true)
        } else if !wasAtBottom {
            vc.collectionView.contentOffset = savedOffset
        }

        vc.finalizeUpdate(count: newRows.count, animated: true)
        vc.flushPendingMessages()
    }

    // MARK: - Helpers

    /// Invalidate sizeCache only for messages whose content actually changed.
    private func invalidateChangedSizes(oldRows: [ChatRow], newRows: [ChatRow], vc: ChatViewController) {
        var oldById: [String: ChatRow] = [:]
        oldById.reserveCapacity(oldRows.count)
        for row in oldRows {
            if let id = row.messageId { oldById[id] = row }
        }
        for row in newRows {
            guard case .message(let msg) = row else { continue }
            if let old = oldById[msg.id], !row.isContentEqual(to: old) {
                vc.sizeCache.removeValue(forKey: msg.id)
            }
        }
    }
}
