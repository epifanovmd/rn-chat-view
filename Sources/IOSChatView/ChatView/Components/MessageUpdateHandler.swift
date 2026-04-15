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
        let oldCount = snap.oldMessages.count
        let newCount = newMessages.count

        log("━━━ [Update] \(oldCount) → \(newCount) сообщений, wasAtBottom=\(snap.wasAtBottom) ━━━")

        // Пустой → данные
        if snap.oldMessages.isEmpty {
            log("  Стратегия: INITIAL")
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            applyInitial(vc: vc, newRows: vc.buildRows(from: newMessages))
            return
        }

        // Данные → пустой
        if newMessages.isEmpty {
            log("  Стратегия: CLEAR")
            applyClear(vc: vc)
            return
        }

        // Prepend / Append — дешёвая O(n) проверка по порядку ID
        if MessageDiff.isPrependOnly(old: snap.oldMessages, new: newMessages) {
            log("  Стратегия: PREPEND (+\(newCount - oldCount) сообщений сверху)")
            invalidateChangedMessages(vc: vc, oldMessages: snap.oldMessages, newMessages: newMessages)
            vc.setMessages(newMessages)
            vc.rebuildMessageIndex()
            applyPrepend(vc: vc, newRows: vc.buildRows(from: newMessages), snap: snap)
            return
        }
        if MessageDiff.isAppendOnly(old: snap.oldMessages, new: newMessages) {
            log("  Стратегия: APPEND (+\(newCount - oldCount) сообщений снизу)")
            invalidateChangedMessages(vc: vc, oldMessages: snap.oldMessages, newMessages: newMessages)
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

        var insertCount = 0, deleteCount = 0, moveCount = 0, updateCount = 0
        for stage in changeset {
            insertCount += stage.elementInserted.count
            deleteCount += stage.elementDeleted.count
            moveCount += stage.elementMoved.count
            updateCount += stage.elementUpdated.count
        }
        let structuralCount = insertCount + deleteCount + moveCount

        let shouldScroll = vc.pendingScrollToBottom
        if shouldScroll { vc.pendingScrollToBottom = false }
        let wantScroll = shouldScroll || (snap.wasAtBottom && !vc.isLoadingNewerActive)

        if structuralCount == 0 {
            log("  Стратегия: CONTENT_ONLY (обновлено: \(updateCount), pending: \(pendingMapping.oldToNew.count))")
            applyContentOnly(vc: vc, newRows: newRows, pendingMapping: pendingMapping, snap: snap, wantScroll: shouldScroll)
        } else {
            log("  Стратегия: STRUCTURAL (ins=\(insertCount) del=\(deleteCount) move=\(moveCount) upd=\(updateCount), stages=\(changeset.count), pending=\(pendingMapping.oldToNew.count))")
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
        vc.isInitialScrollProtected = true
        vc.sizeCache.invalidateAll()
        vc.setRows(newRows)
        vc.applyLayoutData(vc.computeLayoutData())
        vc.collectionView.reloadData()
        vc.collectionView.layoutIfNeeded()

        let cv = vc.collectionView!
        log("  Метод: reloadData")
        log("  Layout: rows=\(newRows.count) contentH=\(f(cv.contentSize.height)) frameH=\(f(cv.bounds.height))")

        if vc.pendingScrollToBottom {
            log("  Скролл: → toBottom (явный запрос)")
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toBottom
        } else if let anchor = vc.pendingScrollAnchor {
            log("  Скролл: → toAnchor(\(anchor.messageId.prefix(12)))")
            vc.pendingScrollAnchor = nil
            vc.pendingInitialScroll = .toAnchor(anchor)
        } else {
            log("  Скролл: → toBottom (по умолчанию)")
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
        log("  Метод: reloadData (очистка)")
        vc.finalizeUpdate(count: 0, animated: false)
    }
}

// MARK: - Prepend (старые сообщения сверху, компенсация offset)

private extension MessageUpdateHandler {

    func applyPrepend(vc: ChatViewController, newRows: [ChatRow], snap s: Snapshot) {
        guard newRows.count > s.oldRows.count else {
            log("  ⚠️ Пропуск: newRows(\(newRows.count)) <= oldRows(\(s.oldRows.count))")
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

        log("  Метод: reloadData + компенсация offset")
        log("  Offset: \(f(s.savedOffset.y)) + \(f(compensating)) = \(f(s.savedOffset.y + compensating))")

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

// MARK: - Append (новые сообщения снизу, сохранение позиции скролла)

private extension MessageUpdateHandler {

    func applyAppend(vc: ChatViewController, newRows: [ChatRow], snap s: Snapshot) {
        let insertedCount = newRows.count - s.oldRows.count
        // Авто-скролл только для 1-2 сообщений (сокет) внизу, не для пагинации
        let wantScroll = vc.pendingScrollToBottom || (s.wasAtBottom && insertedCount <= 2 && !vc.isLoadingNewerActive)
        if wantScroll { vc.pendingScrollToBottom = false }

        log("  Метод: reloadData")
        log("  Скролл: wantScroll=\(wantScroll) wasAtBottom=\(s.wasAtBottom) loadingNewer=\(vc.isLoadingNewerActive)")

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
            log("  Скролл: → scrollToBottom (animated)")
        } else {
            vc.collectionView.contentOffset = s.savedOffset
            log("  Скролл: → сохранён offset=\(f(s.savedOffset.y))")
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

        let doApply = { [weak self] (suppressAnimation: Bool) in
            guard let self else { return }

            let offsetBefore = cv.contentOffset.y
            let contentHBefore = cv.contentSize.height

            // Якорь для восстановления позиции скролла
            let anchor = wantScroll ? nil : vc.currentScrollAnchor()
            if let a = anchor {
                log("  Anchor: msg=\(a.messageId.prefix(12)) offsetFromTop=\(f(a.offsetFromTop)) wasAtBottom=\(a.wasAtBottom)")
            }

            if isFullReplace {
                vc.setRows(newRows)
                vc.applyLayoutData(vc.computeLayoutData())
                UIView.transition(with: cv, duration: 0.25, options: .transitionCrossDissolve) {
                    cv.reloadData()
                    cv.layoutIfNeeded()
                }
                log("  Метод: crossfade (полная замена)")
            } else {
                // Собираем все операции из stages
                var allDeleted: [IndexPath] = []
                var allInserted: [IndexPath] = []
                var allUpdated: [IndexPath] = []
                for stage in changeset {
                    allDeleted += stage.elementDeleted.map { IndexPath(item: $0.element, section: $0.section) }
                    allInserted += stage.elementInserted.map { IndexPath(item: $0.element, section: $0.section) }
                    allUpdated += stage.elementUpdated.map { IndexPath(item: $0.element, section: $0.section) }
                }

                let hasInsertDelete = !allDeleted.isEmpty || !allInserted.isEmpty

                if hasInsertDelete && changeset.count > 1 {
                    // Multi-stage — схлопываем в один performBatchUpdates
                    let applyMerged = {
                        cv.performBatchUpdates({
                            vc.setRows(newRows)
                            vc.applyLayoutData(vc.computeLayoutData())
                            if !allDeleted.isEmpty { cv.deleteItems(at: allDeleted) }
                            if !allInserted.isEmpty { cv.insertItems(at: allInserted) }
                            if !allUpdated.isEmpty { cv.reloadItems(at: allUpdated) }
                        })
                        cv.layoutIfNeeded()
                    }
                    if suppressAnimation { UIView.performWithoutAnimation(applyMerged) } else { applyMerged() }
                    log("  Метод: merged batch (del=\(allDeleted.count) ins=\(allInserted.count) upd=\(allUpdated.count), animated=\(!suppressAnimation))")
                } else {
                    // 1 stage или только moves/updates — DK
                    let applyDK = {
                        cv.reload(using: changeset) { [weak vc] data in
                            guard let vc else { return }
                            vc.setRows(data)
                            vc.applyLayoutData(vc.computeLayoutData())
                        }
                        cv.layoutIfNeeded()
                    }
                    if suppressAnimation { UIView.performWithoutAnimation(applyDK) } else { applyDK() }
                    log("  Метод: DK batch (stages=\(changeset.count), animated=\(!suppressAnimation))")
                }
            }

            if vc.rows != newRows {
                log("  ⚠️ Rows inconsistent → full reload")
                vc.setRows(newRows)
                vc.applyLayoutData(vc.computeLayoutData())
                cv.reloadData()
                cv.layoutIfNeeded()
            }

            let offsetAfter = cv.contentOffset.y
            let contentHAfter = cv.contentSize.height
            log("  Offset: \(f(offsetBefore)) → \(f(offsetAfter)), contentH: \(f(contentHBefore)) → \(f(contentHAfter))")

            if wantScroll {
                self.scrollToBottom(cv: cv, animated: animateScroll)
                log("  Скролл: → scrollToBottom (animated=\(animateScroll))")
            } else if let anchor {
                vc.restoreScrollAnchor(anchor)
                log("  Скролл: → restore anchor \(anchor.messageId.prefix(12)), offset: \(f(offsetAfter)) → \(f(cv.contentOffset.y))")
            }

            if !s.wasAtBottom && !wantScroll {
                vc.trackNewUnread(newMessages: vc.messages, oldCount: s.oldMessages.count)
            }

            vc.finalizeUpdate(count: newRows.count, animated: true)
            vc.flushPendingMessages()
        }

        // Disintegration только для чистых удалений (без одновременных вставок)
        let hasInserts = changeset.contains { !$0.elementInserted.isEmpty }
        if vc.disintegrationEnabled && !deletedIDs.isEmpty && !isFullReplace && !hasInserts {
            log("  Анимация: disintegration (\(deletedIDs.count) удалений)")
            animateDisintegrationThen(vc: vc, deletedIDs: deletedIDs) { hadVisibleAnimation in
                // Если удаление было вне viewport (конфетти не играло) — подавляем DK анимацию
                doApply(!hadVisibleAnimation)
            }
        } else {
            doApply(false)
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

        log("  Метод: инкрементальный патч (\(changed.count) изменений)")

        // Пересчёт layout только для изменённых строк — O(changed), не O(n)
        var layoutData = s.oldLayoutData
        var width = cv.bounds.width
        if width <= 0 { width = UIScreen.main.bounds.width }

        guard layoutData.count == rows.count else {
            log("  ⚠️ Layout/row count mismatch → full reload")
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
            let extraSpacing: CGFloat
            switch msg.ownership {
            case .system: extraSpacing = vc.layout.systemCellBottomSpacing
            case .pinned: extraSpacing = vc.layout.pinnedCellBottomSpacing
            default:      extraSpacing = 0
            }
            layoutData[i] = RowLayoutInfo(
                height: newH,
                topInset: vc.layout.cellVSpacing / 2 + extraSpacing,
                bottomInset: vc.layout.cellVSpacing / 2 + extraSpacing
            )
            if abs(oldH - newH) > 0.5 {
                log("  Height: \(msg.id.prefix(12)) \(f(oldH)) → \(f(newH)) (Δ\(f(newH - oldH)))")
            }
        }
        vc.applyLayoutData(layoutData)

        // Был внизу — останемся внизу, delta не нужна (и при wantScroll тоже — мы уже внизу)
        let stayAtBottom = s.wasAtBottom

        // Стабилизация offset относительно нижнего видимого сообщения
        let delta = (wantScroll || stayAtBottom) ? 0 : OffsetCalculator.bottomStableDelta(
            oldRows: s.oldRows, oldLayout: s.oldLayoutData,
            newRows: rows, newLayout: layoutData, vc: vc)

        if stayAtBottom {
            log("  Скролл: stayAtBottom (без анимации)")
        } else if delta != 0 {
            log("  Скролл: bottom-stable delta=\(f(delta)), offset: \(f(s.savedOffset.y)) → \(f(s.savedOffset.y + delta))")
        }

        // Рекофигурация видимых ячеек с crossfade анимацией
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

        if stayAtBottom {
            scrollToBottom(cv: cv, animated: false)
        } else if wantScroll {
            scrollToBottom(cv: cv, animated: false)
        } else {
            cv.contentOffset = CGPoint(x: s.savedOffset.x, y: s.savedOffset.y + delta)
            OffsetCalculator.clamp(cv: cv, savedX: s.savedOffset.x, skip: false)
        }

        CATransaction.commit()

        vc.finalizeUpdate(count: rows.count, animated: true)
        vc.flushPendingMessages()
    }
}

// MARK: - Disintegration (анимация удаления)

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

    /// Инвалидация sizeCache для сообщений с изменённым контентом (prepend/append путь).
    func invalidateChangedMessages(vc: ChatViewController, oldMessages: [ChatMessage], newMessages: [ChatMessage]) {
        let oldById = Dictionary(oldMessages.map { ($0.id, $0) }, uniquingKeysWith: { _, l in l })
        for msg in newMessages {
            if let prev = oldById[msg.id], prev != msg {
                vc.invalidateSizeCache(forKey: msg.id)
            }
        }
    }

    /// Инвалидация sizeCache для изменённых и pending сообщений.
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
