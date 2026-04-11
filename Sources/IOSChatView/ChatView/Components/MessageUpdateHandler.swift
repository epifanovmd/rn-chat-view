import UIKit
import DifferenceKit

/// Routes message updates to the optimal strategy and keeps scroll stable.
///
/// | Strategy    | Trigger                  | Method                                |
/// |-------------|--------------------------|---------------------------------------|
/// | Initial     | First batch (was empty)  | `reloadData` + scroll to bottom       |
/// | Prepend     | Older messages loaded    | `reloadData` + offset compensation    |
/// | Append      | New messages at bottom   | `reloadData` + auto-scroll            |
/// | Content     | Edit / reactions / polls  | Incremental patch + offset fix        |
/// | Replace     | Delete+insert same pos   | Targeted `reloadItems` + offset fix   |
/// | Structural  | Row count changed        | DifferenceKit animated batch          |
///
/// **Bottom-edge-stable**: content and replace updates pin the anchor
/// message's bottom edge to its screen position — height changes expand upward.
final class MessageUpdateHandler {

    private weak var controller: ChatViewController?

    init(controller: ChatViewController) {
        self.controller = controller
    }

    // MARK: - Public

    func update(with newMessages: [ChatMessage]) {
        guard let vc = controller else { return }

        let snapshot = Snapshot(vc: vc)
        let kind = classify(snapshot: snapshot, newMessages: newMessages)

        // Content updates use incremental patching — O(changed) instead of O(n).
        if kind == .content {
            applyContent(vc: vc, newMessages: newMessages, snapshot: snapshot)
            return
        }

        vc.setMessages(newMessages)
        vc.rebuildMessageIndex()
        let newRows = vc.buildRows(from: newMessages)

        switch kind {
        case .initial:  applyInitial(vc: vc, newRows: newRows)
        case .prepend:  applyPrepend(vc: vc, newRows: newRows)
        case .append:   applyAppend(vc: vc, newRows: newRows, snapshot: snapshot)
        case .content:  break
        }
    }
}

// MARK: - Update Classification

private extension MessageUpdateHandler {

    struct Snapshot {
        let wasAtBottom: Bool
        let wasEmpty: Bool
        let oldFirstId: String?
        let oldLastId: String?
        let oldCount: Int
        let oldMessages: [ChatMessage]
        let oldRows: [ChatRow]
        let oldLayoutData: [RowLayoutInfo]
        let savedOffset: CGPoint

        init(vc: ChatViewController) {
            wasAtBottom   = vc.isNearBottom()
            wasEmpty      = vc.messages.isEmpty
            oldFirstId    = vc.messages.first?.id
            oldLastId     = vc.messages.last?.id
            oldCount      = vc.messages.count
            oldMessages   = vc.messages
            oldRows       = vc.rows
            oldLayoutData = vc.chatLayout.rowLayoutData
            savedOffset   = vc.collectionView.contentOffset
        }
    }

    enum UpdateKind { case initial, prepend, append, content }

    func classify(snapshot s: Snapshot, newMessages: [ChatMessage]) -> UpdateKind {
        let grew = newMessages.count > s.oldCount

        if s.wasEmpty && !newMessages.isEmpty { return .initial }

        if !s.wasEmpty && grew
            && s.oldFirstId != nil && s.oldFirstId != newMessages.first?.id
            && s.oldLastId == newMessages.last?.id { return .prepend }

        if !s.wasEmpty && grew
            && s.oldLastId != nil && s.oldLastId != newMessages.last?.id { return .append }

        return .content
    }
}

// MARK: - Initial

private extension MessageUpdateHandler {

    func applyInitial(vc: ChatViewController, newRows: [ChatRow]) {
        vc.sizeCache.invalidateAll()
        vc.setRows(newRows)
        vc.applyLayoutData(vc.computeLayoutData())

        // Pre-set offset to bottom BEFORE reloadData so the first rendered
        // frame already shows the bottom — no flash of top content.
        let layoutData = vc.chatLayout.rowLayoutData
        var totalH: CGFloat = 0
        for info in layoutData { totalH += info.totalHeight }
        let cv = vc.collectionView!
        let maxY = totalH - cv.bounds.height + cv.contentInset.bottom
        if maxY > -cv.adjustedContentInset.top {
            cv.contentOffset = CGPoint(x: 0, y: maxY)
        }

        cv.reloadData()
        cv.layoutIfNeeded()

        if let scrollId = vc.pendingScrollMessageId {
            let position = vc.pendingScrollMessagePosition ?? "center"
            let highlight = position == "center"
            vc.scrollToMessage(id: scrollId, position: position, animated: false, highlight: highlight)
            vc.pendingScrollMessageId = nil
            vc.pendingScrollMessagePosition = nil
        }

        vc.isInitialScrollProtected = false
        vc.finalizeUpdate(count: newRows.count, animated: false)
    }
}

// MARK: - Prepend

private extension MessageUpdateHandler {

