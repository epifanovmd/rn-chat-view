import UIKit

// MARK: - Row Layout Info

/// Pre-computed layout info for a single row (message, date separator, or loading).
struct RowLayoutInfo {
    let height: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat

    var totalHeight: CGFloat { topInset + height + bottomInset }
}

// MARK: - Chat Collection View Layout

/// Custom `UICollectionViewLayout` optimized for chat — single section, N items.
///
/// Architecture:
/// - Pre-computed `rowLayoutData` array — zero delegate/dataSource calls in `prepare()`
/// - Binary search for visible rect queries — O(log n)
/// - `shouldInvalidateLayout(forBoundsChange:)` returns `false` on scroll (only width change)
/// - `ContiguousArray` for cache-friendly sequential access
///
/// The layout data must be set **before** any `reloadData()` or `performBatchUpdates()` call.
final class ChatCollectionViewLayout: UICollectionViewLayout {

    // MARK: - Input Data

    /// One entry per item in the collection view.
    /// Must be set before `reloadData` / `performBatchUpdates` to match item count.
    var rowLayoutData: [RowLayoutInfo] = []

    // MARK: - Computed Cache

    private var yOffsets = ContiguousArray<CGFloat>()
    private var heights = ContiguousArray<CGFloat>()
    private var totalHeight: CGFloat = 0
    private var cachedWidth: CGFloat = 0

    // MARK: - Content Size

    override var collectionViewContentSize: CGSize {
        CGSize(width: cachedWidth, height: totalHeight)
    }

    // MARK: - Prepare

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }

        cachedWidth = cv.bounds.width
        let count = rowLayoutData.count

        yOffsets.removeAll(keepingCapacity: true)
        yOffsets.reserveCapacity(count)
        heights.removeAll(keepingCapacity: true)
        heights.reserveCapacity(count)

        var y: CGFloat = 0
        for i in 0..<count {
            let info = rowLayoutData[i]
            y += info.topInset
            yOffsets.append(y)
            heights.append(info.height)
            y += info.height + info.bottomInset
        }
        totalHeight = y
    }

    // MARK: - Layout Attributes

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard !yOffsets.isEmpty else { return nil }

        let startIdx = lowerBound(for: rect.minY)
        guard startIdx < yOffsets.count else { return nil }

        var result: [UICollectionViewLayoutAttributes] = []
        for i in startIdx..<yOffsets.count {
            let y = yOffsets[i]
            if y > rect.maxY { break }
            let h = heights[i]
            if y + h >= rect.minY {
                let attrs = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
                attrs.frame = CGRect(x: 0, y: y, width: cachedWidth, height: h)
                result.append(attrs)
            }
        }
        return result
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let idx = indexPath.item
        guard idx < yOffsets.count else { return nil }
        let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attrs.frame = CGRect(x: 0, y: yOffsets[idx], width: cachedWidth, height: heights[idx])
        return attrs
    }

    // MARK: - Batch Update Animations

    /// Appearing cells start at final position — no slide-in animation.
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attrs = layoutAttributesForItem(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes
        attrs?.alpha = 1
        return attrs
    }

    /// Disappearing cells fade out at current position.
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attrs = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes
            ?? layoutAttributesForItem(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes
        attrs?.alpha = 0
        return attrs
    }

    // MARK: - Invalidation

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let cv = collectionView else { return true }
        return cv.bounds.width != newBounds.width
    }

    // MARK: - Binary Search

    /// Returns first index where `yOffsets[i] + heights[i] >= targetY`.
    private func lowerBound(for targetY: CGFloat) -> Int {
        var lo = 0, hi = yOffsets.count
        while lo < hi {
            let mid = (lo + hi) >> 1
            if yOffsets[mid] + heights[mid] < targetY {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo
    }
}
