import UIKit

// MARK: - ContextMenuLayout

/// Результат расчёта всех позиций контекстного меню.
struct ContextMenuLayout {
    let snapTarget:    CGRect
    let emojiTarget:   CGRect   // .zero если панель отсутствует
    let actionsTarget: CGRect   // .zero если панель отсутствует
    let snapOrigin:    CGRect
    let emojiOrigin:   CGRect
    let actionsOrigin: CGRect
    let canvasSize:    CGSize
    let scrollOffset:  CGFloat
    let needsScroll:   Bool
    let hasEmoji:      Bool
    let hasActions:    Bool
}

// MARK: - ContextMenuLayoutEngine

/// Вычисляет позиции всех элементов контекстного меню.
/// Чистая функция без UIKit-состояния — легко тестируется.
/// Панели эмодзи и действий опциональны: если размер нулевой — панель не учитывается в layout.
enum ContextMenuLayoutEngine {

    static func calculate(
        sourceFrame:  CGRect,
        snapSize:     CGSize,
        emojiSize:    CGSize,   // .zero если эмодзи не переданы
        actionsSize:  CGSize,   // .zero если действия не переданы
        screen:       CGRect,
        safeArea:     UIEdgeInsets,
        theme:        ContextMenuTheme
    ) -> ContextMenuLayout {

        let hasEmoji   = emojiSize.height   > 0
        let hasActions = actionsSize.height > 0

        let hPad = theme.horizontalPadding
        let vPad = theme.verticalPadding
        let eGap = hasEmoji   ? theme.emojiPanelSpacing : 0
        let mGap = hasActions ? theme.menuSpacing       : 0

        let snapW  = snapSize.width
        let snapH  = snapSize.height
        let emojiW = hasEmoji   ? min(emojiSize.width,   screen.width - hPad * 2) : 0
        let emojiH = hasEmoji   ? emojiSize.height   : 0
        let menuW  = hasActions ? min(actionsSize.width, screen.width - hPad * 2) : 0
        let menuH  = hasActions ? actionsSize.height : 0

        let topLimit    = safeArea.top    + vPad
        let bottomLimit = screen.height - safeArea.bottom - vPad

        let snapX  = clamp(sourceFrame.minX, lo: hPad, hi: screen.width - snapW - hPad)
        let emojiX = hasEmoji   ? clamp(snapX + snapW - emojiW, lo: hPad, hi: screen.width - emojiW - hPad) : 0
        let menuX  = hasActions ? (snapX + menuW > screen.width - hPad ? screen.width - hPad - menuW : snapX) : 0

        let totalH      = emojiH + eGap + snapH + mGap + menuH
        let needsScroll = totalH > bottomLimit - topLimit

        let emojiYc, snapYc, menuYc, canvasH, scrollOffset: CGFloat

        if needsScroll {
            emojiYc      = topLimit
            snapYc       = emojiYc + emojiH + eGap
            menuYc       = snapYc  + snapH  + mGap
            canvasH      = menuYc  + menuH  + safeArea.bottom + vPad
            scrollOffset = max(0, canvasH - screen.height)
        } else {
            let blockTop = clamp(sourceFrame.minY - emojiH - eGap, lo: topLimit, hi: bottomLimit - totalH)
            emojiYc      = blockTop
            snapYc       = emojiYc + emojiH + eGap
            menuYc       = snapYc  + snapH  + mGap
            canvasH      = screen.height
            scrollOffset = 0
        }

        let originY = sourceFrame.minY + scrollOffset

        return ContextMenuLayout(
            snapTarget:    CGRect(x: snapX,  y: snapYc,  width: snapW,  height: snapH),
            emojiTarget:   hasEmoji   ? CGRect(x: emojiX, y: emojiYc, width: emojiW, height: emojiH) : .zero,
            actionsTarget: hasActions ? CGRect(x: menuX,  y: menuYc,  width: menuW,  height: menuH)  : .zero,
            snapOrigin:    CGRect(x: sourceFrame.minX, y: originY, width: snapW, height: snapH),
            emojiOrigin:   hasEmoji   ? CGRect(x: emojiX, y: originY - eGap - emojiH, width: emojiW, height: emojiH) : .zero,
            actionsOrigin: hasActions ? CGRect(x: menuX,  y: originY + snapH + mGap,  width: menuW,  height: menuH)  : .zero,
            canvasSize:    CGSize(width: screen.width, height: canvasH),
            scrollOffset:  scrollOffset,
            needsScroll:   needsScroll,
            hasEmoji:      hasEmoji,
            hasActions:    hasActions
        )
    }

    private static func clamp(_ v: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        max(lo, min(v, hi))
    }
}
