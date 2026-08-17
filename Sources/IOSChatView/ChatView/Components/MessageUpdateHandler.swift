import UIKit
import DifferenceKit

// MARK: - Логирование

/// Аргумент — @autoclosure: интерполяция строки не вычисляется в release-сборках.
private func log(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}

private func f(_ v: CGFloat) -> String { String(format: "%.1f", v) }

// MARK: - Роутер обновлений

/// Быстрые пути (без DK): Initial, Clear, Prepend, Append.
/// DK changeset — единственный diff-движок:
/// ContentOnly (structural=0): инкрементальный патч + bottom-stable offset.
/// Structural (structural>0): DK batch + anchor restore.
final class MessageUpdateHandler {

    private weak var controller: ChatViewController?

    init(controller: ChatViewController) {
        self.controller = controller
    }

    // MARK: - Публичное API

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

        var ins = 0, del = 0, mov = 0, upd = 0
        for stage in changeset { ins += stage.elementInserted.count; del += stage.elementDeleted.count; mov += stage.elementMoved.count; upd += stage.elementUpdated.count }
        let structural = ins + del + mov

        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }

        if structural == 0 {
            log("  Стратегия: CONTENT_ONLY (upd=\(upd), pending=\(pendingMapping.oldToNew.count))")
            applyContentOnly(vc: vc, newRows: newRows, pendingMapping: pendingMapping, snap: snap, wantScroll: shouldScroll)
        } else {
            log("  Стратегия: STRUCTURAL (ins=\(ins) del=\(del) mov=\(mov) upd=\(upd), stages=\(changeset.count))")
            applyStructural(vc: vc, newRows: newRows, changeset: changeset, snap: snap, wantScroll: shouldScroll, animateScroll: shouldScroll)
        }
    }

    /// Вызывается во время скролла — дешёвая O(n) проверка без DK-changeset
    /// и без построения строк.
    func peekClassify(old: [ChatMessage], new: [ChatMessage]) -> Bool {
        if old.isEmpty || new.isEmpty { return false }
        return MessageDiff.hasStructuralChange(old: old, new: new)
    }
}

// MARK: - Снимок состояния

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

// MARK: - Первичная загрузка

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

// MARK: - Очистка

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
            scrollToBottom(cv: vc.collectionView, animated: true)
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

// MARK: - Структурные изменения

private extension MessageUpdateHandler {

    func applyStructural(vc: ChatViewController, newRows: [ChatRow], changeset: StagedChangeset<[ChatRow]>,
                         snap s: Snapshot, wantScroll: Bool, animateScroll: Bool = false) {
        let cv = vc.collectionView!

        var allInserted: [IndexPath] = [], allDeleted: [IndexPath] = [], allUpdated: [IndexPath] = []
        for stage in changeset {
            allDeleted += stage.elementDeleted.map { IndexPath(item: $0.element, section: $0.section) }
            allInserted += stage.elementInserted.map { IndexPath(item: $0.element, section: $0.section) }
            allUpdated += stage.elementUpdated.map { IndexPath(item: $0.element, section: $0.section) }
        }

        let hasInserts = !allInserted.isEmpty
        let hasDeletes = !allDeleted.isEmpty

        let deletedIDs: Set<String> = {
            let old = Set(s.oldMessages.map(\.id))
            let new = Set(vc.messages.map(\.id))
            return old.subtracting(new)
        }()

        // Якоря — видимые message cells для восстановления позиции скролла после DK batch
        let anchors = wantScroll ? [] : vc.currentVisibleAnchors()

        if !anchors.isEmpty {
            log("  Anchors: \(anchors.count), top=\(anchors.first!.messageId.prefix(10))…, bot=\(anchors.last!.messageId.prefix(10))…")
        }

        let doApply = { [weak self] (suppressAnimation: Bool) in
            guard let self else { return }

            let offsetBefore = cv.contentOffset.y
            let contentHBefore = cv.contentSize.height
            var dkAnimated = false
            // Snapshot fade для fullReplace/mixed — offset восстанавливается до fade
            var usedSnapshotFade = false

            if hasInserts {
                // Snapshot → DK без анимации → восстановление offset → fade поверх
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
                    vc.restoreBestAnchor(anchors, fallbackOffset: offsetBefore)
                } else {
                    // Нет якорей — clamp старый offset к новому contentSize
                    let minY = -cv.adjustedContentInset.top
                    let maxY = cv.chatMaxOffsetY
                    cv.contentOffset = CGPoint(x: 0, y: min(max(offsetBefore, minY), max(maxY, minY)))
                }

                if let snap = snapshot {
                    let frame = cv.convert(cv.bounds, to: vc.view)
                    snap.frame = frame
                    vc.view.addSubview(snap)
                    UIView.animate(withDuration: 0.25, animations: { snap.alpha = 0 }) { _ in snap.removeFromSuperview() }
                }

                usedSnapshotFade = true
                let type = hasDeletes ? "MIXED" : "INSERT"
                log("  Метод: \(type) (snapshot fade, del=\(allDeleted.count) ins=\(allInserted.count) upd=\(allUpdated.count))")

            } else {
                // DK batch с анимацией — только delete/shuffle (без inserts)
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

        if vc.disintegrationEnabled && !deletedIDs.isEmpty && !hasInserts {
            log("  Disintegration: \(deletedIDs.count) удалений")
            animateDisintegrationThen(vc: vc, deletedIDs: deletedIDs) { hadVisible in
                doApply(!hadVisible)
            }
        } else {
            doApply(false)
        }
    }
}

// MARK: - Контентные обновления (без структурных изменений)

private extension MessageUpdateHandler {

