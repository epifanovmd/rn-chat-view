import UIKit
import DifferenceKit

/// Unified message update system.
///
/// Instead of choosing one strategy per batch, analyzes ALL changes granularly
/// and applies them via `performBatchUpdates` — inserts, deletes, and reloads
/// in a single animated transaction.
///
/// Special paths:
/// - **Initial**: empty → data, uses `reloadData` + pending scroll
/// - **Prepend-only**: older messages loaded, uses offset compensation
///
/// All other cases use the unified diff path.
final class MessageUpdateHandler {

    private weak var controller: ChatViewController?

    init(controller: ChatViewController) {
        self.controller = controller
    }

    // MARK: - Public

    func update(with newMessages: [ChatMessage]) {
        guard let vc = controller else { return }

        let snapshot = Snapshot(vc: vc)

        // Initial: empty → data
        if snapshot.oldMessages.isEmpty {
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            let newRows = vc.buildRows(from: newMessages)
            applyInitial(vc: vc, newRows: newRows)
            return
        }

        // Empty result (clear all)
        if newMessages.isEmpty {
            vc.setMessages([])
            vc.rebuildMessageIndex()
            vc.setRows([])
            vc.applyLayoutData([])
            vc.sizeCache.invalidateAll()
            vc.collectionView.reloadData()
            vc.finalizeUpdate(count: 0, animated: false)
            return
        }

        // Compute diff (recognizes pending→real via localId)
        let diff = MessageDiff.compute(old: snapshot.oldMessages, new: newMessages)
        let pendingMapping = MessageDiff.buildPendingMapping(old: snapshot.oldMessages, new: newMessages)
        let strategy = MessageDiff.classify(old: snapshot.oldMessages, new: newMessages, diff: diff)

        print("[UpdateHandler] diff: inserted=\(diff.insertedIDs.count) deleted=\(diff.deletedIDs.count) updated=\(diff.updatedIDs.count) pendingMapped=\(pendingMapping.oldToNew.count) strategy=\(strategy)")

        // Invalidate sizeCache for changed messages
        for id in diff.updatedIDs {
            vc.invalidateSizeCache(forKey: id)
        }
        // Also invalidate old pending IDs that were mapped to real IDs
        for oldId in pendingMapping.oldToNew.keys {
            vc.invalidateSizeCache(forKey: oldId)
        }

        switch strategy {
        case .initial, .clear:
            break // already handled above

        case .prependOnly:
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            applyPrepend(vc: vc, newRows: vc.buildRows(from: newMessages), snapshot: snapshot)

        case .appendOnly:
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            applyAppend(vc: vc, newRows: vc.buildRows(from: newMessages), snapshot: snapshot)

        case .contentOnly:
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            let wantScroll = vc.pendingScrollToBottom
            if wantScroll { vc.pendingScrollToBottom = false }
            applyContentOnly(vc: vc, newRows: vc.buildRows(from: newMessages), diff: diff, pendingMapping: pendingMapping, snapshot: snapshot, wantScrollToBottom: wantScroll)

        case .structural:
            applyUnified(vc: vc, newMessages: newMessages, diff: diff, snapshot: snapshot)
        }
    }