    func applyPrepend(vc: ChatViewController, newRows: [ChatRow]) {
        let insertedCount = newRows.count - vc.rows.count
        guard insertedCount > 0 else { return }

        let prependedRows = Array(newRows[0..<insertedCount])
        vc.setRows(newRows)

        let prependedLayout = vc.computeLayoutInfo(for: prependedRows)
        var compensating: CGFloat = 0
        for info in prependedLayout { compensating += info.totalHeight }

        vc.rebuildCachesIncremental(insertedCount: insertedCount)
        vc.prependLayoutData(prependedLayout, insertedRowCount: insertedCount)

        let saved = vc.collectionView.contentOffset
        vc.collectionView.reloadData()
        vc.collectionView.layoutIfNeeded()
        vc.collectionView.contentOffset = CGPoint(x: saved.x, y: saved.y + compensating)

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
            vc.trackNewUnread(newMessages: vc.messages, oldCount: s.oldCount)
        }

        vc.setRows(newRows)
        vc.applyLayoutData(vc.computeLayoutData())
        vc.collectionView.reloadData()
        vc.collectionView.layoutIfNeeded()

        if wantScroll {
            vc.scrollToBottom(animated: true)
        } else {
            vc.collectionView.contentOffset = s.savedOffset
        }

        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }
}

// MARK: - Content / Replace / Structural

private extension MessageUpdateHandler {

    /// Result of analyzing old vs new messages in a single O(n) pass.
    struct ContentAnalysis {
        let kind: ContentKind
        let changedIDs: Set<String>
        let replacedMsgIndices: [Int]
    }

    enum ContentKind { case noChange, pureContent, positionalReplace, structural }

    /// Single-pass analysis over messages (not rows) — classifies update type,
    /// collects changed IDs, and invalidates size cache in one O(n) sweep.
    func analyzeContent(oldMessages: [ChatMessage], newMessages: [ChatMessage],
                        vc: ChatViewController) -> ContentAnalysis {
        guard oldMessages.count == newMessages.count else {
            return ContentAnalysis(kind: .structural, changedIDs: [], replacedMsgIndices: [])
        }

        var changedIDs = Set<String>()
        var replacedIndices: [Int] = []

        for i in 0..<oldMessages.count {
            let old = oldMessages[i], new = newMessages[i]
            if old.id == new.id {
                if old != new {
                    changedIDs.insert(new.id)
                    vc.invalidateSizeCache(forKey: new.id)
                }
            } else {
                replacedIndices.append(i)
                vc.invalidateSizeCache(forKey: old.id)
                vc.invalidateSizeCache(forKey: new.id)
            }
        }

        if !replacedIndices.isEmpty {
            return ContentAnalysis(kind: .positionalReplace, changedIDs: changedIDs,
                                  replacedMsgIndices: replacedIndices)
        }
        if !changedIDs.isEmpty {
            return ContentAnalysis(kind: .pureContent, changedIDs: changedIDs,
                                  replacedMsgIndices: [])
        }
        return ContentAnalysis(kind: .noChange, changedIDs: [], replacedMsgIndices: [])
    }

    func applyContent(vc: ChatViewController, newMessages: [ChatMessage], snapshot s: Snapshot) {
        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }

        let analysis = analyzeContent(oldMessages: s.oldMessages, newMessages: newMessages, vc: vc)

        switch analysis.kind {
        case .noChange:
            vc.setMessages(newMessages)

        case .pureContent:
            applyPureContent(vc: vc, newMessages: newMessages, snapshot: s,
                             shouldScroll: shouldScroll, analysis: analysis)

        case .positionalReplace:
            applyReplace(vc: vc, newMessages: newMessages, snapshot: s,
                         shouldScroll: shouldScroll, analysis: analysis)

        case .structural:
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            let newRows = vc.buildRows(from: newMessages)
            applyStructural(vc: vc, oldRows: s.oldRows, newRows: newRows,
                            snapshot: s, shouldScroll: shouldScroll)
        }

        if shouldScroll { vc.scrollToBottom(animated: true) }

