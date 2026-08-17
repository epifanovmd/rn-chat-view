import UIKit

// MARK: - Предвычисленные данные строки

struct RowLayoutInfo {
    let height: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat

    var totalHeight: CGFloat { topInset + height + bottomInset }
}

// MARK: - Группа аватара

struct AvatarGroup {
    let firstIndex: Int
    let lastIndex: Int
    let senderName: String
    let senderAvatarUrl: String?
}

// MARK: - Chat Collection View Layout

/// Кастомный layout для чата: предвычисленные высоты, бинарный поиск O(log n),
/// sticky-аватары. rowLayoutData должен быть задан ДО reloadData/performBatchUpdates.
final class ChatCollectionViewLayout: UICollectionViewLayout {

    // MARK: - Входные данные

    var rowLayoutData: [RowLayoutInfo] = []
    var avatarGroups: [AvatarGroup] = []
    var showAvatars: Bool = false
    var avatarSize: CGFloat = 30
    var avatarLeadingMargin: CGFloat = 8

    // MARK: - Кэш

    private(set) var yOffsets = ContiguousArray<CGFloat>()
    private(set) var heights = ContiguousArray<CGFloat>()
    private var totalHeight: CGFloat = 0
    private var cachedWidth: CGFloat = 0

    private var lastPreparedDataCount = -1
    private var needsFullPrepare = true

    func setNeedsFullPrepare() {
        needsFullPrepare = true
    }

    // MARK: - Размер контента

    override var collectionViewContentSize: CGSize {
        CGSize(width: cachedWidth, height: totalHeight)
    }

    // MARK: - Prepare

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }

        let widthChanged = cv.bounds.width != cachedWidth
        let dataChanged = needsFullPrepare || rowLayoutData.count != lastPreparedDataCount

        // Пропускаем O(n) пересчёт при обычном скролле (без изменения данных)
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

    // MARK: - Атрибуты layout

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

        if showAvatars, !avatarGroups.isEmpty {
            let viewport = actualVisibleRect()
            let startGroup = lowerBoundGroup(for: viewport.minY)
            for groupIdx in startGroup..<avatarGroups.count {
                let group = avatarGroups[groupIdx]
                guard group.firstIndex < yOffsets.count else { continue }
                let groupTop = yOffsets[group.firstIndex]
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

    /// Видимый rect с учётом insets (клавиатура, input bar).
    /// contentOffset.y уже включает top inset, поэтому visible top = contentOffset.y.
    private func actualVisibleRect() -> CGRect {
        guard let cv = collectionView else { return .zero }
        let insets = cv.adjustedContentInset
        let visibleTop = cv.contentOffset.y + insets.top
        let visibleHeight = cv.bounds.height - insets.top - insets.bottom
        return CGRect(x: 0, y: visibleTop, width: cv.bounds.width, height: visibleHeight)
    }

    // MARK: - Sticky-позиционирование аватара

    /// Sticky-позиция: natural (низ последнего сообщения) → sticky (прилипает к низу экрана)
    /// → ceiling (не выше первого сообщения группы — уходит вверх вместе с ним).
    private func avatarAttributes(for groupIdx: Int, group: AvatarGroup, visibleRect: CGRect) -> UICollectionViewLayoutAttributes? {
        guard group.firstIndex < yOffsets.count, group.lastIndex < yOffsets.count else { return nil }

        let firstY = yOffsets[group.firstIndex]
        let lastY = yOffsets[group.lastIndex]
        let lastH = heights[group.lastIndex]

        let groupTop = firstY
        let groupBottom = lastY + lastH

        let margin = avatarSize + 20
        if groupBottom + margin < visibleRect.minY || groupTop - margin > visibleRect.maxY {
            return nil
        }

        let naturalY = groupBottom - avatarSize
        let visibleBottom = visibleRect.maxY - avatarSize
        let stickyY = min(naturalY, visibleBottom)
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

    // MARK: - Анимации batch update

    // Появляющиеся ячейки сразу на финальной позиции — без slide-in
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attrs = layoutAttributesForItem(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes
        attrs?.alpha = 1
        return attrs
    }

    // Исчезающие ячейки fade out на текущей позиции
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attrs = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes
            ?? layoutAttributesForItem(at: itemIndexPath)?.copy() as? UICollectionViewLayoutAttributes
        attrs?.alpha = 0
        return attrs
    }

    // MARK: - Инвалидация

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let cv = collectionView else { return true }
        // Смена ширины → полная инвалидация. Скролл → только если нужен sticky-аватар.
        if cv.bounds.width != newBounds.width { return true }
        return showAvatars && !avatarGroups.isEmpty
    }

    // MARK: - Якорная геометрия

    /// «Низ ячейки» в семантике якорей скролла: `yOffset + topInset + height`.
    /// ВНИМАНИЕ: yOffsets уже включает topInset, так что значение смещено на
    /// topInset относительно фактической геометрии — но сохранение и
    /// восстановление якоря используют одну формулу, смещение сокращается.
    /// Якоря персистятся хостом (RN) — формулу не менять.
    func anchorCellBottom(at index: Int) -> CGFloat? {
        guard index < rowLayoutData.count, index < yOffsets.count else { return nil }
        return yOffsets[index] + rowLayoutData[index].topInset + rowLayoutData[index].height
    }

    // MARK: - Бинарный поиск

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

// MARK: - Скролл-геометрия

extension UICollectionView {
    /// Максимальный contentOffset.y — «низ» контента с учётом bottom inset.
    /// Единственная точка правды для формулы scrollToBottom/clamp.
    var chatMaxOffsetY: CGFloat {
        contentSize.height - bounds.height + contentInset.bottom
    }
}
