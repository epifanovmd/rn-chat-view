import UIKit

// MARK: - UIScrollViewDelegate

extension ChatViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let now = CACurrentMediaTime()
        if now - lastScrollEventTime >= scrollThrottleInterval {
            lastScrollEventTime = now
            delegate?.chatDidScroll(offset: scrollView.contentOffset)
        }

        let offset = scrollView.contentOffset.y
        let contentH = scrollView.contentSize.height
        let frameH = scrollView.bounds.height

        if offset < topThreshold && hasMore && !isLoading && !waitingForNewMessages {
            waitingForNewMessages = true
            delegate?.chatDidReachTop(distance: offset)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.waitingForNewMessages = false
            }
        }

        if contentH - offset - frameH < bottomThreshold && hasNewer && !isLoadingNewerActive && !waitingForNewerMessages {
            waitingForNewerMessages = true
            isLoadingNewerActive = true
            delegate?.chatDidReachBottom(distance: contentH - offset - frameH)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.waitingForNewerMessages = false
            }
        }

        lastContentOffsetY = offset
        updateFABVisibility(animated: true)
        updateVisibleMessages()
        updateFloatingDate()
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
