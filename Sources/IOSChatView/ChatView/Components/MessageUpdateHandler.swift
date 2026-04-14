import UIKit
import DifferenceKit

/// Routes message updates to the optimal strategy and keeps scroll stable.
///
/// Single-level classification — O(n) ID comparison, no heuristics:
///
/// | Strategy    | Condition                     | Method                                |
/// |-------------|-------------------------------|---------------------------------------|
/// | Initial     | Old empty, new not empty      | `reloadData` + pending scroll         |
/// | Content     | Same IDs, same order          | Incremental patch + offset fix        |
/// | Prepend     | Old IDs are suffix of new     | `reloadData` + offset compensation    |
/// | Append      | Old IDs are prefix of new     | `reloadData` + auto-scroll            |
/// | Structural  | Everything else               | DifferenceKit or reload + anchor      |
///
/// **Bottom-edge-stable**: content updates pin the anchor
/// message's bottom edge to its screen position — height changes expand upward.
final class MessageUpdateHandler {

    private weak var controller: ChatViewController?

    init(controller: ChatViewController) {
        self.controller = controller
    }

    enum Strategy { case initial, content, prepend, append, structural }

    // MARK: - Public

    /// Peek at what strategy would be used without applying. Used to decide deferral.
    func peekClassify(old: [ChatMessage], new: [ChatMessage]) -> Strategy {
        classify(old: old, new: new)
    }

    func update(with newMessages: [ChatMessage]) {
        guard let vc = controller else { return }

        let snapshot = Snapshot(vc: vc)
        let strategy = classify(old: snapshot.oldMessages, new: newMessages)

        switch strategy {
        case .initial:
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            let newRows = vc.buildRows(from: newMessages)
            applyInitial(vc: vc, newRows: newRows)

        case .content:
            applyContent(vc: vc, newMessages: newMessages, snapshot: snapshot)

        case .prepend:
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            let newRows = vc.buildRows(from: newMessages)
            applyPrepend(vc: vc, newRows: newRows, snapshot: snapshot)

        case .append:
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            let newRows = vc.buildRows(from: newMessages)
            applyAppend(vc: vc, newRows: newRows, snapshot: snapshot)

        case .structural:
            applyStructuralEntry(vc: vc, newMessages: newMessages, snapshot: snapshot)
        }
    }
}

// MARK: - Snapshot

private extension MessageUpdateHandler {

    struct Snapshot {
        let wasAtBottom: Bool
        let wasEmpty: Bool
        let oldMessages: [ChatMessage]
        let oldRows: [ChatRow]
        let oldLayoutData: [RowLayoutInfo]
        let savedOffset: CGPoint

        init(vc: ChatViewController) {
            wasAtBottom   = vc.isNearBottom()
            wasEmpty      = vc.messages.isEmpty
            oldMessages   = vc.messages
            oldRows       = vc.rows
            oldLayoutData = vc.chatLayout.rowLayoutData
            savedOffset   = vc.collectionView.contentOffset
        }
    }
}

// MARK: - Classification

private extension MessageUpdateHandler {

    /// Single-level O(n) classification by comparing message IDs.
    func classify(old: [ChatMessage], new: [ChatMessage]) -> Strategy {
        // Empty → non-empty = initial
        if old.isEmpty { return new.isEmpty ? .initial : .initial }

        // Non-empty → empty = structural (clear all)
        if new.isEmpty { return .structural }

        // Same count — check if all IDs match in order
        if old.count == new.count {
            var allSame = true
            for i in 0..<old.count where old[i].id != new[i].id {
                allSame = false
                break
            }
            if allSame { return .content }
            // Same count but different IDs → structural
            return .structural
        }

        // New has more items — check prepend or append
        if new.count > old.count {
            let offset = new.count - old.count

            // Check prepend: old IDs are suffix of new IDs
            var isPrepend = true
            for i in 0..<old.count where old[i].id != new[i + offset].id {
                isPrepend = false
                break
            }
            if isPrepend { return .prepend }

            // Check append: old IDs are prefix of new IDs
            var isAppend = true
            for i in 0..<old.count where old[i].id != new[i].id {
                isAppend = false
                break
            }
            if isAppend { return .append }
        }

        // Everything else: fewer items, or mixed insert/delete
        return .structural
    }
}

