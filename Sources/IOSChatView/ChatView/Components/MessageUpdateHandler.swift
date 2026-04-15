import UIKit
import DifferenceKit

// MARK: - Логирование

private func log(_ items: Any...) {
    #if DEBUG
    let msg = items.map { "\($0)" }.joined(separator: " ")
    print(msg)
    #endif
}

private func f(_ v: CGFloat) -> String { String(format: "%.1f", v) }

// MARK: - Роутер обновлений

/// Единая точка входа для обновления списка сообщений.
///
/// Быстрые пути (без DifferenceKit):
/// - Initial, Clear, Prepend, Append
///
/// DK changeset — единственный diff-движок:
/// - ContentOnly (structural=0): инкрементальный патч + bottom-stable offset
/// - Structural (structural>0): DK batch + anchor restore
final class MessageUpdateHandler {

    private weak var controller: ChatViewController?

    init(controller: ChatViewController) {
        self.controller = controller
    }

    // MARK: - Public

    func update(with newMessages: [ChatMessage]) {
        guard let vc = controller else { return }

        let snap = Snapshot(vc: vc)

        log("━━━ [Update] \(snap.oldMessages.count) → \(newMessages.count), wasAtBottom=\(snap.wasAtBottom), offset=\(f(snap.savedOffset.y)), contentH=\(f(vc.collectionView.contentSize.height)) ━━━")

        // ── Быстрые пути ──

        if snap.oldMessages.isEmpty {
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            applyInitial(vc: vc, newRows: vc.buildRows(from: newMessages))
            return
        }

        if newMessages.isEmpty {
            applyClear(vc: vc)
            return
        }

        if MessageDiff.isPrependOnly(old: snap.oldMessages, new: newMessages) {
            invalidateChangedMessages(vc: vc, oldMessages: snap.oldMessages, newMessages: newMessages)
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            let newRows = vc.buildRows(from: newMessages)
            log("  Стратегия: PREPEND (+\(newMessages.count - snap.oldMessages.count))")
            applyPrepend(vc: vc, newRows: newRows, snap: snap)
            return
        }

        if MessageDiff.isAppendOnly(old: snap.oldMessages, new: newMessages) {
            invalidateChangedMessages(vc: vc, oldMessages: snap.oldMessages, newMessages: newMessages)
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            let newRows = vc.buildRows(from: newMessages)
            log("  Стратегия: APPEND (+\(newMessages.count - snap.oldMessages.count))")
            applyAppend(vc: vc, newRows: newRows, snap: snap)
            return
        }

        // ── DK changeset ──

        let pendingMapping = MessageDiff.buildPendingMapping(old: snap.oldMessages, new: newMessages)
        invalidateCaches(vc: vc, oldMessages: snap.oldMessages, newMessages: newMessages, pendingMapping: pendingMapping)

        vc.setMessages(newMessages)
        vc.rebuildMessageIndex()
        let newRows = vc.buildRows(from: newMessages)
        let changeset = StagedChangeset(source: snap.oldRows, target: newRows)

        // Подсчёт операций
        var ins = 0, del = 0, mov = 0, upd = 0
        for stage in changeset { ins += stage.elementInserted.count; del += stage.elementDeleted.count; mov += stage.elementMoved.count; upd += stage.elementUpdated.count }
        let structural = ins + del + mov

        // Скролл
        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }
        let wantScroll = shouldScroll || (snap.wasAtBottom && !vc.isLoadingNewerActive)

        if structural == 0 {
            log("  Стратегия: CONTENT_ONLY (upd=\(upd), pending=\(pendingMapping.oldToNew.count))")
            applyContentOnly(vc: vc, newRows: newRows, pendingMapping: pendingMapping, snap: snap, wantScroll: shouldScroll)
        } else {
            log("  Стратегия: STRUCTURAL (ins=\(ins) del=\(del) mov=\(mov) upd=\(upd), stages=\(changeset.count))")
            applyStructural(vc: vc, newRows: newRows, changeset: changeset, snap: snap, wantScroll: wantScroll, animateScroll: shouldScroll)
        }
    }

    /// Быстрая проверка: будет ли обновление структурным.
    func peekClassify(old: [ChatMessage], new: [ChatMessage]) -> Bool {
        if old.isEmpty || new.isEmpty { return false }
        let oldRows = controller?.buildRows(from: old) ?? []
        let newRows = controller?.buildRows(from: new) ?? []
        let changeset = StagedChangeset(source: oldRows, target: newRows)
        return changeset.reduce(0) { $0 + $1.elementInserted.count + $1.elementDeleted.count + $1.elementMoved.count } > 0
    }
}

