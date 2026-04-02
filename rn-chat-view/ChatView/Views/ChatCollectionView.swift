import UIKit

final class ChatCollectionView: UICollectionView {

    var needsPrependCompensation = false
    var prePrependContentHeight: CGFloat = 0
    var prePrependContentOffset: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        if needsPrependCompensation {
            needsPrependCompensation = false
            let delta = contentSize.height - prePrependContentHeight
            if delta > 0 {
                contentOffset = CGPoint(x: 0, y: prePrependContentOffset + delta)
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
