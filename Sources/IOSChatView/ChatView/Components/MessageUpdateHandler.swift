import UIKit
import DifferenceKit

// MARK: - Роутер обновлений

/// Единая точка входа для обновления списка сообщений.
///
/// Быстрые пути (без DifferenceKit):
/// - Initial: пустой список → данные, `reloadData` + скролл
/// - Clear: данные → пустой список
/// - Prepend: старые сообщения сверху, компенсация offset
/// - Append: новые сообщения снизу, сохранение позиции скролла
///
/// Всё остальное: DK changeset — единственный источник правды для классификации.
/// - structural > 0 → DK анимированный batch (insert/delete/move)
/// - structural = 0 → contentOnly (инкрементальный патч, bottom-stable offset)
final class MessageUpdateHandler {

    private weak var controller: ChatViewController?

    init(controller: ChatViewController) {
        self.controller = controller
    }

    // MARK: - Public

    func update(with newMessages: [ChatMessage]) {
        guard let vc = controller else { return }

        let snap = Snapshot(vc: vc)

        // Пустой → данные
        if snap.oldMessages.isEmpty {
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            applyInitial(vc: vc, newRows: vc.buildRows(from: newMessages))
            return
        }

        // Данные → пустой
        if newMessages.isEmpty {
            applyClear(vc: vc)
            return
        }

        // Prepend / Append — дешёвая O(n) проверка по порядку ID
        if MessageDiff.isPrependOnly(old: snap.oldMessages, new: newMessages) {
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            applyPrepend(vc: vc, newRows: vc.buildRows(from: newMessages), snap: snap)
            return
        }
        if MessageDiff.isAppendOnly(old: snap.oldMessages, new: newMessages) {
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            applyAppend(vc: vc, newRows: vc.buildRows(from: newMessages), snap: snap)
            return
        }

        // Всё остальное: DK changeset как единый diff-движок
        let pendingMapping = MessageDiff.buildPendingMapping(old: snap.oldMessages, new: newMessages)
        invalidateCaches(vc: vc, oldMessages: snap.oldMessages, newMessages: newMessages, pendingMapping: pendingMapping)

        vc.setMessages(newMessages)
        vc.rebuildMessageIndex()
        let newRows = vc.buildRows(from: newMessages)

        // DK changeset на строках (включая date separators, детектирует moves)
        let changeset = StagedChangeset(source: snap.oldRows, target: newRows)
        let structuralCount = changeset.reduce(0) { $0 + $1.elementInserted.count + $1.elementDeleted.count + $1.elementMoved.count }

        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }
        let wantScroll = shouldScroll || (snap.wasAtBottom && !vc.isLoadingNewerActive)

        let updateCount = changeset.reduce(0) { $0 + $1.elementUpdated.count }
        print("[UpdateHandler] structural=\(structuralCount) updates=\(updateCount) pending=\(pendingMapping.oldToNew.count) wantScroll=\(wantScroll)")

        if structuralCount == 0 {
            // ContentOnly: bottom-stable delta сам удержит позицию, scrollToBottom не нужен
            applyContentOnly(vc: vc, newRows: newRows, pendingMapping: pendingMapping, snap: snap, wantScroll: shouldScroll)
        } else {
            // Анимированный скролл только по явному запросу (send, returnToLatest),
            // для auto-scroll (wasAtBottom) — без анимации
            applyStructural(vc: vc, newRows: newRows, changeset: changeset, structuralCount: structuralCount, snap: snap, wantScroll: wantScroll, animateScroll: shouldScroll)
        }
    }

    /// Быстрая проверка: будет ли обновление структурным (для отложенного применения при скролле).
    func peekClassify(old: [ChatMessage], new: [ChatMessage]) -> Bool {
        if old.isEmpty || new.isEmpty { return false }
        let oldRows = controller?.buildRows(from: old) ?? []
        let newRows = controller?.buildRows(from: new) ?? []
        let changeset = StagedChangeset(source: oldRows, target: newRows)
        return changeset.reduce(0) { $0 + $1.elementInserted.count + $1.elementDeleted.count + $1.elementMoved.count } > 0
    }
}

