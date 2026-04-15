import UIKit

// MARK: - UICollectionViewDelegate + UIScrollViewDelegate (скролл, пагинация, видимость)

extension ChatViewController: UICollectionViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentY = scrollView.contentOffset.y
        if currentY > lastScrollOffsetY + 1 {
            scrollDirection = .down
        } else if currentY < lastScrollOffsetY - 1 {
            scrollDirection = .up
        }
        lastScrollOffsetY = currentY

        let now = CACurrentMediaTime()
        if now - lastScrollEventTime >= layout.scrollThrottleInterval {
            lastScrollEventTime = now
            delegate?.chatDidScroll(offset: scrollView.contentOffset)
        }

        // Не трогаем пагинацию при пустых данных или начальной защите скролла
        guard !messages.isEmpty, !isInitialScrollProtected else {
            updateFABVisibility(animated: true)
            updateFloatingDate()
            return
        }

        let offset = scrollView.contentOffset.y
        let contentH = scrollView.contentSize.height
        let frameH = scrollView.bounds.height

        // Верхняя пагинация — пропускаем только при скролле ВНИЗ
        if scrollDirection != .down
            && offset < features.topLoadThreshold
            && hasMore && !isLoadingTop {
            delegate?.chatDidReachTop(distance: offset)
        }

        // Нижняя пагинация — пропускаем только при скролле ВВЕРХ
        let distanceToBottom = contentH - offset - frameH
        if scrollDirection != .up
            && distanceToBottom < features.bottomLoadThreshold
            && hasNewer && !isLoadingBottom && !isLoadingNewerActive {
            isLoadingNewerActive = true
            delegate?.chatDidReachBottom(distance: distanceToBottom)
        }

        updateFABVisibility(animated: true)
        updateVisibleMessages()
        updateFloatingDate()
        reportScrollAnchorIfNeeded()
        if isLoadingTop { hideFirstDateSeparator(true) }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserDragging = true
        pendingScrollToBottom = false
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isUserDragging = false
        if !decelerate {
            reportScrollAnchorOnSettled()
            flushPendingMessages()
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        reportScrollAnchorOnSettled()
        flushPendingMessages()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
        // Не репортим якорь после программного скролла — RN управляет этим состоянием
    }
}

// MARK: - Отправка якоря скролла

extension ChatViewController {

    /// Throttled (~300ms) отправка якоря. Работает только при пользовательском скролле —
    /// заблокирован при начальной защите, программном скролле, стабилизации после обновлений.
    func reportScrollAnchorIfNeeded() {
        guard !isInitialScrollProtected else { return }
        guard !isProgrammaticScroll else { return }

        guard let cv = collectionView,
              cv.isDragging || cv.isDecelerating || isUserDragging else { return }

        let now = CACurrentMediaTime()
        guard now - anchorThrottleTime >= 0.3 else { return }
        anchorThrottleTime = now

        if let anchor = currentScrollAnchor() {
            delegate?.chatScrollAnchorChanged(anchor: anchor)
        }
    }

    /// Однократная отправка якоря после окончания скролла пользователем (финальная позиция).
    func reportScrollAnchorOnSettled() {
        guard !isInitialScrollProtected, !isProgrammaticScroll else {
            return
        }

        // Сбрасываем throttle чтобы сработало немедленно
        anchorThrottleTime = 0

        if let anchor = currentScrollAnchor() {
            delegate?.chatScrollAnchorChanged(anchor: anchor)
        }
    }
}

// MARK: - Отслеживание видимости

extension ChatViewController {