    func applyContentOnly(vc: ChatViewController, newRows: [ChatRow],
                          pendingMapping: MessageDiff.PendingMapping = .empty,
                          snap s: Snapshot, wantScroll: Bool) {
        let cv = vc.collectionView!

        // rebuildMessageIndex() уже вызван — vc.messageIndex индексирует новые сообщения
        let newMsgByID = vc.messageIndex
        var pendingMap: [String: ChatMessage] = [:]
        for (oldId, newId) in pendingMapping.oldToNew {
            if let msg = newMsgByID[newId] { pendingMap[oldId] = msg }
        }

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

        // Пересчёт layout только для изменённых строк — O(changed)
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
            layoutData[i] = vc.messageRowLayoutInfo(for: msg, width: width)
            let newH = layoutData[i].height
            if abs(oldH - newH) > 0.5 {
                log("  Height: \(msg.id.prefix(12)) \(f(oldH)) → \(f(newH)) (Δ\(f(newH - oldH)))")
            }
        }
        vc.applyLayoutData(layoutData)

        let stayAtBottom = s.wasAtBottom
        let delta = (wantScroll || stayAtBottom) ? 0 : OffsetCalculator.bottomStableDelta(
            oldRows: s.oldRows, oldLayout: s.oldLayoutData,
            newRows: rows, newLayout: layoutData,
            visibleItems: cv.indexPathsForVisibleItems.map(\.item))

        log("  Метод: CONTENT_ONLY (\(changed.count) изменений, stayAtBottom=\(stayAtBottom), delta=\(f(delta)))")

        for i in changed {
            let ip = IndexPath(item: i, section: 0)
            guard case .message(let msg) = rows[i] else { continue }
            if let cell = cv.cellForItem(at: ip) as? MessageCell {
                vc.dataSource.reconfigureMessageCellInPlace(cell, message: msg, vc: vc)
            }
        }

        // Атомарное обновление: offset + layout в одном CATransaction без промежуточного кадра
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

// MARK: - Анимация распада

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

    /// Вызывается ДО setMessages/rebuildMessageIndex — vc.messageIndex на этот
    /// момент индексирует старые сообщения, отдельный словарь не нужен.
    func invalidateChangedMessages(vc: ChatViewController, oldMessages: [ChatMessage], newMessages: [ChatMessage]) {
        for msg in newMessages {
            if let prev = vc.messageIndex[msg.id], prev != msg {
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
        let maxY = cv.chatMaxOffsetY
        if maxY > -cv.contentInset.top {
            cv.setContentOffset(CGPoint(x: 0, y: maxY), animated: animated)
        }
    }
}

// MARK: - Калькулятор offset

enum OffsetCalculator {

    /// Чистая функция: принимает индексы видимых строк (сверху вниз по item)
    /// вместо доступа к контроллеру — тестируется без UIKit.
    static func bottomStableDelta(
        oldRows: [ChatRow], oldLayout: [RowLayoutInfo],
        newRows: [ChatRow], newLayout: [RowLayoutInfo],
        visibleItems: [Int]
    ) -> CGFloat {
        var newIndex: [String: Int] = Dictionary(minimumCapacity: newRows.count)
        for (i, row) in newRows.enumerated() {
            if let id = row.messageId { newIndex[id] = i }
        }

        let oldSums = prefixSums(oldLayout)
        let newSums = prefixSums(newLayout)

        // Нижний видимый элемент — первый в порядке убывания item
        for idx in visibleItems.sorted(by: >) {
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
        let maxY = cv.chatMaxOffsetY
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