// MARK: - Снапшот состояния до обновления

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

// MARK: - Initial (пустой → данные)

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
        print("[Initial] offset=\(f(cv.contentOffset.y)) contentH=\(f(cv.contentSize.height)) frameH=\(f(cv.bounds.height))")

        if vc.pendingScrollToBottom {
            print("[Initial] → toBottom (pending)")
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toBottom
        } else if let anchor = vc.pendingScrollAnchor {
            print("[Initial] → toAnchor(\(anchor.messageId.prefix(8)))")
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toAnchor(anchor)
        } else {
            print("[Initial] → toBottom (default)")
            vc.pendingInitialScroll = .toBottom
        }

        vc.executePendingInitialScroll()
    }
}

// MARK: - Clear (данные → пустой)

private extension MessageUpdateHandler {

    func applyClear(vc: ChatViewController) {
        vc.setMessages([])
        vc.rebuildMessageIndex()
        vc.setRows([])
        vc.applyLayoutData([])
        vc.sizeCache.invalidateAll()
        vc.collectionView.reloadData()
        vc.finalizeUpdate(count: 0, animated: false)
    }
}

// MARK: - Prepend (старые сообщения сверху, компенсация offset)

private extension MessageUpdateHandler {

    func applyPrepend(vc: ChatViewController, newRows: [ChatRow], snap s: Snapshot) {
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

        print("[Prepend] offset=\(f(vc.collectionView.contentOffset.y))")
        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }
}

// MARK: - Append (новые сообщения снизу, сохранение позиции скролла)

private extension MessageUpdateHandler {

    func applyAppend(vc: ChatViewController, newRows: [ChatRow], snap s: Snapshot) {
        let insertedCount = newRows.count - s.oldRows.count
        // Авто-скролл только для 1-2 сообщений (сокет) внизу, не для пагинации
        let wantScroll = vc.pendingScrollToBottom || (s.wasAtBottom && insertedCount <= 2 && !vc.isLoadingNewerActive)
        if wantScroll { vc.pendingScrollToBottom = false }

        print("[Append] oldRows=\(s.oldRows.count) newRows=\(newRows.count) wantScroll=\(wantScroll) wasAtBottom=\(s.wasAtBottom)")

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
            vc.collectionView.contentOffset = s.savedOffset
            print("[Append] → offset=\(f(s.savedOffset.y))")
        }

        vc.finalizeUpdate(count: newRows.count, animated: false)
        vc.flushPendingMessages()
    }
}

// MARK: - Structural (DK анимированный batch: insert/delete/move)

private extension MessageUpdateHandler {

