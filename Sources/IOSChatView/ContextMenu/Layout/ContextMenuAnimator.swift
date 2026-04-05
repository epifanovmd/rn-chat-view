import UIKit

// MARK: - ContextMenuAnimator

/// Управляет анимациями открытия и закрытия контекстного меню.
/// emojiPanel и actionsPanel опциональны — если nil, анимация их пропускает.
final class ContextMenuAnimator {

    private let theme:        ContextMenuTheme
    private let backdrop:     UIView
    private let snapshot:     UIView?
    private let emojiPanel:   UIView?   // nil если эмодзи не переданы
    private let actionsPanel: UIView?   // nil если действия не переданы

    private static let openScale:  CGFloat = 0.5
    private static let closeScale: CGFloat = 0.5

    init(theme: ContextMenuTheme, backdrop: UIView, snapshot: UIView?,
         emojiPanel: UIView?, actionsPanel: UIView?) {
        self.theme        = theme
        self.backdrop     = backdrop
        self.snapshot     = snapshot
        self.emojiPanel   = emojiPanel
        self.actionsPanel = actionsPanel
    }

    /// Устанавливает начальное состояние элементов перед анимацией открытия.
    func prepareOpen(layout: ContextMenuLayout) {
        snapshot?.frame = layout.snapOrigin

        if let panel = emojiPanel {
            place(panel, in: layout.emojiOrigin, scale: Self.openScale)
            panel.alpha = 0
        }
        if let panel = actionsPanel {
            place(panel, in: layout.actionsOrigin, scale: Self.openScale)
            panel.alpha = 0
        }
        backdrop.alpha = 0
    }

    /// Запускает spring-анимацию открытия.
    func animateOpen(layout: ContextMenuLayout) {
        let dur = theme.openDuration
        let d   = theme.springDamping
        let v   = theme.springVelocity

        UIView.animate(withDuration: dur * 0.55, delay: 0, options: .curveEaseOut) { [weak self] in
            self?.backdrop.alpha = 1
        }

        UIView.animate(withDuration: dur, delay: 0,
                       usingSpringWithDamping: d, initialSpringVelocity: v,
                       options: .allowUserInteraction) { [weak self] in
            self?.snapshot?.frame = layout.snapTarget
        }

        if let panel = actionsPanel {
            animatePanel(panel, to: layout.actionsTarget, duration: dur, damping: d, velocity: v)
        }
        if let panel = emojiPanel {
            animatePanel(panel, to: layout.emojiTarget, duration: dur, damping: d - 0.1, velocity: v)
        }
    }

    /// Анимирует закрытие: элементы схлопываются к исходной позиции снапшота.
    func animateClose(returnFrame: CGRect, layout: ContextMenuLayout, completion: @escaping () -> Void) {
        let eGap = theme.emojiPanelSpacing
        let mGap = theme.menuSpacing
        let y    = returnFrame.minY

        UIView.animate(withDuration: theme.closeDuration, delay: 0,
                       usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2) { [weak self] in
            guard let self else { return }
            self.backdrop.alpha  = 0
            self.snapshot?.frame = returnFrame

            if let panel = self.emojiPanel {
                let emojiClose = layout.emojiTarget.at(y: y - layout.emojiTarget.height - eGap)
                self.place(panel, in: emojiClose, scale: Self.closeScale)
                panel.alpha = 0
            }
            if let panel = self.actionsPanel {
                let actionsClose = layout.actionsTarget.at(y: y + returnFrame.height + mGap)
                self.place(panel, in: actionsClose, scale: Self.closeScale)
                panel.alpha = 0
            }
        } completion: { _ in completion() }
    }

    // MARK: - Private

    private func place(_ view: UIView, in rect: CGRect, scale: CGFloat) {
        view.bounds    = CGRect(origin: .zero, size: rect.size)
        view.center    = CGPoint(x: rect.midX, y: rect.midY)
        view.transform = scale == 1 ? .identity : CGAffineTransform(scaleX: scale, y: scale)
    }

    private func animatePanel(_ panel: UIView, to target: CGRect,
                               duration: TimeInterval, damping: CGFloat, velocity: CGFloat) {
        UIView.animate(withDuration: duration, delay: 0,
                       usingSpringWithDamping: damping, initialSpringVelocity: velocity,
                       options: .allowUserInteraction) {
            panel.center    = CGPoint(x: target.midX, y: target.midY)
            panel.transform = .identity
            panel.alpha     = 1
        }
    }
}

// MARK: - CGRect helpers

private extension CGRect {
    func at(y: CGFloat) -> CGRect {
        CGRect(x: minX, y: y, width: width, height: height)
    }
}
