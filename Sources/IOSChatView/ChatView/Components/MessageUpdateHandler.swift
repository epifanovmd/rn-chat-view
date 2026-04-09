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
        vc.setMessages(newMessages)
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
        // Clear stale heights from previous session (e.g., clear → reload same IDs with different content)
        vc.sizeCache.invalidateAll()
        vc.setRows(newRows)
        vc.applyLayoutData(vc.computeLayoutData())
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

    /// Older messages inserted at the top — incremental insert + offset compensation.
    private func applyPrepend(vc: ChatViewController, newRows: [ChatRow]) {
        let oldRowCount = vc.rows.count
        let insertedCount = newRows.count - oldRowCount
        guard insertedCount > 0 else { return }

        // Extract only the prepended rows
        let prependedRows = Array(newRows[0..<insertedCount])

        // 1. Update model — rows and messageIndex must be consistent before layout
        vc.setRows(newRows)

        // 2. Compute layout ONLY for new rows — O(insertedCount)
        let prependedLayout = vc.computeLayoutInfo(for: prependedRows)

        // 3. Sum heights for scroll compensation (before reloadData)
        var compensatingOffset: CGFloat = 0
        for info in prependedLayout {
            compensatingOffset += info.totalHeight
        }

        // 4. Update all caches atomically, then reload
        vc.rebuildCachesIncremental(insertedCount: insertedCount)
        vc.prependLayoutData(prependedLayout, insertedRowCount: insertedCount)

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
        vc.setRows(newRows)
        vc.applyLayoutData(vc.computeLayoutData())
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

    /// Content change (edit, delete, reorder, reactions).
    ///
    /// For pure content updates (same row count, same structure) — reconfigures
    /// visible cells in-place without dequeue, preserving the view hierarchy
    /// and enabling animations (e.g., poll bar transitions).
    ///
    /// For structural changes (row count differs, inserts/deletes) — falls back
    /// to DifferenceKit animated batch updates.
    private func applyContent(vc: ChatViewController, newRows: [ChatRow], wasAtBottom: Bool) {
        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }

        // Invalidate size cache for messages whose content changed.
        invalidateChangedSizes(oldRows: vc.rows, newRows: newRows, vc: vc)

        let changeset = StagedChangeset(source: vc.rows, target: newRows)

        guard !changeset.isEmpty else {
            vc.setRows(newRows)
            return
        }

        let savedOffset = vc.collectionView.contentOffset

        // Check if this is a pure content update (no inserts/deletes/moves)
        let isPureContent = isPureContentChange(changeset)

        if isPureContent {
            // Find changed message IDs
            let changedIDs = findChangedMessageIDs(oldRows: vc.rows, newRows: newRows)

            // Update model
            vc.setRows(newRows)
            vc.applyLayoutData(vc.computeLayoutData())

            // Reconfigure visible cells in-place
            for cell in vc.collectionView.visibleCells {
                guard let msgCell = cell as? MessageCell,
                      let indexPath = vc.collectionView.indexPath(for: cell),
                      indexPath.item < newRows.count,
                      case .message(let msg) = newRows[indexPath.item],
                      changedIDs.contains(msg.id) else { continue }

                vc.dataSource.reconfigureMessageCellInPlace(msgCell, message: msg, vc: vc)
            }

            // Invalidate layout for size changes
            vc.collectionView.collectionViewLayout.invalidateLayout()
            vc.collectionView.layoutIfNeeded()
        } else {
            // Structural change — use DifferenceKit
            vc.collectionView.reload(using: changeset) { [weak vc] data in
                guard let vc else { return }
                vc.setRows(data)
                vc.applyLayoutData(vc.computeLayoutData())
            }

            // Safety: if DifferenceKit left rows in intermediate state, force final.
            if vc.rows != newRows {
                vc.setRows(newRows)
                vc.applyLayoutData(vc.computeLayoutData())
                vc.collectionView.reloadData()
            }

            vc.collectionView.layoutIfNeeded()
            reconfigureVisibleAvatars(vc: vc)
        }

        if shouldScroll {
            vc.scrollToBottom(animated: true)
        } else if !wasAtBottom {
            vc.collectionView.contentOffset = savedOffset
        }

        vc.finalizeUpdate(count: newRows.count, animated: true)
        vc.flushPendingMessages()
    }

    /// Returns true if the changeset contains only element updates (no inserts, deletes, moves, or section changes).
    private func isPureContentChange(_ changeset: StagedChangeset<[ChatRow]>) -> Bool {
        for stage in changeset {
            if !stage.elementInserted.isEmpty || !stage.elementDeleted.isEmpty || !stage.elementMoved.isEmpty {
                return false
            }
            if !stage.sectionInserted.isEmpty || !stage.sectionDeleted.isEmpty || !stage.sectionMoved.isEmpty {
                return false
            }
        }
        return true
    }

    /// Returns IDs of messages whose content changed between old and new rows.
    private func findChangedMessageIDs(oldRows: [ChatRow], newRows: [ChatRow]) -> Set<String> {
        var oldById: [String: ChatRow] = [:]
        oldById.reserveCapacity(oldRows.count)
        for row in oldRows {
            if let id = row.messageId { oldById[id] = row }
        }
        var changed = Set<String>()
        for row in newRows {
            guard case .message(let msg) = row else { continue }
            if let old = oldById[msg.id], !row.isContentEqual(to: old) {
                changed.insert(msg.id)
            }
        }
        return changed
    }

    // MARK: - Helpers

    /// Reconfigure all visible avatar supplementary views to match current avatar groups.
    /// UICollectionView does not reconfigure visible supplementary views after
    /// performBatchUpdates — they keep stale content.
    private func reconfigureVisibleAvatars(vc: ChatViewController) {
        let cv = vc.collectionView!
        let groups = vc.chatLayout.avatarGroups
        let kind = AvatarSupplementaryView.kind
        for i in 0..<groups.count {
            let ip = IndexPath(item: i, section: 0)
            guard let avatar = cv.supplementaryView(forElementKind: kind, at: ip) as? AvatarSupplementaryView else { continue }
            let group = groups[i]
            let view = vc.contentFactory.avatarView(
                name: group.senderName,
                url: group.senderAvatarUrl,
                size: vc.layout.avatarSize,
                theme: vc.theme,
                layout: vc.layout
            )
            avatar.configure(view: view, size: vc.layout.avatarSize)
        }
    }

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
                vc.invalidateSizeCache(forKey: msg.id)
            }
        }
    }
}