    /// Peek at whether update would be structural (for deferral during scroll).
    func peekClassify(old: [ChatMessage], new: [ChatMessage]) -> Bool {
        if old.isEmpty || new.isEmpty { return false }
        return MessageDiff.compute(old: old, new: new).hasStructuralChanges
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

// MARK: - Initial

private extension MessageUpdateHandler {

    func applyInitial(vc: ChatViewController, newRows: [ChatRow]) {
        print("[Initial] rows=\(newRows.count) pendingScrollToBottom=\(vc.pendingScrollToBottom) pendingAnchor=\(vc.pendingScrollAnchor?.messageId.prefix(8) ?? "nil")")

        vc.isInitialScrollProtected = true
        vc.sizeCache.invalidateAll()
        vc.setRows(newRows)
        vc.applyLayoutData(vc.computeLayoutData())

        vc.collectionView.reloadData()
        vc.collectionView.layoutIfNeeded()

        let cv = vc.collectionView!
        print("[Initial] after layout: offset=\(f(cv.contentOffset.y)) contentH=\(f(cv.contentSize.height)) frameH=\(f(cv.bounds.height))")

        if vc.pendingScrollToBottom {
            print("[Initial] → .toBottom (pendingScrollToBottom)")
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toBottom
        } else if let anchor = vc.pendingScrollAnchor {
            print("[Initial] → .toAnchor(\(anchor.messageId.prefix(8)))")
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toAnchor(anchor)
        } else {
            print("[Initial] → .toBottom (default)")
            vc.pendingInitialScroll = .toBottom
        }

        vc.executePendingInitialScroll()
    }
}

// MARK: - Prepend (offset-compensated, for older messages only)

private extension MessageUpdateHandler {

    func applyPrepend(vc: ChatViewController, newRows: [ChatRow], snapshot s: Snapshot) {
        guard newRows.count > s.oldRows.count else {
            print("[Prepend] ⚠️ SKIP: newRows(\(newRows.count)) <= oldRows(\(s.oldRows.count))")
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

        print("[Prepend] oldRows=\(s.oldRows.count) newRows=\(newRows.count) compensating=\(f(compensating))")

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        vc.applyLayoutData(newLayout)
        let saved = vc.collectionView.contentOffset
        vc.collectionView.reloadData()
        vc.collectionView.contentOffset = CGPoint(x: saved.x, y: saved.y + compensating)
        vc.collectionView.layoutIfNeeded()

        CATransaction.commit()

        print("[Prepend] DONE offset=\(f(vc.collectionView.contentOffset.y))")
        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }
}

// MARK: - Append (newer messages at bottom, preserve scroll position)

private extension MessageUpdateHandler {

    func applyAppend(vc: ChatViewController, newRows: [ChatRow], snapshot s: Snapshot) {
        let insertedCount = newRows.count - s.oldRows.count
        // Auto-scroll only for small appends (1-2 socket messages) at bottom.
        // Batch appends (pagination, loadNewer) preserve scroll position.
        let wantScroll = vc.pendingScrollToBottom || (s.wasAtBottom && insertedCount <= 2 && !vc.isLoadingNewerActive)
        if wantScroll { vc.pendingScrollToBottom = false }

        print("[Append] oldRows=\(s.oldRows.count) newRows=\(newRows.count) wantScroll=\(wantScroll) wasAtBottom=\(s.wasAtBottom) loadingNewer=\(vc.isLoadingNewerActive)")

        if !s.wasAtBottom && !wantScroll {
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
            print("[Append] → scrollToBottom maxY=\(f(maxY))")
        } else {
            // Preserve scroll position — user stays where they were
            vc.collectionView.contentOffset = s.savedOffset
            print("[Append] → preserved offset=\(f(s.savedOffset.y))")
        }

        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }
}

// MARK: - Unified diff (handles any combination of insert/delete/update)

private extension MessageUpdateHandler {

    func applyUnified(vc: ChatViewController, newMessages: [ChatMessage], diff: MessageDiff.Result, snapshot s: Snapshot) {
        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }

        // Auto-scroll to bottom only if:
        // 1. Explicit request (pendingScrollToBottom) — e.g. send message, returnToLatest
        // 2. Was at bottom + NOT during pagination (stay at bottom regardless of insert/delete mix)
        let wantScrollToBottom = shouldScroll
            || (s.wasAtBottom && !vc.isLoadingNewerActive)

        print("[Unified] wantScroll=\(wantScrollToBottom) shouldScroll=\(shouldScroll) wasAtBottom=\(s.wasAtBottom) loadingNewer=\(vc.isLoadingNewerActive)")

        // Update data model
        vc.setMessages(newMessages)
        vc.rebuildMessageIndex()
        let newRows = vc.buildRows(from: newMessages)

        // Full replace — skip disintegration, crossfade handles the transition
        let isFullReplace = diff.deletedIDs.count + diff.insertedIDs.count > max(s.oldRows.count, newRows.count)

        // Disintegration only for partial deletes (individual messages), not full replace
        if vc.disintegrationEnabled && !diff.deletedIDs.isEmpty && !isFullReplace {
            animateDisintegrationThen(vc: vc, deletedIDs: diff.deletedIDs) { [weak self] in
                self?.applyDiff(vc: vc, newRows: newRows, diff: diff, snapshot: s, wantScrollToBottom: wantScrollToBottom)
            }
        } else {
            applyDiff(vc: vc, newRows: newRows, diff: diff, snapshot: s, wantScrollToBottom: wantScrollToBottom)
        }
    }

    func applyDiff(vc: ChatViewController, newRows: [ChatRow], diff: MessageDiff.Result,
                   snapshot s: Snapshot, wantScrollToBottom: Bool) {
        let cv = vc.collectionView!
        let oldRows = s.oldRows

        // Build DifferenceKit changeset on rows (includes date separators)
        let changeset = StagedChangeset(source: oldRows, target: newRows)

        // Count STRUCTURAL changes only (insert/delete/move) — NOT content updates.
        // DifferenceKit marks content-changed rows as "updates" but those should use
        // reconfigureMessageCellInPlace (preserves animations), not reload.
        let structuralChanges = changeset.reduce(0) {
            $0 + $1.elementInserted.count + $1.elementDeleted.count + $1.elementMoved.count
        }

        if structuralChanges == 0 {
            // Only content updates (e.g., poll vote, status change) — no insert/delete/move
            print("[Unified] content-only (DK updates only, no structural changes)")
            applyContentOnly(vc: vc, newRows: newRows, diff: diff, snapshot: s, wantScrollToBottom: wantScrollToBottom)
            return
        }

        // Full replace: most rows changed — crossfade instead of staged DK animation
        let isFullReplace = structuralChanges > max(oldRows.count, newRows.count)

        print("[Unified] structural=\(structuralChanges) fullReplace=\(isFullReplace) wantScroll=\(wantScrollToBottom) wasAtBottom=\(s.wasAtBottom)")

        // Capture anchor BEFORE applying changes — needed for stable scroll
        let anchor = wantScrollToBottom ? nil : vc.currentScrollAnchor()

        if isFullReplace {
            vc.setRows(newRows)
            vc.applyLayoutData(vc.computeLayoutData())
            UIView.transition(with: cv, duration: 0.25, options: .transitionCrossDissolve) {
                cv.reloadData()
                cv.layoutIfNeeded()
            }
            print("[Unified] → crossfade reload")
        } else {
            cv.reload(using: changeset) { [weak vc] data in
                guard let vc else { return }
                vc.setRows(data)
                vc.applyLayoutData(vc.computeLayoutData())
            }

            // Verify consistency
            if vc.rows != newRows {
                print("[Unified] ⚠️ rows inconsistent after DifferenceKit — full reload")
                vc.setRows(newRows)
                vc.applyLayoutData(vc.computeLayoutData())
                cv.reloadData()
            }

            cv.layoutIfNeeded()
        }

        if wantScrollToBottom {
            scrollToBottom(cv: cv)
            print("[Unified] → scrollToBottom")
        } else if let anchor {
            vc.restoreScrollAnchor(anchor)
            print("[Unified] → restored anchor \(anchor.messageId.prefix(8))")
        }

        // Reconfigure updated cells in-place (preserves animations like poll bars).
        // invalidateLayout + layoutIfNeeded updates cell FRAMES without destroying cells.
        if !diff.updatedIDs.isEmpty {
            for id in diff.updatedIDs {
                guard let idx = newRows.firstIndex(where: { $0.messageId == id }) else { continue }
                let ip = IndexPath(item: idx, section: 0)
                if let cell = cv.cellForItem(at: ip) as? MessageCell,
                   case .message(let msg) = newRows[idx] {
                    vc.dataSource.reconfigureMessageCellInPlace(cell, message: msg, vc: vc)
                }
            }
            cv.collectionViewLayout.invalidateLayout()
            cv.layoutIfNeeded()
            print("[Unified] reconfigured \(diff.updatedIDs.count) updated cells in-place")
        }

        if !s.wasAtBottom && !wantScrollToBottom {
            vc.trackNewUnread(newMessages: vc.messages, oldCount: s.oldMessages.count)
        }

        vc.finalizeUpdate(count: newRows.count, animated: true)
        vc.flushPendingMessages()
    }

    /// Content-only: same rows, just message fields changed. No structural changes.
    func applyContentOnly(vc: ChatViewController, newRows: [ChatRow], diff: MessageDiff.Result,
                          pendingMapping: MessageDiff.PendingMapping = .empty,
                          snapshot s: Snapshot, wantScrollToBottom: Bool) {
        let cv = vc.collectionView!

        // Patch rows in place
        var rows = vc.rows
        var newMsgByID: [String: ChatMessage] = [:]
        for msg in vc.messages where diff.updatedIDs.contains(msg.id) {
            newMsgByID[msg.id] = msg
        }
        // Also map old pending IDs to new real messages via localId mapping
        var pendingOldToNewMsg: [String: ChatMessage] = [:]
        for (oldId, newId) in pendingMapping.oldToNew {
            if let msg = newMsgByID[newId] {
                pendingOldToNewMsg[oldId] = msg
            }
        }
        for (i, row) in rows.enumerated() {
            guard case .message(let msg) = row else { continue }
            if let updated = newMsgByID[msg.id] {
                rows[i] = .message(updated)
            } else if let updated = pendingOldToNewMsg[msg.id] {
                // pending→real: replace old pending message with new real message
                rows[i] = .message(updated)
            }
        }
        vc.setRows(rows)
        // Rebuild caches since IDs may have changed (pending→real)
        if !pendingMapping.isEmpty {
            vc.rebuildCachesFromRows()
        }

        // Recompute layout for changed rows
        var layoutData = s.oldLayoutData
        var width = cv.bounds.width
        if width <= 0 { width = UIScreen.main.bounds.width }

        guard layoutData.count == rows.count else {
            print("[ContentOnly] ⚠️ layoutData.count(\(layoutData.count)) != rows.count(\(rows.count)) → full reload")
            vc.applyLayoutData(vc.computeLayoutData())
            cv.reloadData()
            cv.layoutIfNeeded()
            vc.finalizeUpdate(count: rows.count, animated: false)
            vc.flushPendingMessages()
            return
        }

        for (i, row) in rows.enumerated() {
            guard case .message(let msg) = row, diff.updatedIDs.contains(msg.id) else { continue }
            let oldH = layoutData[i].height
            let newH = vc.computeMessageHeight(forId: msg.id, width: width)
            let extraBottom: CGFloat
            switch msg.ownership {
            case .system: extraBottom = vc.layout.systemCellBottomSpacing
            case .pinned: extraBottom = vc.layout.pinnedCellBottomSpacing
            default:      extraBottom = 0
            }
            layoutData[i] = RowLayoutInfo(
                height: newH,
                topInset: vc.layout.cellVSpacing / 2,
                bottomInset: vc.layout.cellVSpacing / 2 + extraBottom
            )
            if abs(oldH - newH) > 0.5 {
                print("[ContentOnly] height: \(msg.id.prefix(8)) \(f(oldH)) → \(f(newH))")
            }
        }
        vc.applyLayoutData(layoutData)

        // Bottom-edge-stable offset
        let delta = wantScrollToBottom ? 0 : OffsetCalculator.bottomStableDelta(
            oldRows: s.oldRows, oldLayout: s.oldLayoutData,
            newRows: rows, newLayout: layoutData, vc: vc)

        // Collect changed index paths
        let changedPaths = diff.updatedIDs.compactMap { id -> IndexPath? in
            guard let idx = rows.firstIndex(where: { $0.messageId == id }) else { return nil }
            return IndexPath(item: idx, section: 0)
        }

        print("[ContentOnly] updated=\(changedPaths.count) delta=\(f(delta)) wantScroll=\(wantScrollToBottom)")

        if !wantScrollToBottom {
            cv.contentOffset = CGPoint(x: s.savedOffset.x, y: s.savedOffset.y + delta)
        }

        // Reconfigure visible cells in-place — preserves running animations (poll bars, etc).
        // invalidateLayout + layoutIfNeeded updates cell FRAMES without destroying cells.
        for ip in changedPaths {
            let idx = ip.item
            guard idx < rows.count, case .message(let msg) = rows[idx] else { continue }
            if let cell = cv.cellForItem(at: ip) as? MessageCell {
                vc.dataSource.reconfigureMessageCellInPlace(cell, message: msg, vc: vc)
            }
        }
        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()

        OffsetCalculator.clamp(cv: cv, savedX: s.savedOffset.x, skip: wantScrollToBottom)

        if wantScrollToBottom {
            scrollToBottom(cv: cv)
        }

        vc.finalizeUpdate(count: rows.count, animated: true)
        vc.flushPendingMessages()
    }
}

// MARK: - Disintegration

private extension MessageUpdateHandler {

    func animateDisintegrationThen(vc: ChatViewController, deletedIDs: Set<String>, then: @escaping () -> Void) {
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

        if animatedAny {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: then)
        } else {
            then()
        }
    }
}

// MARK: - Scroll Helpers

private extension MessageUpdateHandler {

    func scrollToBottom(cv: UICollectionView) {
        let maxY = cv.contentSize.height - cv.bounds.height + cv.contentInset.bottom
        if maxY > -cv.contentInset.top {
            cv.setContentOffset(CGPoint(x: 0, y: maxY), animated: true)
        }
    }
}

// MARK: - Offset Calculator

enum OffsetCalculator {

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

// MARK: - Formatting

private func f(_ v: CGFloat) -> String { String(format: "%.1f", v) }