// MARK: - Initial

private extension MessageUpdateHandler {

    func applyInitial(vc: ChatViewController, newRows: [ChatRow]) {
        vc.isInitialScrollProtected = true
        vc.sizeCache.invalidateAll()
        vc.setRows(newRows)
        vc.applyLayoutData(vc.computeLayoutData())

        vc.collectionView.reloadData()
        vc.collectionView.layoutIfNeeded()

        let cv = vc.collectionView!

        // pendingScrollToBottom takes priority (e.g., returnToLatest + scrollToBottom)
        if vc.pendingScrollToBottom {
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toBottom
        } else if let anchor = vc.pendingScrollAnchor {
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toAnchor(anchor)
        } else {
            vc.pendingInitialScroll = .toBottom
        }

        vc.executePendingInitialScroll()
    }
}

// MARK: - Prepend

private extension MessageUpdateHandler {

    func applyPrepend(vc: ChatViewController, newRows: [ChatRow], snapshot s: Snapshot) {
        guard newRows.count > s.oldRows.count else {
            return
        }

        let oldLayout = vc.chatLayout.rowLayoutData
        var oldTotalH: CGFloat = 0
        for info in oldLayout { oldTotalH += info.totalHeight }

        vc.setRows(newRows)
        let newLayout = vc.computeLayoutData()
        var newTotalH: CGFloat = 0
        for info in newLayout { newTotalH += info.totalHeight }
        let compensating = newTotalH - oldTotalH

        // Apply everything in a single render pass — no intermediate frame
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        vc.applyLayoutData(newLayout)
        let saved = vc.collectionView.contentOffset
        vc.collectionView.reloadData()
        vc.collectionView.contentOffset = CGPoint(x: saved.x, y: saved.y + compensating)
        vc.collectionView.layoutIfNeeded()

        CATransaction.commit()

        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }
}

// MARK: - Append

private extension MessageUpdateHandler {

    func applyAppend(vc: ChatViewController, newRows: [ChatRow], snapshot s: Snapshot) {
        let wantScroll = vc.pendingScrollToBottom || (s.wasAtBottom && !vc.isLoadingNewerActive)
        let wasLoadingNewer = vc.isLoadingNewerActive
        vc.isLoadingNewerActive = false
        if wantScroll { vc.pendingScrollToBottom = false }

        if !wasLoadingNewer && !s.wasAtBottom {
            vc.trackNewUnread(newMessages: vc.messages, oldCount: s.oldMessages.count)
        }

        vc.setRows(newRows)
        vc.applyLayoutData(vc.computeLayoutData())
        vc.collectionView.reloadData()
        vc.collectionView.layoutIfNeeded()

        if wantScroll {
            let maxY = vc.collectionView.contentSize.height - vc.collectionView.bounds.height + vc.collectionView.contentInset.bottom
            if maxY > -vc.collectionView.contentInset.top {
                vc.collectionView.setContentOffset(CGPoint(x: 0, y: maxY), animated: true)
            }
        } else {
            vc.collectionView.contentOffset = s.savedOffset
        }

        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }
}

// MARK: - Content (same IDs, same order — incremental patch)

private extension MessageUpdateHandler {

    func applyContent(vc: ChatViewController, newMessages: [ChatMessage], snapshot s: Snapshot) {
        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }

        let cv = vc.collectionView!

        // Single O(n) pass: find changed messages, invalidate their size cache
        var changedIDs = Set<String>()
        for i in 0..<s.oldMessages.count {
            if s.oldMessages[i] != newMessages[i] {
                changedIDs.insert(newMessages[i].id)
                vc.invalidateSizeCache(forKey: newMessages[i].id)
            }
        }