// MARK: - Snapshot

private extension MessageUpdateHandler {
    struct Snapshot {
        let wasAtBottom: Bool
        let oldMessages: [ChatMessage]
        let oldRows: [ChatRow]
        let oldLayoutData: [RowLayoutInfo]
        let savedOffset: CGPoint

        init(vc: ChatViewController) {
            wasAtBottom   = vc.isNearBottom()
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
        vc.isInitialScrollProtected = true
        vc.sizeCache.invalidateAll()
        vc.setRows(newRows)
        vc.applyLayoutData(vc.computeLayoutData())
        vc.collectionView.reloadData()
        vc.collectionView.layoutIfNeeded()

        let cv = vc.collectionView!

        if vc.pendingScrollToBottom {
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toBottom
            log("  Стратегия: INITIAL → toBottom (pending)")
        } else if let anchor = vc.pendingScrollAnchor {
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toAnchor(anchor)
            log("  Стратегия: INITIAL → toAnchor(\(anchor.messageId.prefix(12)))")
        } else {
            vc.pendingInitialScroll = .toBottom
            log("  Стратегия: INITIAL → toBottom (default)")
        }

        log("  Результат: rows=\(newRows.count), contentH=\(f(cv.contentSize.height))")
        vc.executePendingInitialScroll()
    }
}

// MARK: - Clear

private extension MessageUpdateHandler {
    func applyClear(vc: ChatViewController) {
        vc.setMessages([])
        vc.rebuildMessageIndex()
        vc.setRows([])
        vc.applyLayoutData([])
        vc.sizeCache.invalidateAll()
        vc.collectionView.reloadData()
        log("  Стратегия: CLEAR")
        vc.finalizeUpdate(count: 0, animated: false)
    }
}

// MARK: - Prepend

private extension MessageUpdateHandler {
    func applyPrepend(vc: ChatViewController, newRows: [ChatRow], snap s: Snapshot) {
        guard newRows.count > s.oldRows.count else { return }

        var oldTotalH: CGFloat = 0
        for info in vc.chatLayout.rowLayoutData { oldTotalH += info.totalHeight }

        vc.setRows(newRows)
        let newLayout = vc.computeLayoutData()
        var newTotalH: CGFloat = 0
        for info in newLayout { newTotalH += info.totalHeight }
        let compensation = newTotalH - oldTotalH

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        vc.applyLayoutData(newLayout)
        let saved = vc.collectionView.contentOffset
        vc.collectionView.reloadData()
        vc.collectionView.contentOffset = CGPoint(x: saved.x, y: saved.y + compensation)
        vc.collectionView.layoutIfNeeded()
        CATransaction.commit()

        log("  Метод: reloadData + offset compensation (\(f(compensation)))")
        log("  Результат: offset=\(f(vc.collectionView.contentOffset.y))")

        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }
}

// MARK: - Append

private extension MessageUpdateHandler {
    func applyAppend(vc: ChatViewController, newRows: [ChatRow], snap s: Snapshot) {
        let insertedCount = newRows.count - s.oldRows.count
        let wantScroll = vc.pendingScrollToBottom || (s.wasAtBottom && insertedCount <= 2 && !vc.isLoadingNewerActive)
        if wantScroll { vc.pendingScrollToBottom = false }

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
            log("  Метод: reloadData → scrollToBottom (animated)")
        } else {
            vc.collectionView.contentOffset = s.savedOffset
            log("  Метод: reloadData → preserve offset=\(f(s.savedOffset.y))")
        }

        log("  Результат: offset=\(f(vc.collectionView.contentOffset.y)), contentH=\(f(vc.collectionView.contentSize.height))")

        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }
}