        vc.finalizeUpdate(count: vc.rows.count, animated: true)
        vc.flushPendingMessages()
    }

    // MARK: Pure Content �� incremental patch

    private func applyPureContent(vc: ChatViewController, newMessages: [ChatMessage],
                                  snapshot s: Snapshot, shouldScroll: Bool,
                                  analysis: ContentAnalysis) {
        // Build ID→message map for changed messages only
        var newMsgByID: [String: ChatMessage] = Dictionary(minimumCapacity: analysis.changedIDs.count)
        for msg in newMessages where analysis.changedIDs.contains(msg.id) {
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
        patchLayoutData(&layoutData, changedIDs: analysis.changedIDs, rows: rows, vc: vc)
        vc.applyLayoutData(layoutData)

        // Bottom-edge-stable offset
        let delta = shouldScroll ? 0 : OffsetCalculator.bottomStableDelta(
            oldRows: s.oldRows, oldLayout: s.oldLayoutData,
            newRows: rows, newLayout: layoutData, vc: vc)

        let cv = vc.collectionView!

        // Reconfigure visible cells in-place
        for cell in cv.visibleCells {
            guard let msgCell = cell as? MessageCell,
                  let ip = cv.indexPath(for: cell),
                  ip.item < rows.count,
                  case .message(let msg) = rows[ip.item],
                  analysis.changedIDs.contains(msg.id) else { continue }
            vc.dataSource.reconfigureMessageCellInPlace(msgCell, message: msg, vc: vc)
        }

        if !shouldScroll {
            cv.contentOffset = CGPoint(x: s.savedOffset.x, y: s.savedOffset.y + delta)
        }
        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()

        OffsetCalculator.clamp(cv: cv, savedX: s.savedOffset.x, skip: shouldScroll)
    }

    // MARK: Positional Replace — incremental patch

    private func applyReplace(vc: ChatViewController, newMessages: [ChatMessage],
                              snapshot s: Snapshot, shouldScroll: Bool,
                              analysis: ContentAnalysis) {
        // Patch messageIndex: remove old IDs, add new IDs
        for idx in analysis.replacedMsgIndices {
            let oldId = s.oldMessages[idx].id
            let newMsg = newMessages[idx]
            vc.messageIndex.removeValue(forKey: oldId)
            vc.messageIndex[newMsg.id] = newMsg
        }
        for id in analysis.changedIDs {
            if let msg = newMessages.first(where: { $0.id == id }) {
                vc.messageIndex[id] = msg
            }
        }
        vc.setMessages(newMessages)

        // Patch rows at replaced positions
        var rows = vc.rows
        for idx in analysis.replacedMsgIndices {
            let newMsg = newMessages[idx]
            if let rowIdx = vc.rowIndexCache[s.oldMessages[idx].id] {
                rows[rowIdx] = .message(newMsg)
                vc.rowIndexCache.removeValue(forKey: s.oldMessages[idx].id)
                vc.rowIndexCache[newMsg.id] = rowIdx
            }
        }
        vc.setRows(rows)

        // Patch layout for all affected IDs
        var layoutData = s.oldLayoutData
        let allChangedIDs = analysis.changedIDs.union(
            Set(analysis.replacedMsgIndices.map { newMessages[$0].id }))
        patchLayoutData(&layoutData, changedIDs: allChangedIDs, rows: rows, vc: vc)
        vc.applyLayoutData(layoutData)

        // Bottom-edge-stable offset (by position — IDs changed)
        let delta = shouldScroll ? 0 : OffsetCalculator.bottomStableDeltaByPosition(
            oldLayout: s.oldLayoutData, newLayout: layoutData, vc: vc)

        // Map replaced message indices to row-level index paths
        var replacedIndexPaths: [IndexPath] = []
        for idx in analysis.replacedMsgIndices {
            if let rowIdx = vc.rowIndexCache[newMessages[idx].id] {
                replacedIndexPaths.append(IndexPath(item: rowIdx, section: 0))
            }
        }

        let cv = vc.collectionView!

        if !shouldScroll {
            cv.contentOffset = CGPoint(x: s.savedOffset.x, y: s.savedOffset.y + delta)
        }

        if !replacedIndexPaths.isEmpty {
            UIView.performWithoutAnimation {
                cv.reloadItems(at: replacedIndexPaths)
            }
        }
        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()

        OffsetCalculator.clamp(cv: cv, savedX: s.savedOffset.x, skip: shouldScroll)
    }

    // MARK: Structural — full rebuild (fallback)

    private func applyStructural(vc: ChatViewController, oldRows: [ChatRow],
                                 newRows: [ChatRow], snapshot s: Snapshot, shouldScroll: Bool) {
        let changeset = StagedChangeset(source: oldRows, target: newRows)
        guard !changeset.isEmpty else {
            vc.setRows(newRows)
            return
        }

        vc.collectionView.reload(using: changeset) { [weak vc] data in
            guard let vc else { return }
            vc.setRows(data)
            vc.applyLayoutData(vc.computeLayoutData())
        }

        if vc.rows != newRows {
            vc.setRows(newRows)
            vc.applyLayoutData(vc.computeLayoutData())
            vc.collectionView.reloadData()
        }

        vc.collectionView.layoutIfNeeded()

        if !shouldScroll && !s.wasAtBottom {
            vc.collectionView.contentOffset = s.savedOffset
        }

        reconfigureVisibleAvatars(vc: vc)
    }

    // MARK: Incremental Layout Patch

    /// Recompute layout only for rows whose message ID is in `changedIDs`.
    private func patchLayoutData(_ layoutData: inout [RowLayoutInfo],
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

    /// Delta to keep anchor's bottom edge on screen. Finds anchor by row position.
    static func bottomStableDeltaByPosition(
        oldLayout: [RowLayoutInfo], newLayout: [RowLayoutInfo],
        vc: ChatViewController
    ) -> CGFloat {
        let oldSums = prefixSums(oldLayout)
        let newSums = prefixSums(newLayout)

        let paths = vc.collectionView.indexPathsForVisibleItems.sorted { $0.item > $1.item }
        for ip in paths {
            let idx = ip.item
            guard idx < oldLayout.count, idx < newLayout.count else { continue }

            return cellBottom(at: idx, sums: newSums, layout: newLayout)
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
