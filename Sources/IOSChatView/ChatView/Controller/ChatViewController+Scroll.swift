import UIKit

// MARK: - UICollectionViewDelegate + UIScrollViewDelegate

extension ChatViewController: UICollectionViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let now = CACurrentMediaTime()
        if now - lastScrollEventTime >= layout.scrollThrottleInterval {
            lastScrollEventTime = now
            delegate?.chatDidScroll(offset: scrollView.contentOffset)
        }

        // Don't trigger pagination when empty or during initial scroll protection
        guard !messages.isEmpty, !isInitialScrollProtected else {
            updateFABVisibility(animated: true)
            updateFloatingDate()
            return
        }

        let offset = scrollView.contentOffset.y
        let contentH = scrollView.contentSize.height
        let frameH = scrollView.bounds.height

        if offset < features.topLoadThreshold && hasMore && !isLoadingTop {
            delegate?.chatDidReachTop(distance: offset)
        }

        if contentH - offset - frameH < features.bottomLoadThreshold && hasNewer && !isLoadingBottom && !isLoadingNewerActive {
            isLoadingNewerActive = true
            delegate?.chatDidReachBottom(distance: contentH - offset - frameH)
        }

        updateFABVisibility(animated: true)
        updateVisibleMessages()
        updateFloatingDate()
        if isLoadingTop { hideFirstDateSeparator(true) }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserDragging = true
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isUserDragging = false
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
    }
}

// MARK: - Visibility Tracking

extension ChatViewController {

    /// Collects message IDs from visible cells using hysteresis for the visible snapshot
    /// and a separate threshold for mark-as-read.
    ///
    /// Hysteresis: a cell enters `allIDs` at `visibilityThreshold` (0.8),
    /// stays until it drops below `visibilityExitThreshold` (0.5).
    func collectVisibleMessageIDs() -> (all: [String], unread: Set<String>) {
        let visibleRect = CGRect(
            origin: collectionView.contentOffset,
            size: collectionView.bounds.size
        )
        let enterThreshold = visibilityThreshold
        let exitThreshold = visibilityExitThreshold
        let unreadThreshold = unreadVisibilityThreshold

        // Collect (indexPath.item, cell) pairs and sort by index (top to bottom)
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

        // --- Mark-as-read (internal) ---
        let newUnread = unreadIDs.subtracting(visibleMessageIDs)
        if !newUnread.isEmpty {
            visibleMessageIDs = unreadIDs
            unreadManager.markAsRead(newUnread)
        }

        // --- Visible messages → throttle ---
        latestVisibleIDs = allVisibleIDs
        notifyVisibleMessages()

        // --- Unread messages → debounce ---
        if !newUnread.isEmpty {
            notifyUnreadMessages(newUnread)
        }
    }

    // MARK: - Throttle: visible messages snapshot

    private func notifyVisibleMessages() {
        let now = CACurrentMediaTime()
        let interval = visibleMessagesThrottleInterval

        if now - lastVisibleThrottleTime >= interval {
            lastVisibleThrottleTime = now
            fireVisibleSnapshot()
        } else {
            // Schedule trailing edge if not already scheduled
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

    // MARK: - Debounce: unread messages batch

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