        guard !changedIDs.isEmpty else {
            // No actual content change
            vc.setMessages(newMessages)
            return
        }

        // Build ID→message map for changed messages
        var newMsgByID: [String: ChatMessage] = Dictionary(minimumCapacity: changedIDs.count)
        for msg in newMessages where changedIDs.contains(msg.id) {
            newMsgByID[msg.id] = msg
        }

        // Patch messageIndex — O(changed)
        for (id, msg) in newMsgByID { vc.messageIndex[id] = msg }
        vc.setMessages(newMessages)

        // Patch rows in-place — O(rows) scan, O(changed) swaps
        var rows = vc.rows
        for (i, row) in rows.enumerated() {
            guard case .message(let msg) = row, let updated = newMsgByID[msg.id] else { continue }
            rows[i] = .message(updated)
        }
        vc.setRows(rows)

        // Patch layout — recompute only changed rows
        var layoutData = s.oldLayoutData
        patchLayoutData(&layoutData, changedIDs: changedIDs, rows: rows, vc: vc)
        vc.applyLayoutData(layoutData)

        // Bottom-edge-stable offset
        let delta = shouldScroll ? 0 : OffsetCalculator.bottomStableDelta(
            oldRows: s.oldRows, oldLayout: s.oldLayoutData,
            newRows: rows, newLayout: layoutData, vc: vc)

        // Reconfigure visible cells in-place
        for cell in cv.visibleCells {
            guard let msgCell = cell as? MessageCell,
                  let ip = cv.indexPath(for: cell),
                  ip.item < rows.count,
                  case .message(let msg) = rows[ip.item],
                  changedIDs.contains(msg.id) else { continue }
            vc.dataSource.reconfigureMessageCellInPlace(msgCell, message: msg, vc: vc)
        }

        if !shouldScroll {
            let newOffset = s.savedOffset.y + delta
            cv.contentOffset = CGPoint(x: s.savedOffset.x, y: newOffset)
        }
        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()

        let preClamp = cv.contentOffset.y
        OffsetCalculator.clamp(cv: cv, savedX: s.savedOffset.x, skip: shouldScroll)

        if shouldScroll {
            // Scroll directly — do NOT call scrollToBottom() which re-sets pendingScrollToBottom
            let maxY = cv.contentSize.height - cv.bounds.height + cv.contentInset.bottom
            if maxY > -cv.contentInset.top {
                cv.setContentOffset(CGPoint(x: 0, y: maxY), animated: true)
            }
        }

        vc.finalizeUpdate(count: vc.rows.count, animated: true)
        vc.flushPendingMessages()
    }
}

// MARK: - Structural (DifferenceKit or full reload)

private extension MessageUpdateHandler {

    func applyStructuralEntry(vc: ChatViewController, newMessages: [ChatMessage], snapshot s: Snapshot) {
        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }

        // Detect deleted message IDs for disintegration animation
        let newIDs = Set(newMessages.map(\.id))
        let deletedIDs = s.oldMessages.filter { !newIDs.contains($0.id) }.map(\.id)

        vc.setMessages(newMessages)
        vc.rebuildMessageIndex()
        let newRows = vc.buildRows(from: newMessages)