    func applyStructural(vc: ChatViewController, newRows: [ChatRow], changeset: StagedChangeset<[ChatRow]>,
                         structuralCount: Int, snap s: Snapshot, wantScroll: Bool, animateScroll: Bool = false) {
        let cv = vc.collectionView!

        // Полная замена — crossfade вместо staged DK анимации
        let isFullReplace = structuralCount > max(s.oldRows.count, newRows.count)

        // Удалённые ID для disintegration-анимации
        let deletedIDs: Set<String> = {
            let oldIDs = Set(s.oldMessages.map(\.id))
            let newIDs = Set(vc.messages.map(\.id))
            return oldIDs.subtracting(newIDs)
        }()

        print("[Structural] changes=\(structuralCount) fullReplace=\(isFullReplace) deleted=\(deletedIDs.count) wantScroll=\(wantScroll)")

        let doApply = { [weak self] in
            guard let self else { return }

            let offsetBefore = cv.contentOffset.y
            let contentHBefore = cv.contentSize.height

            // Якорь для восстановления позиции скролла
            let anchor = wantScroll ? nil : vc.currentScrollAnchor()
            if let a = anchor {
                print("[Structural] anchor: msg=\(a.messageId.prefix(12)) offsetFromTop=\(f(a.offsetFromTop)) wasAtBottom=\(a.wasAtBottom)")
            }

            if isFullReplace {
                vc.setRows(newRows)
                vc.applyLayoutData(vc.computeLayoutData())
                UIView.transition(with: cv, duration: 0.25, options: .transitionCrossDissolve) {
                    cv.reloadData()
                    cv.layoutIfNeeded()
                }
                print("[Structural] → crossfade")
            } else {
                // Подавляем анимацию для multi-stage insert/delete (промежуточные layout shifts).
                // Moves (shuffle) — всегда анимируем, они не вызывают staged shifts.
                let hasMultiStageInsertDelete = changeset.count > 1 && changeset.contains {
                    !$0.elementInserted.isEmpty || !$0.elementDeleted.isEmpty
                }
                let applyDK = {
                    cv.reload(using: changeset) { [weak vc] data in
                        guard let vc else { return }
                        vc.setRows(data)
                        vc.applyLayoutData(vc.computeLayoutData())
                    }
                    cv.layoutIfNeeded()
                }

                if hasMultiStageInsertDelete {
                    UIView.performWithoutAnimation(applyDK)
                } else {
                    applyDK()
                }

                if vc.rows != newRows {
                    print("[Structural] ⚠️ rows inconsistent → full reload")
                    vc.setRows(newRows)
                    vc.applyLayoutData(vc.computeLayoutData())
                    cv.reloadData()
                    cv.layoutIfNeeded()
                }

                let offsetAfterDK = cv.contentOffset.y
                let contentHAfter = cv.contentSize.height
                print("[Structural] → DK batch (stages=\(changeset.count)): offset \(f(offsetBefore))→\(f(offsetAfterDK)) contentH \(f(contentHBefore))→\(f(contentHAfter))")
            }

            if wantScroll {
                self.scrollToBottom(cv: cv, animated: animateScroll)
                print("[Structural] → scrollToBottom(animated=\(animateScroll))")
            } else if let anchor {
                let offsetBeforeRestore = cv.contentOffset.y
                vc.restoreScrollAnchor(anchor)
                let offsetAfterRestore = cv.contentOffset.y
                print("[Structural] → restore anchor \(anchor.messageId.prefix(12)): offset \(f(offsetBeforeRestore))→\(f(offsetAfterRestore)) delta=\(f(offsetAfterRestore - offsetBefore))")
            }

            // Рекофигурация только ячеек с изменённым контентом (DK elementUpdated)
            let updatedIndices = Set(changeset.flatMap { $0.elementUpdated.map(\.element) })
            self.reconfigureUpdatedCells(vc: vc, newRows: newRows, indices: updatedIndices)

            if !s.wasAtBottom && !wantScroll {
                vc.trackNewUnread(newMessages: vc.messages, oldCount: s.oldMessages.count)
            }

            vc.finalizeUpdate(count: newRows.count, animated: true)
            vc.flushPendingMessages()
        }

        // Disintegration только для частичных удалений, не для полной замены
        if vc.disintegrationEnabled && !deletedIDs.isEmpty && !isFullReplace {
            animateDisintegrationThen(vc: vc, deletedIDs: deletedIDs, then: doApply)
        } else {
            doApply()
        }
    }

    /// Рекофигурация только изменённых ячеек (сохраняет анимации, например полоски poll).
    func reconfigureUpdatedCells(vc: ChatViewController, newRows: [ChatRow], indices: Set<Int>) {
        guard !indices.isEmpty else { return }
        let cv = vc.collectionView!
        var count = 0
        for idx in indices {
            guard idx < newRows.count, case .message(let msg) = newRows[idx] else { continue }
            let ip = IndexPath(item: idx, section: 0)
            if let cell = cv.cellForItem(at: ip) as? MessageCell {
                vc.dataSource.reconfigureMessageCellInPlace(cell, message: msg, vc: vc)
                count += 1
            }
        }
        if count > 0 {
            cv.collectionViewLayout.invalidateLayout()
            cv.layoutIfNeeded()
            print("[Structural] reconfigured \(count) cells")
        }
    }
}