// MARK: - Structural

private extension MessageUpdateHandler {

    func applyStructural(vc: ChatViewController, newRows: [ChatRow], changeset: StagedChangeset<[ChatRow]>,
                         snap s: Snapshot, wantScroll: Bool, animateScroll: Bool = false) {
        let cv = vc.collectionView!

        // Подсчёт операций
        var allInserted: [IndexPath] = [], allDeleted: [IndexPath] = [], allUpdated: [IndexPath] = []
        for stage in changeset {
            allDeleted += stage.elementDeleted.map { IndexPath(item: $0.element, section: $0.section) }
            allInserted += stage.elementInserted.map { IndexPath(item: $0.element, section: $0.section) }
            allUpdated += stage.elementUpdated.map { IndexPath(item: $0.element, section: $0.section) }
        }

        // Классификация
        let isFullReplace = (allDeleted.count + allInserted.count) > max(s.oldRows.count, newRows.count)
        let hasInserts = !allInserted.isEmpty
        let hasDeletes = !allDeleted.isEmpty
        // Snapshot fade: fullReplace, mixed (del+ins), insert only — всё с inserts кроме чистых delete/shuffle
        let useSnapshotFade = !isFullReplace && hasInserts

        // Удалённые ID
        let deletedIDs: Set<String> = {
            let old = Set(s.oldMessages.map(\.id))
            let new = Set(vc.messages.map(\.id))
            return old.subtracting(new)
        }()

        // Якоря (все видимые message cells)
        let anchors = wantScroll ? [] : vc.currentVisibleAnchors()

        if !anchors.isEmpty {
            log("  Anchors: \(anchors.count), top=\(anchors.first!.messageId.prefix(10))…, bot=\(anchors.last!.messageId.prefix(10))…")
        }

        // ── Выбор метода и анимации ──
        //
        // | Кейс              | Анимация       | Скролл после         |
        // |--------------------|----------------|----------------------|
        // | FullReplace        | Snapshot fade  | anchor / scrollToBot |
        // | Insert / Mixed     | Snapshot fade  | anchor / scrollToBot |
        // | Delete / Shuffle   | DK animated    | DK сам               |
        // | Disintegration     | Конфетти → DK  | DK сам / anchor      |

        let doApply = { [weak self] (suppressAnimation: Bool) in
            guard let self else { return }

            let offsetBefore = cv.contentOffset.y
            let contentHBefore = cv.contentSize.height
            var dkAnimated = false
            // Snapshot fade используется для fullReplace и mixed — offset восстанавливается до fade
            var usedSnapshotFade = false

            // ── Применение данных ──

            if isFullReplace || useSnapshotFade {
                // Snapshot → DK без анимации → offset → fade
                let snapshot = cv.snapshotView(afterScreenUpdates: false)

                UIView.performWithoutAnimation {
                    cv.reload(using: changeset) { [weak vc] data in
                        guard let vc else { return }
                        vc.setRows(data)
                        vc.applyLayoutData(vc.computeLayoutData())
                    }
                    cv.layoutIfNeeded()
                }

                if vc.rows != newRows {
                    vc.setRows(newRows)
                    vc.applyLayoutData(vc.computeLayoutData())
                    cv.reloadData()
                    cv.layoutIfNeeded()
                }

                if wantScroll {
                    self.scrollToBottom(cv: cv, animated: false)
                } else if !anchors.isEmpty {
                    vc.restoreBestAnchor(anchors)
                }

                if let snap = snapshot {
                    let frame = cv.convert(cv.bounds, to: vc.view)
                    snap.frame = frame
                    vc.view.addSubview(snap)
                    UIView.animate(withDuration: 0.25, animations: { snap.alpha = 0 }) { _ in snap.removeFromSuperview() }
                }

                usedSnapshotFade = true
                let type = isFullReplace ? "FULL_REPLACE" : (hasDeletes ? "MIXED" : "INSERT")
                log("  Метод: \(type) (snapshot fade, del=\(allDeleted.count) ins=\(allInserted.count) upd=\(allUpdated.count))")

            } else {
                // DK batch — анимация для delete/shuffle (нет inserts)
                let shouldAnimate = !suppressAnimation
                dkAnimated = shouldAnimate

                let apply = {
                    cv.reload(using: changeset) { [weak vc] data in
                        guard let vc else { return }
                        vc.setRows(data)
                        vc.applyLayoutData(vc.computeLayoutData())
                    }
                    cv.layoutIfNeeded()
                }

                if shouldAnimate { apply() } else { UIView.performWithoutAnimation(apply) }

                if vc.rows != newRows {
                    log("  ⚠️ Rows inconsistent → full reload")
                    vc.setRows(newRows)
                    vc.applyLayoutData(vc.computeLayoutData())
                    cv.reloadData()
                    cv.layoutIfNeeded()
                }

                let animType = shouldAnimate ? (hasDeletes ? "DELETE" : "SHUFFLE") : "INSERT"
                log("  Метод: DK_BATCH (\(animType), stages=\(changeset.count), animated=\(shouldAnimate))")
            }

            // ── Скролл ──

            let offsetAfter = cv.contentOffset.y
            let contentHAfter = cv.contentSize.height

            if usedSnapshotFade {
                log("  Скролл: offset в snapshot fade, offset=\(f(cv.contentOffset.y))")
            } else if wantScroll {
                self.scrollToBottom(cv: cv, animated: animateScroll)
                log("  Скролл: scrollToBottom (animated=\(animateScroll))")
            } else if dkAnimated {
                log("  Скролл: DK animated (не трогаем)")
            } else if !anchors.isEmpty {
                vc.restoreBestAnchor(anchors)
                log("  Скролл: best anchor restore")
            }

            log("  Результат: offset=\(f(cv.contentOffset.y)) (Δ\(f(cv.contentOffset.y - offsetBefore))), contentH=\(f(contentHAfter)) (Δ\(f(contentHAfter - contentHBefore)))")

            if !s.wasAtBottom && !wantScroll {
                vc.trackNewUnread(newMessages: vc.messages, oldCount: s.oldMessages.count)
            }

            vc.finalizeUpdate(count: newRows.count, animated: true)
            vc.flushPendingMessages()
        }

        // ── Disintegration ──

        if vc.disintegrationEnabled && !deletedIDs.isEmpty && !isFullReplace && !hasInserts {
            log("  Disintegration: \(deletedIDs.count) удалений")
            animateDisintegrationThen(vc: vc, deletedIDs: deletedIDs) { hadVisible in
                doApply(!hadVisible)
            }
        } else {
            doApply(false)
        }
    }
}