        if vc.disintegrationEnabled && !deletedIDs.isEmpty {
            animateDisintegrationAndApply(
                vc: vc, deletedIDs: deletedIDs, newRows: newRows,
                oldRows: s.oldRows, snapshot: s, shouldScroll: shouldScroll
            )
        } else {
            applyStructural(vc: vc, oldRows: s.oldRows, newRows: newRows,
                            snapshot: s, shouldScroll: shouldScroll)
        }
    }

    func applyStructural(vc: ChatViewController, oldRows: [ChatRow],
                         newRows: [ChatRow], snapshot s: Snapshot, shouldScroll: Bool) {
        let changeset = StagedChangeset(source: oldRows, target: newRows)

        // No actual changes — bail out
        guard !changeset.isEmpty else {
            vc.setRows(newRows)
            return
        }

        // Measure how "heavy" the change is
        let totalChanges = changeset.reduce(0) {
            $0 + $1.elementInserted.count + $1.elementDeleted.count + $1.elementMoved.count
        }
        let rowCount = max(oldRows.count, newRows.count)
        let isHeavy = rowCount > 0 && totalChanges > rowCount / 2

        if isHeavy {
            // Heavy change (returnToLatest, navigateToMessage, mass delete) — skip animation
            let anchor = vc.currentScrollAnchor()

            vc.setRows(newRows)
            vc.applyLayoutData(vc.computeLayoutData())
            vc.collectionView.reloadData()
            vc.collectionView.layoutIfNeeded()

            if shouldScroll {
                let maxY = vc.collectionView.contentSize.height - vc.collectionView.bounds.height + vc.collectionView.contentInset.bottom
                if maxY > -vc.collectionView.contentInset.top {
                    vc.collectionView.setContentOffset(CGPoint(x: 0, y: maxY), animated: true)
                }
            } else if !s.wasAtBottom, let anchor {
                vc.restoreScrollAnchor(anchor)
            }
        } else {
            // Light structural (1-2 deletes/inserts) — animated DifferenceKit batch.
            // DifferenceKit handles scroll position automatically during animation —
            // no manual anchor restore needed.
            vc.collectionView.reload(using: changeset) { [weak vc] data in
                guard let vc else { return }
                vc.setRows(data)
                vc.applyLayoutData(vc.computeLayoutData())
            }

            // Verify rows are consistent after DifferenceKit
            if vc.rows != newRows {
                vc.setRows(newRows)
                vc.applyLayoutData(vc.computeLayoutData())
                vc.collectionView.reloadData()
            }
            vc.collectionView.layoutIfNeeded()

            if shouldScroll {
                let maxY = vc.collectionView.contentSize.height - vc.collectionView.bounds.height + vc.collectionView.contentInset.bottom
                if maxY > -vc.collectionView.contentInset.top {
                    vc.collectionView.setContentOffset(CGPoint(x: 0, y: maxY), animated: true)
                }
            }
        }

        reconfigureVisibleAvatars(vc: vc)
        vc.finalizeUpdate(count: newRows.count, animated: !isHeavy)
        vc.flushPendingMessages()
    }

    // MARK: Disintegration + Structural

    private func animateDisintegrationAndApply(
        vc: ChatViewController, deletedIDs: [String], newRows: [ChatRow],
        oldRows: [ChatRow], snapshot s: Snapshot, shouldScroll: Bool
    ) {
        let cv = vc.collectionView!
        var animatedAny = false

        for id in deletedIDs {
            guard let rowIndex = vc.rowIndexCache[id],
                  let cell = cv.cellForItem(at: IndexPath(item: rowIndex, section: 0)) as? MessageCell else {
                continue
            }

            animatedAny = true
            DisintegrationAnimator.disintegrate(
                view: cell.bubbleView,
                in: vc.view,
                config: vc.disintegrationConfig
            ) {
                cell.bubbleView.isHidden = false
            }
        }

        let applyBlock = { [weak self] in
            guard let self, let vc = self.controller else { return }
            self.applyStructural(vc: vc, oldRows: oldRows, newRows: newRows,
                                 snapshot: s, shouldScroll: shouldScroll)
        }

        if animatedAny {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: applyBlock)
        } else {
            applyBlock()
        }
    }
}

// MARK: - Incremental Layout Patch

private extension MessageUpdateHandler {

