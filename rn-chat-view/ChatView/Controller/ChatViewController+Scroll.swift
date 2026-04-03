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

        let inTopZone = offset < topThreshold
        if inTopZone && hasMore && !isLoadingTop && !didTriggerTopThisGesture && !isInitialScrollProtected {
            didTriggerTopThisGesture = true
            delegate?.chatDidReachTop(distance: offset)
        }

        let inBottomZone = contentH - offset - frameH < bottomThreshold
        if inBottomZone && hasNewer && !isLoadingBottom && !isLoadingNewerActive && !didTriggerBottomThisGesture && !isInitialScrollProtected {
            didTriggerBottomThisGesture = true
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
        if !isLoadingTop { didTriggerTopThisGesture = false }
        if !isLoadingBottom { didTriggerBottomThisGesture = false }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isUserDragging = false
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isProgrammaticScroll = false
    }
}
