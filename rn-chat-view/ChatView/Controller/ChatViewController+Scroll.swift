import UIKit

// MARK: - UIScrollViewDelegate

extension ChatViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let now = CACurrentMediaTime()
        if now - lastScrollEventTime >= layout.scrollThrottleInterval {
            lastScrollEventTime = now
            delegate?.chatDidScroll(offset: scrollView.contentOffset)
        }

        let offset = scrollView.contentOffset.y
        let contentH = scrollView.contentSize.height
        let frameH = scrollView.bounds.height

        if offset < features.topLoadThreshold && hasMore && !isLoadingTop && !isInitialScrollProtected {
            delegate?.chatDidReachTop(distance: offset)
        }

        if contentH - offset - frameH < features.bottomLoadThreshold && hasNewer && !isLoadingBottom && !isLoadingNewerActive && !isInitialScrollProtected {
            isLoadingNewerActive = true
            delegate?.chatDidReachBottom(distance: contentH - offset - frameH)
        }

        updateFABVisibility(animated: true)
        updateVisibleMessages()
        updateFloatingDate()
        if isLoadingTop { hideFirstDateSeparator(true) }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserDragging = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isUserDragging = false
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
    }
}
