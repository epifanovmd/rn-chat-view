import UIKit

final class ChatCollectionView: UICollectionView {

    var needsPrependCompensation = false
    var prePrependContentHeight: CGFloat = 0
    var prePrependContentOffset: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()

        if needsPrependCompensation {
            let delta = contentSize.height - prePrependContentHeight
            if delta > 0 {
                needsPrependCompensation = false
                let targetY = max(-contentInset.top, prePrependContentOffset + delta)
                contentOffset = CGPoint(x: 0, y: targetY)
            }
        }
    }

    // Disable fade animation on section reload (reactions, status changes)
    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        UIView.performWithoutAnimation {
            super.performBatchUpdates(updates, completion: completion)
        }
    }
}