// MARK: - ContentOnly

private extension MessageUpdateHandler {

    func applyContentOnly(vc: ChatViewController, newRows: [ChatRow],
                          pendingMapping: MessageDiff.PendingMapping = .empty,
                          snap s: Snapshot, wantScroll: Bool) {
        let cv = vc.collectionView!

        // Lookup + pending mapping
        let newMsgByID = Dictionary(vc.messages.map { ($0.id, $0) }, uniquingKeysWith: { _, l in l })
        var pendingMap: [String: ChatMessage] = [:]
        for (oldId, newId) in pendingMapping.oldToNew {
            if let msg = newMsgByID[newId] { pendingMap[oldId] = msg }
        }

        // Патч строк, сбор изменённых
        var rows = s.oldRows
        var changed: [Int] = []

        for (i, row) in rows.enumerated() {
            guard case .message(let msg) = row else { continue }
            if let updated = newMsgByID[msg.id], updated != msg {
                rows[i] = .message(updated)
                changed.append(i)
            } else if let updated = pendingMap[msg.id] {
                rows[i] = .message(updated)
                changed.append(i)
            }
        }
        vc.setRows(rows)
        if !pendingMapping.isEmpty { vc.rebuildCachesFromRows() }

        // Layout для изменённых — O(changed)
        var layoutData = s.oldLayoutData
        var width = cv.bounds.width
        if width <= 0 { width = UIScreen.main.bounds.width }

        guard layoutData.count == rows.count else {
            log("  ⚠️ Layout/row mismatch → full reload")
            vc.applyLayoutData(vc.computeLayoutData())
            cv.reloadData()
            cv.layoutIfNeeded()
            vc.finalizeUpdate(count: rows.count, animated: false)
            vc.flushPendingMessages()
            return
        }

        for i in changed {
            guard case .message(let msg) = rows[i] else { continue }
            let oldH = layoutData[i].height
            let newH = vc.computeMessageHeight(forId: msg.id, width: width)
            let extra: CGFloat
            switch msg.ownership {
            case .system: extra = vc.layout.systemCellBottomSpacing
            case .pinned: extra = vc.layout.pinnedCellBottomSpacing
            default:      extra = 0
            }
            layoutData[i] = RowLayoutInfo(
                height: newH,
                topInset: vc.layout.cellVSpacing / 2 + extra,
                bottomInset: vc.layout.cellVSpacing / 2 + extra
            )
            if abs(oldH - newH) > 0.5 {
                log("  Height: \(msg.id.prefix(12)) \(f(oldH)) → \(f(newH)) (Δ\(f(newH - oldH)))")
            }
        }
        vc.applyLayoutData(layoutData)

        let stayAtBottom = s.wasAtBottom
        let delta = (wantScroll || stayAtBottom) ? 0 : OffsetCalculator.bottomStableDelta(
            oldRows: s.oldRows, oldLayout: s.oldLayoutData,
            newRows: rows, newLayout: layoutData, vc: vc)

        log("  Метод: CONTENT_ONLY (\(changed.count) изменений, stayAtBottom=\(stayAtBottom), delta=\(f(delta)))")

        // Crossfade на изменённых ячейках
        for i in changed {
            let ip = IndexPath(item: i, section: 0)
            guard case .message(let msg) = rows[i] else { continue }
            if let cell = cv.cellForItem(at: ip) as? MessageCell {
                UIView.transition(with: cell.bubbleView, duration: 0.2, options: .transitionCrossDissolve) {
                    vc.dataSource.reconfigureMessageCellInPlace(cell, message: msg, vc: vc)
                }
            }
        }

        // Атомарное обновление offset + layout
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()

        if stayAtBottom || wantScroll {
            scrollToBottom(cv: cv, animated: false)
        } else {
            cv.contentOffset = CGPoint(x: s.savedOffset.x, y: s.savedOffset.y + delta)
            OffsetCalculator.clamp(cv: cv, savedX: s.savedOffset.x, skip: false)
        }

        CATransaction.commit()

        log("  Результат: offset=\(f(cv.contentOffset.y)), contentH=\(f(cv.contentSize.height))")

        vc.finalizeUpdate(count: rows.count, animated: true)
        vc.flushPendingMessages()
    }
}