    /// Recompute layout only for rows whose message ID is in `changedIDs`.
    func patchLayoutData(_ layoutData: inout [RowLayoutInfo],
                         changedIDs: Set<String>,
                         rows: [ChatRow],
                         vc: ChatViewController) {
        guard !changedIDs.isEmpty else { return }
        var width = vc.collectionView.bounds.width
        if width <= 0 { width = UIScreen.main.bounds.width }

        for (i, row) in rows.enumerated() {
            guard case .message(let msg) = row, changedIDs.contains(msg.id) else { continue }
            let h = vc.computeMessageHeight(forId: msg.id, width: width)
            let extraBottom: CGFloat
            switch msg.ownership {
            case .system: extraBottom = vc.layout.systemCellBottomSpacing
            case .pinned: extraBottom = vc.layout.pinnedCellBottomSpacing
            default:      extraBottom = 0
            }
            layoutData[i] = RowLayoutInfo(
                height: h,
                topInset: vc.layout.cellVSpacing / 2,
                bottomInset: vc.layout.cellVSpacing / 2 + extraBottom
            )
        }
    }
}

// MARK: - Offset Calculator

/// Pure math for bottom-edge-stable scroll offset using prefix sums.
enum OffsetCalculator {

    /// Delta to keep anchor's bottom edge on screen. Finds anchor by message ID.
    /// Scans visible cells bottom-to-top, skipping deleted rows.
    static func bottomStableDelta(
        oldRows: [ChatRow], oldLayout: [RowLayoutInfo],
        newRows: [ChatRow], newLayout: [RowLayoutInfo],
        vc: ChatViewController
    ) -> CGFloat {
        var newIndex: [String: Int] = Dictionary(minimumCapacity: newRows.count)
        for (i, row) in newRows.enumerated() {
            if let id = row.messageId { newIndex[id] = i }
        }

        let oldSums = prefixSums(oldLayout)
        let newSums = prefixSums(newLayout)

        let paths = vc.collectionView.indexPathsForVisibleItems.sorted { $0.item > $1.item }
        for ip in paths {
            let idx = ip.item
            guard idx < oldRows.count, idx < oldLayout.count,
                  let id = oldRows[idx].messageId,
                  let newIdx = newIndex[id],
                  newIdx < newLayout.count else { continue }

            return cellBottom(at: newIdx, sums: newSums, layout: newLayout)
                 - cellBottom(at: idx, sums: oldSums, layout: oldLayout)
        }
        return 0
    }

    /// Clamp offset to valid scroll range after layout.
    static func clamp(cv: UICollectionView, savedX: CGFloat, skip: Bool) {
        guard !skip else { return }
        let maxY = cv.contentSize.height - cv.bounds.height + cv.contentInset.bottom
        let minY = -cv.adjustedContentInset.top
        let clamped = min(max(cv.contentOffset.y, minY), max(maxY, minY))
        if abs(clamped - cv.contentOffset.y) > 0.5 {
            cv.contentOffset = CGPoint(x: savedX, y: clamped)
        }
    }

    private static func cellBottom(at idx: Int, sums: [CGFloat], layout: [RowLayoutInfo]) -> CGFloat {
        sums[idx] + layout[idx].topInset + layout[idx].height
    }

    private static func prefixSums(_ data: [RowLayoutInfo]) -> [CGFloat] {
        var sums = [CGFloat]()
        sums.reserveCapacity(data.count)
        var y: CGFloat = 0
        for info in data {
            sums.append(y)
            y += info.totalHeight
        }
        return sums
    }
}

// MARK: - Avatar Reconfiguration

private extension MessageUpdateHandler {

    func reconfigureVisibleAvatars(vc: ChatViewController) {
        let cv = vc.collectionView!
        let groups = vc.chatLayout.avatarGroups
        let kind = AvatarSupplementaryView.kind
        for i in 0..<groups.count {
            let ip = IndexPath(item: i, section: 0)
            guard let avatar = cv.supplementaryView(forElementKind: kind, at: ip)
                    as? AvatarSupplementaryView else { continue }
            let g = groups[i]
            avatar.configure(
                view: vc.contentFactory.avatarView(
                    name: g.senderName, url: g.senderAvatarUrl,
                    size: vc.layout.avatarSize, theme: vc.theme, layout: vc.layout),
                size: vc.layout.avatarSize)
        }
    }
}
