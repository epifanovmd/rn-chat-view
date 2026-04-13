import UIKit

// MARK: - Row Layout Info

/// Pre-computed layout info for a single row (message, date separator, or loading).
struct RowLayoutInfo {
    let height: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat

    var totalHeight: CGFloat { topInset + height + bottomInset }
}

// MARK: - Avatar Group

/// Describes a group of consecutive messages from the same sender that share one avatar.
struct AvatarGroup {
    /// Index of the first message in the group (in rows array).
    let firstIndex: Int
    /// Index of the last message in the group.
    let lastIndex: Int
    /// Sender display name (for initials).
    let senderName: String
    /// Sender avatar URL (optional).
    let senderAvatarUrl: String?
}

// MARK: - Chat Collection View Layout

/// Custom `UICollectionViewLayout` optimized for chat — single section, N items.
///
/// Architecture:
/// - Pre-computed `rowLayoutData` array — zero delegate/dataSource calls in `prepare()`
/// - Binary search for visible rect queries — O(log n)
/// - `shouldInvalidateLayout(forBoundsChange:)` returns `true` when avatars enabled (sticky)
/// - `ContiguousArray` for cache-friendly sequential access
///
/// The layout data must be set **before** any `reloadData()` or `performBatchUpdates()` call.
final class ChatCollectionViewLayout: UICollectionViewLayout {

    // MARK: - Input Data

    /// One entry per item in the collection view.
    /// Must be set before `reloadData` / `performBatchUpdates` to match item count.
    var rowLayoutData: [RowLayoutInfo] = []

    /// Avatar groups for sticky positioning. Set alongside rowLayoutData.
    var avatarGroups: [AvatarGroup] = []

    /// Whether avatars are enabled.
    var showAvatars: Bool = false

    /// Avatar sizing (copied from ChatLayout for use in layout calculations).
    var avatarSize: CGFloat = 30
    var avatarLeadingMargin: CGFloat = 8

    // MARK: - Computed Cache

    private(set) var yOffsets = ContiguousArray<CGFloat>()
    private(set) var heights = ContiguousArray<CGFloat>()
    private var totalHeight: CGFloat = 0
    private var cachedWidth: CGFloat = 0

    /// Tracks whether rowLayoutData changed since last prepare().
    private var lastPreparedDataCount = -1
    private var needsFullPrepare = true

    /// Call when rowLayoutData is replaced to force a full prepare on next layout pass.
    func setNeedsFullPrepare() {
        needsFullPrepare = true
    }

    // MARK: - Content Size

    override var collectionViewContentSize: CGSize {
        CGSize(width: cachedWidth, height: totalHeight)
    }

    // MARK: - Prepare

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }

        let widthChanged = cv.bounds.width != cachedWidth
        let dataChanged = needsFullPrepare || rowLayoutData.count != lastPreparedDataCount

        // Skip expensive O(n) rebuild if only scrolling (bounds change without data change)
        guard widthChanged || dataChanged else { return }

        cachedWidth = cv.bounds.width
        let count = rowLayoutData.count
        lastPreparedDataCount = count
        needsFullPrepare = false

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

        // Cell attributes
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

        // Avatar supplementary attributes — use actual visible content rect
        if showAvatars, !avatarGroups.isEmpty {
            let viewport = actualVisibleRect()
            // Find first potentially visible group via binary search
            let startGroup = lowerBoundGroup(for: viewport.minY)
            for groupIdx in startGroup..<avatarGroups.count {
                let group = avatarGroups[groupIdx]
                guard group.firstIndex < yOffsets.count else { continue }
                let groupTop = yOffsets[group.firstIndex]
                // Stop if group starts well past visible bottom
                if groupTop > viewport.maxY + avatarSize + 20 { break }
                if let attrs = avatarAttributes(for: groupIdx, group: group, visibleRect: viewport) {
                    result.append(attrs)
                }
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

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard elementKind == AvatarSupplementaryView.kind,
              showAvatars,
              indexPath.item < avatarGroups.count else { return nil }
        let group = avatarGroups[indexPath.item]
        return avatarAttributes(for: indexPath.item, group: group, visibleRect: actualVisibleRect())
    }

    /// The visible content rect accounting for content insets (keyboard, input bar).
    /// `contentOffset.y` already includes the top inset adjustment, so the visible
    /// top in content coordinates is just `contentOffset.y`. The visible height
    /// excludes both top and bottom insets.
    private func actualVisibleRect() -> CGRect {
        guard let cv = collectionView else { return .zero }
        let insets = cv.adjustedContentInset
        let visibleTop = cv.contentOffset.y + insets.top
        let visibleHeight = cv.bounds.height - insets.top - insets.bottom
        return CGRect(x: 0, y: visibleTop, width: cv.bounds.width, height: visibleHeight)
    }

    // MARK: - Avatar Sticky Positioning

    /// Computes the sticky position for an avatar group.
    ///
    /// Behavior:
    /// - Natural position: bottom of the last message in the group
    /// - Sticky: when last message is below visible bottom, avatar sticks to visible bottom
    /// - Ceiling: avatar cannot go above the top of the first message in the group
    ///   → when first message scrolls out the top, avatar goes with it
    private func avatarAttributes(for groupIdx: Int, group: AvatarGroup, visibleRect: CGRect) -> UICollectionViewLayoutAttributes? {
        guard group.firstIndex < yOffsets.count, group.lastIndex < yOffsets.count else { return nil }

        let firstY = yOffsets[group.firstIndex]
        let lastY = yOffsets[group.lastIndex]
        let lastH = heights[group.lastIndex]

        let groupTop = firstY
        let groupBottom = lastY + lastH

        // Skip if entirely outside visible rect
        let margin = avatarSize + 20
        if groupBottom + margin < visibleRect.minY || groupTop - margin > visibleRect.maxY {
            return nil
        }

        // 1. Natural: bottom-aligned with the last message
        let naturalY = groupBottom - avatarSize

        // 2. Sticky bottom: clamp to visible bottom when group extends below screen
        let visibleBottom = visibleRect.maxY - avatarSize
        let stickyY = min(naturalY, visibleBottom)

        // 3. Ceiling: cannot go above first message — follows it out when scrolling up
        let finalY = max(stickyY, groupTop)

        let x = avatarLeadingMargin
        let attrs = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: AvatarSupplementaryView.kind,
            with: IndexPath(item: groupIdx, section: 0)
        )
        attrs.frame = CGRect(x: x, y: finalY, width: avatarSize, height: avatarSize)
        attrs.zIndex = 100
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
        // Width change → full invalidation. Scroll → only if avatars need sticky update.
        if cv.bounds.width != newBounds.width { return true }
        return showAvatars && !avatarGroups.isEmpty
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

    /// Returns first avatar group whose last message's bottom >= targetY.
    private func lowerBoundGroup(for targetY: CGFloat) -> Int {
        var lo = 0, hi = avatarGroups.count
        while lo < hi {
            let mid = (lo + hi) >> 1
            let group = avatarGroups[mid]
            let lastIdx = group.lastIndex
            guard lastIdx < yOffsets.count else { lo = mid + 1; continue }
            let groupBottom = yOffsets[lastIdx] + heights[lastIdx]
            if groupBottom + avatarSize + 20 < targetY {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        return lo
    }
}