    /// Гистерезис: ячейка входит в allIDs при visibilityThreshold (0.8),
    /// выходит при visibilityExitThreshold (0.5). Отдельный порог для mark-as-read.
    func collectVisibleMessageIDs() -> (all: [String], unread: Set<String>) {
        let visibleRect = CGRect(
            origin: collectionView.contentOffset,
            size: collectionView.bounds.size
        )
        let enterThreshold = visibilityThreshold
        let exitThreshold = visibilityExitThreshold
        let unreadThreshold = unreadVisibilityThreshold

        // Собираем пары (index, cell) и сортируем сверху вниз
        var sorted: [(index: Int, cell: UICollectionViewCell, msg: ChatMessage)] = []

        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  indexPath.item < rows.count,
                  case .message(let msg) = rows[indexPath.item] else { continue }
            sorted.append((indexPath.item, cell, msg))
        }

        sorted.sort { $0.index < $1.index }

        var allIDs: [String] = []
        var unreadIDs: Set<String> = []
        var newActiveIDs: Set<String> = []

        for (_, cell, msg) in sorted {
            let cellFrame = cell.frame
            let intersection = visibleRect.intersection(cellFrame)

            guard !intersection.isNull else { continue }

            let visibleFraction = intersection.height / max(cellFrame.height, 1)

            let wasActive = activeVisibleIDs.contains(msg.id)
            let isActive = wasActive
                ? visibleFraction >= exitThreshold
                : visibleFraction >= enterThreshold

            if isActive {
                allIDs.append(msg.id)
                newActiveIDs.insert(msg.id)
            }

            if visibleFraction >= unreadThreshold && msg.status != .read {
                unreadIDs.insert(msg.id)
            }
        }

        activeVisibleIDs = newActiveIDs

        return (allIDs, unreadIDs)
    }

    public func updateVisibleMessages() {
        guard !messages.isEmpty else { return }

        let (allVisibleIDs, unreadIDs) = collectVisibleMessageIDs()

        guard !allVisibleIDs.isEmpty else { return }

        // --- Отметка прочитанности (внутренний) ---
        let newUnread = unreadIDs.subtracting(visibleMessageIDs)
        if !newUnread.isEmpty {
            visibleMessageIDs = unreadIDs
            unreadManager.markAsRead(newUnread)
        }

        // --- Видимые сообщения → throttle ---
        latestVisibleIDs = allVisibleIDs
        notifyVisibleMessages()

        // --- Непрочитанные → debounce ---
        if !newUnread.isEmpty {
            notifyUnreadMessages(newUnread)
        }
    }

    // MARK: - Throttle: снимок видимых сообщений

    private func notifyVisibleMessages() {
        let now = CACurrentMediaTime()
        let interval = visibleMessagesThrottleInterval

        if now - lastVisibleThrottleTime >= interval {
            lastVisibleThrottleTime = now
            fireVisibleSnapshot()
        } else {
            // Планируем trailing edge если ещё не запланирован
            guard pendingVisibleThrottleTask == nil else { return }
            let remaining = interval - (now - lastVisibleThrottleTime)
            let task = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.lastVisibleThrottleTime = CACurrentMediaTime()
                self.pendingVisibleThrottleTask = nil
                self.fireVisibleSnapshot()
            }
            pendingVisibleThrottleTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: task)
        }
    }

    private func fireVisibleSnapshot() {
        let ids = latestVisibleIDs
        guard !ids.isEmpty else { return }
        let idSet = Set(ids)
        guard idSet != lastFiredVisibleIDs else { return }
        lastFiredVisibleIDs = idSet
        delegate?.chatVisibleMessagesDidChange(ids: ids)
    }

    // MARK: - Debounce: батч непрочитанных

    private func notifyUnreadMessages(_ newUnread: Set<String>) {
        pendingUnreadIDs.formUnion(newUnread)
        unreadDebounceTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self, !self.pendingUnreadIDs.isEmpty else { return }
            let batch = Array(self.pendingUnreadIDs)
            self.pendingUnreadIDs.removeAll()
            self.delegate?.chatUnreadMessagesDidAppear(ids: batch)
        }
        unreadDebounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + unreadMessagesDebounceInterval, execute: task)
    }
}