// MARK: - Disintegration

private extension MessageUpdateHandler {

    func animateDisintegrationThen(vc: ChatViewController, deletedIDs: Set<String>, then: @escaping (_ hadVisibleAnimation: Bool) -> Void) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { then(true) }
        } else {
            then(false)
        }
    }
}

// MARK: - Вспомогательное

private extension MessageUpdateHandler {

    func invalidateChangedMessages(vc: ChatViewController, oldMessages: [ChatMessage], newMessages: [ChatMessage]) {
        let oldById = Dictionary(oldMessages.map { ($0.id, $0) }, uniquingKeysWith: { _, l in l })
        for msg in newMessages {
            if let prev = oldById[msg.id], prev != msg {
                vc.invalidateSizeCache(forKey: msg.id)
            }
        }
    }

    func invalidateCaches(vc: ChatViewController, oldMessages: [ChatMessage], newMessages: [ChatMessage], pendingMapping: MessageDiff.PendingMapping) {
        invalidateChangedMessages(vc: vc, oldMessages: oldMessages, newMessages: newMessages)
        for oldId in pendingMapping.oldToNew.keys {
            vc.invalidateSizeCache(forKey: oldId)
        }
    }

    func scrollToBottom(cv: UICollectionView, animated: Bool = true) {
        let maxY = cv.contentSize.height - cv.bounds.height + cv.contentInset.bottom
        if maxY > -cv.contentInset.top {
            cv.setContentOffset(CGPoint(x: 0, y: maxY), animated: animated)
        }
    }
}

// MARK: - OffsetCalculator

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