// MARK: - ContentOnly (инкрементальный патч, bottom-stable offset)

private extension MessageUpdateHandler {

    func applyContentOnly(vc: ChatViewController, newRows: [ChatRow],
                          pendingMapping: MessageDiff.PendingMapping = .empty,
                          snap s: Snapshot, wantScroll: Bool) {
        let cv = vc.collectionView!

        // Lookup новых сообщений + pending→real маппинг
        let newMsgByID = Dictionary(vc.messages.map { ($0.id, $0) }, uniquingKeysWith: { _, l in l })
        var pendingMap: [String: ChatMessage] = [:]
        for (oldId, newId) in pendingMapping.oldToNew {
            if let msg = newMsgByID[newId] { pendingMap[oldId] = msg }
        }

        // Патч строк на месте, сбор изменённых индексов
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

        // Пересчёт layout только для изменённых строк — O(changed), не O(n)
        var layoutData = s.oldLayoutData
        var width = cv.bounds.width
        if width <= 0 { width = UIScreen.main.bounds.width }

        guard layoutData.count == rows.count else {
            print("[ContentOnly] ⚠️ layout/row count mismatch → full reload")
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

        // Стабилизация offset относительно нижнего видимого сообщения
        let delta = wantScroll ? 0 : OffsetCalculator.bottomStableDelta(
            oldRows: s.oldRows, oldLayout: s.oldLayoutData,
            newRows: rows, newLayout: layoutData, vc: vc)

        print("[ContentOnly] updated=\(changed.count) delta=\(f(delta)) wantScroll=\(wantScroll)")

        if !wantScroll {
            cv.contentOffset = CGPoint(x: s.savedOffset.x, y: s.savedOffset.y + delta)
        }

        // Рекофигурация видимых ячеек на месте (без пересоздания)
        for i in changed {
            let ip = IndexPath(item: i, section: 0)
            guard case .message(let msg) = rows[i] else { continue }
            if let cell = cv.cellForItem(at: ip) as? MessageCell {
                vc.dataSource.reconfigureMessageCellInPlace(cell, message: msg, vc: vc)
            }
        }
        cv.collectionViewLayout.invalidateLayout()
        cv.layoutIfNeeded()

        OffsetCalculator.clamp(cv: cv, savedX: s.savedOffset.x, skip: wantScroll)
        if wantScroll { scrollToBottom(cv: cv) }

        vc.finalizeUpdate(count: rows.count, animated: true)
        vc.flushPendingMessages()
    }
}

// MARK: - Disintegration (анимация удаления)

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

// MARK: - Вспомогательное

private extension MessageUpdateHandler {

    /// Инвалидация sizeCache для изменённых и pending сообщений.
    func invalidateCaches(vc: ChatViewController, oldMessages: [ChatMessage], newMessages: [ChatMessage], pendingMapping: MessageDiff.PendingMapping) {
        let oldById = Dictionary(oldMessages.map { ($0.id, $0) }, uniquingKeysWith: { _, l in l })
        for msg in newMessages {
            if let prev = oldById[msg.id], prev != msg {
                vc.invalidateSizeCache(forKey: msg.id)
            }
        }
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

// MARK: - Калькулятор offset (bottom-edge-stable)

enum OffsetCalculator {

    /// Дельта для стабилизации: пинит нижний видимый элемент к его экранной позиции.
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

    /// Ограничение offset в допустимых пределах.
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

private func f(_ v: CGFloat) -> String { String(format: "%.1f", v) }
