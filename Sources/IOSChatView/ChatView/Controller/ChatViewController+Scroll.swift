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
        var ids: Set<String> = []
        let cells = Array(collectionView.visibleCells)
        for cell in cells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  indexPath.item < rows.count,
                  case .message(let msg) = rows[indexPath.item],
                  msg.status != .read else { continue }
            ids.insert(msg.id)
        }

        let newIDs = ids.subtracting(visibleMessageIDs)
        guard !newIDs.isEmpty else { return }
        visibleMessageIDs = ids

        unreadManager.markAsRead(newIDs)

        pendingVisibleIDs.formUnion(newIDs)
        visibilityDebounceTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self, !self.pendingVisibleIDs.isEmpty else { return }
            let batch = Array(self.pendingVisibleIDs)
            self.pendingVisibleIDs.removeAll()
            self.delegate?.chatMessagesDidAppear(ids: batch)
        }
        visibilityDebounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + layout.visibilityDebounceInterval, execute: task)
    }
}
