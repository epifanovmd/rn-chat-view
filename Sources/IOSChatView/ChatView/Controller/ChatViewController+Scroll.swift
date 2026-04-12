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

        // Collect ALL visible message IDs (for scroll position tracking)
        // and unread IDs separately (for mark-as-read).
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

        // Mark-as-read: only new unread IDs
        let newUnread = unreadIDs.subtracting(visibleMessageIDs)
        if !newUnread.isEmpty {
            visibleMessageIDs = unreadIDs
            unreadManager.markAsRead(newUnread)
        }

        // Notify delegate with both arrays (debounced)
        pendingVisibleIDs.formUnion(allVisibleIDs)
        pendingUnreadIDs.formUnion(newUnread)
        visibilityDebounceTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self, !self.pendingVisibleIDs.isEmpty else { return }
            let allBatch = Array(self.pendingVisibleIDs)
            let unreadBatch = Array(self.pendingUnreadIDs)
            self.pendingVisibleIDs.removeAll()
            self.pendingUnreadIDs.removeAll()
            self.delegate?.chatMessagesDidAppear(ids: allBatch, unreadIds: unreadBatch)
        }
        visibilityDebounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + layout.visibilityDebounceInterval, execute: task)
    }
}
