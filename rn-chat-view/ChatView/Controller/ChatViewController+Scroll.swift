import UIKit

// MARK: - UIScrollViewDelegate

extension ChatViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let now = CACurrentMediaTime()
        if now - lastScrollEventTime >= ChatLayout.current.scrollThrottleInterval {
            lastScrollEventTime = now
            delegate?.chatDidScroll(offset: scrollView.contentOffset)
        }

        let offset = scrollView.contentOffset.y
        let contentH = scrollView.contentSize.height
        let frameH = scrollView.bounds.height

        if offset < topThreshold
            && hasMore && !isLoadingTop && !didTriggerTopThisGesture
            && !isInitialScrollProtected {
            didTriggerTopThisGesture = true
            delegate?.chatDidReachTop(distance: offset)
        }

        if contentH - offset - frameH < bottomThreshold
            && hasNewer && !isLoadingBottom && !isLoadingNewerActive && !didTriggerBottomThisGesture
            && !isInitialScrollProtected {
            didTriggerBottomThisGesture = true
            isLoadingNewerActive = true
            delegate?.chatDidReachBottom(distance: contentH - offset - frameH)
        }

        updateFABVisibility(animated: true)
        updateVisibleMessages()
        updateFloatingDate()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserDragging = true
        didTriggerTopThisGesture = isLoadingTop
        didTriggerBottomThisGesture = isLoadingBottom
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isUserDragging = false
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
    }
}
