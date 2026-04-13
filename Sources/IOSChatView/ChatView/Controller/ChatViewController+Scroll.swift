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
    public func updateVisibleMessages() {
        guard !messages.isEmpty else { return }

        // Collect visible message IDs and unread IDs in one pass.
        var allVisibleIDs: [String] = []
        var unreadIDs: Set<String> = []

        let cells = Array(collectionView.visibleCells)
        for cell in cells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  indexPath.item < rows.count,
                  case .message(let msg) = rows[indexPath.item] else { continue }
            allVisibleIDs.append(msg.id)
            if msg.status != .read {
                unreadIDs.insert(msg.id)
            }
        }

        guard !allVisibleIDs.isEmpty else { return }

        // --- Mark-as-read (internal) ---
        let newUnread = unreadIDs.subtracting(visibleMessageIDs)
        if !newUnread.isEmpty {
            visibleMessageIDs = unreadIDs
            unreadManager.markAsRead(newUnread)
        }

        // --- Visible messages → throttle ---
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
            // Enough time passed — fire immediately
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
        var ids: [String] = []
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  indexPath.item < rows.count,
                  case .message(let msg) = rows[indexPath.item] else { continue }
            ids.append(msg.id)
        }
        guard !ids.isEmpty else { return }
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
